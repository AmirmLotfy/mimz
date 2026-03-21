import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../../services/api_client.dart';
import '../../../services/telemetry_service.dart';

import '../domain/live_connection_phase.dart';
import '../domain/live_event.dart';
import '../domain/live_session_config.dart';
import '../domain/live_session_state.dart';
import '../data/live_websocket_client.dart';
import '../data/live_token_client.dart';
import '../data/live_tool_bridge_client.dart';
import '../data/live_audio_capture_service.dart';
import '../data/live_audio_playback_service.dart';
import '../data/live_camera_stream_service.dart';
import '../data/live_mock_adapter.dart';
import 'live_turn_detector.dart';
import 'live_reconnect_policy.dart';
import 'live_permission_guard.dart';
import 'live_session_logger.dart';

/// High-level orchestrator for Gemini Live sessions.
///
/// Coordinates: permissions → token → WebSocket → mic → playback → camera →
/// tool bridge → UI state. This is the single point of control for the
/// live interaction stack.
///
/// The controller is feature-agnostic — use [LiveSessionConfig] presets
/// for onboarding vs quiz vs vision quest behavior.
class LiveSessionController {
  final ApiClient _apiClient;
  final LiveWebSocketClient _ws;
  final LiveTokenClient _tokenClient;
  final LiveToolBridgeClient _toolBridge;
  final AudioCaptureService _audioCapture;
  final AudioPlaybackService _audioPlayback;
  final LiveCameraStreamService _camera;
  final LivePermissionGuard _permissions;
  final LiveTurnDetector _turnDetector;
  final LiveReconnectPolicy _reconnectPolicy;
  final LiveSessionLogger _logger;
  final TelemetryService? _telemetry;
  final LiveMockAdapter? _mockAdapter;

  /// Feature flag: use mock adapter instead of real services.
  final bool useMock;

  /// If non-null, called before starting a real session. Return a non-null
  /// message to block start and show that error (e.g. auth/bootstrap not ready).
  final String? Function()? authPreconditionError;

  // ─── Subscriptions ──────────────────────────────
  StreamSubscription? _wsEventSub;
  StreamSubscription? _audioCaptureSub;
  StreamSubscription? _amplitudeSub;
  StreamSubscription? _cameraFrameSub;
  StreamSubscription? _playbackStateSub;
  StreamSubscription? _turnSub;
  StreamSubscription? _mockSub;

  // ─── State ──────────────────────────────────────
  LiveSessionState _state = const LiveSessionState();
  final _stateController = StreamController<LiveSessionState>.broadcast();
  Stream<LiveSessionState> get stateStream => _stateController.stream;
  LiveSessionState get state => _state;

  LiveSessionConfig? _activeConfig;

  /// Prevents duplicate session_ending logs + teardown calls.
  bool _isEnded = false;

  // ─── Debounce & Cost Guards ─────────────────────
  DateTime _lastCommandTime = DateTime(2000);
  static const _commandCooldown = Duration(seconds: 2);
  int _hintCount = 0;
  int _repeatCount = 0;
  static const maxHintsPerRound = 3;
  static const maxRepeatsPerRound = 5;
  int get hintCount => _hintCount;
  int get repeatCount => _repeatCount;

  // ─── Client-side speech detection ───────────────
  /// RMS amplitude threshold above which we consider the user to be speaking.
  /// 0.008 corresponds to a quiet but deliberate voice — avoids background noise.
  static const _speechActivityThreshold = 0.008;
  bool _userSpeechActive = false;
  // Throttle amplitude UI updates to reduce widget rebuilds during live sessions
  DateTime _lastAmplitudeEmit = DateTime(2000);
  static const _amplitudeEmitInterval = Duration(milliseconds: 80);
  Timer? _sessionDurationTimer;
  Timer? _silenceGuardTimer;
  String? _silenceGuardQuestionKey;
  int _silencePromptCount = 0;
  DateTime? _sessionStartupStartedAt;
  DateTime? _tokenFetchStartedAt;
  DateTime? _wsConnectStartedAt;
  DateTime? _sessionReadyAt;
  DateTime? _firstAudioChunkAt;

  /// Fires if setupComplete is not received from server within handshake window.
  static const _handshakeTimeout = Duration(seconds: 18);
  Timer? _handshakeTimer;

  LiveSessionController({
    required ApiClient apiClient,
    required LiveWebSocketClient ws,
    required LiveTokenClient tokenClient,
    required LiveToolBridgeClient toolBridge,
    required AudioCaptureService audioCapture,
    required AudioPlaybackService audioPlayback,
    required LiveCameraStreamService camera,
    LivePermissionGuard? permissions,
    LiveTurnDetector? turnDetector,
    LiveReconnectPolicy? reconnectPolicy,
    LiveSessionLogger? logger,
    TelemetryService? telemetry,
    LiveMockAdapter? mockAdapter,
    this.useMock = false,
    this.authPreconditionError,
  })  : _apiClient = apiClient,
        _ws = ws,
        _tokenClient = tokenClient,
        _toolBridge = toolBridge,
        _audioCapture = audioCapture,
        _audioPlayback = audioPlayback,
        _camera = camera,
        _permissions = permissions ?? LivePermissionGuard(),
        _turnDetector = turnDetector ?? LiveTurnDetector(),
        _reconnectPolicy = reconnectPolicy ?? LiveReconnectPolicy(),
        _logger = logger ?? LiveSessionLogger(),
        _telemetry = telemetry,
        _mockAdapter = mockAdapter;

  Future<void> _pauseMicCapture() async {
    if (_activeConfig?.enableAudioCapture != true) return;
    if (_audioCapture.isCapturing) {
      await _audioCapture.pauseCapture();
    }
    _emitState(_state.copyWith(
      isMicActive: false,
      audioAmplitude: 0.0,
      silencePromptCount: 0,
    ));
  }

  Future<void> _resumeMicCapture() async {
    if (_activeConfig?.enableAudioCapture != true) return;
    if (_audioPlayback.isPlaying || _state.isPlaybackActive) return;
    if (_state.phase == LiveConnectionPhase.failed ||
        _state.phase == LiveConnectionPhase.ended ||
        _state.phase == LiveConnectionPhase.reconnecting ||
        _state.phase == LiveConnectionPhase.roundComplete) {
      return;
    }
    if (_audioCapture.isCapturing) {
      _emitState(_state.copyWith(isMicActive: true));
      return;
    }
    try {
      await _audioCapture.resumeCapture();
    } catch (_) {
      try {
        await _audioCapture.startCapture();
      } catch (_) {}
    }
    _emitState(_state.copyWith(
      phase: LiveConnectionPhase.listeningForAnswer,
      isMicActive: true,
      silencePromptCount: 0,
    ));
  }

  // ═══════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════

  /// Start an onboarding session.
  Future<void> startOnboardingSession() =>
      _startSession(LiveSessionConfig.onboarding);

  /// Start a quiz session.
  Future<void> startQuizSession() => _startSession(LiveSessionConfig.quiz);

  /// Start a daily sprint session (3 rapid-fire questions).
  Future<void> startSprintSession() => _startSession(LiveSessionConfig.sprint);

  /// Start a vision quest session.
  Future<void> startVisionQuestSession() =>
      _startSession(LiveSessionConfig.visionQuest);

  /// Start an event challenge session.
  Future<void> startEventSession({
    required String eventId,
    required String eventTitle,
  }) =>
      _startSession(
          LiveSessionConfig.event(eventId: eventId, eventTitle: eventTitle));

  /// Retry the currently active mode with a clean socket and optional token refresh.
  Future<void> retrySession({bool hardReset = false}) async {
    if (hardReset) {
      _tokenClient.invalidate();
    }
    await _teardown(keepState: true);
    final config = _activeConfig;
    if (config != null) {
      await _startSession(config);
    }
  }

  /// Interrupt the model with user speech (barge-in).
  Future<void> interruptWithUserSpeech() async {
    if (!_state.phase.isActive &&
        _state.phase != LiveConnectionPhase.modelSpeaking) {
      return;
    }
    _logger.log('barge_in_requested');

    // Stop playback immediately
    await _audioPlayback.stopImmediately();

    // Resume mic capture
    await _resumeMicCapture();
    final micEnabled = _activeConfig?.enableAudioCapture == true;

    _emitState(_state.copyWith(
      phase:
          micEnabled ? LiveConnectionPhase.listeningForAnswer : LiveConnectionPhase.waitingForOpeningPrompt,
      isPlaybackActive: false,
      isMicActive: micEnabled,
    ));
  }

  /// Send a text fallback message (for typed input).
  void sendTextFallback(String text) {
    if (!_state.phase.isActive) return;
    _ws.sendText(text);
    _emitState(_state.copyWith(userTranscript: text));
  }

  /// Send a captured vision frame when camera UI is managed by the caller.
  void sendVisionFrame(Uint8List jpegData) {
    if (_state.mode != LiveSessionMode.visionQuest || !_state.phase.isActive) {
      return;
    }
    _ws.sendImage(jpegData);
    _logger.log('vision_frame_sent', metadata: {'bytes': jpegData.length});
  }

  /// Whether a command is allowed (debounce check).
  bool _isCommandAllowed() {
    final now = DateTime.now();
    if (now.difference(_lastCommandTime) < _commandCooldown) return false;
    _lastCommandTime = now;
    return true;
  }

  /// Request the model to repeat its last response.
  Future<void> requestRepeat() async {
    if (!_isCommandAllowed()) return;
    if (_repeatCount >= maxRepeatsPerRound) {
      _logger.log('repeat_capped', metadata: {'count': _repeatCount});
      return;
    }
    final roundId = _state.currentRoundId;
    if (roundId == null || roundId.isEmpty) return;
    _emitState(_state.copyWith(
      phase: LiveConnectionPhase.grading,
      activeToolName: 'request_round_repeat',
    ));
    try {
      final result = await _apiClient.requestRoundRepeat(roundId);
      final currentQuestion = _mapFromDynamic(result['currentQuestion']);
      final prompt = currentQuestion != null
          ? _promptFromQuestion(currentQuestion)
          : result['prompt'] as String?;
      _repeatCount = (result['repeatCount'] as num?)?.toInt() ?? _repeatCount;
      _emitState(_state.copyWith(
        phase: LiveConnectionPhase.waitingForOpeningPrompt,
        currentRoundId: result['roundId'] as String? ?? _state.currentRoundId,
        currentQuestionId:
            result['questionId'] as String? ?? _state.currentQuestionId,
        currentPrompt: prompt ?? _state.currentPrompt,
        silencePromptCount: 0,
        clearToolCall: true,
      ));
      if (prompt != null && prompt.isNotEmpty) {
        _ws.sendText(
          'Repeat this exact backend-authored question now, word for word: $prompt',
        );
      }
    } catch (e) {
      _handleError(LiveError(
        code: LiveErrorCode.toolExecutionFailed,
        message: 'Could not repeat the current question.',
        detail: e.toString(),
        recovery: LiveErrorRecovery.retry,
      ));
    }
  }

  /// Request a hint from the model.
  Future<void> requestHint() async {
    if (!_isCommandAllowed()) return;
    if (_hintCount >= maxHintsPerRound) {
      _logger.log('hint_capped', metadata: {'count': _hintCount});
      return;
    }
    final roundId = _state.currentRoundId;
    if (roundId == null || roundId.isEmpty) return;
    _emitState(_state.copyWith(
      phase: LiveConnectionPhase.grading,
      activeToolName: 'request_round_hint',
    ));
    try {
      final result = await _apiClient.requestRoundHint(roundId);
      final hint = result['hint'] as String? ?? '';
      final currentQuestion = _mapFromDynamic(result['currentQuestion']);
      final prompt = currentQuestion != null
          ? _promptFromQuestion(currentQuestion)
          : result['prompt'] as String?;
      _hintCount = (result['hintCount'] as num?)?.toInt() ?? _hintCount;
      _emitState(_state.copyWith(
        phase: LiveConnectionPhase.waitingForOpeningPrompt,
        currentRoundId: result['roundId'] as String? ?? _state.currentRoundId,
        currentQuestionId:
            result['questionId'] as String? ?? _state.currentQuestionId,
        currentPrompt: prompt ?? _state.currentPrompt,
        lastRewardPayload: result,
        silencePromptCount: 0,
        clearToolCall: true,
      ));
      if (hint.isNotEmpty) {
        _ws.sendText(
          'Give the player this exact backend-authored hint in one short sentence, then pause for their answer: $hint',
        );
      }
    } catch (e) {
      _handleError(LiveError(
        code: LiveErrorCode.toolExecutionFailed,
        message: 'Could not load a hint right now.',
        detail: e.toString(),
        recovery: LiveErrorRecovery.retry,
      ));
    }
  }

  /// Request difficulty change.
  Future<void> requestDifficultyChange(String difficulty) async {
    if (!_isCommandAllowed()) return;
    final roundId = _state.currentRoundId;
    if (roundId == null || roundId.isEmpty) return;
    _emitState(_state.copyWith(
      phase: LiveConnectionPhase.grading,
      activeToolName: 'change_round_difficulty',
    ));
    try {
      final result = await _apiClient.updateRoundDifficulty(
        roundId,
        difficulty: difficulty,
      );
      final currentQuestion = _mapFromDynamic(result['currentQuestion']);
      final prompt = currentQuestion != null
          ? _promptFromQuestion(currentQuestion)
          : _state.currentPrompt;
      final appliesFromQuestionIndex =
          (result['appliesFromQuestionIndex'] as num?)?.toInt();
      _emitState(_state.copyWith(
        phase: LiveConnectionPhase.waitingForOpeningPrompt,
        currentPrompt: prompt,
        currentQuestionId:
            currentQuestion?['id'] as String? ?? _state.currentQuestionId,
        currentQuestionIndex:
            (result['currentQuestionIndex'] as num?)?.toInt() ??
                _state.currentQuestionIndex,
        questionCount: (result['questionCount'] as num?)?.toInt() ??
            _state.questionCount,
        roundDifficultyPreference: difficulty,
        silencePromptCount: 0,
        clearToolCall: true,
      ));
      _ws.sendText(
        'Acknowledge the difficulty change briefly. '
        'Future questions should now be ${difficulty == 'easy' ? 'easier' : difficulty == 'hard' ? 'harder' : 'adaptive'}. '
        '${appliesFromQuestionIndex != null ? 'This applies from question ${appliesFromQuestionIndex + 1} onward. ' : ''}'
        'If you have the next exact backend-authored question, ask it now.',
      );
    } catch (e) {
      _handleError(LiveError(
        code: LiveErrorCode.toolExecutionFailed,
        message: 'Could not change difficulty right now.',
        detail: e.toString(),
        recovery: LiveErrorRecovery.retry,
      ));
    }
  }

  /// Submit a camera frame for vision quest.
  Future<void> attachCameraFrame() async {
    if (_state.mode != LiveSessionMode.visionQuest) return;
    final frame = await _camera.captureOneShot();
    if (frame != null) {
      _ws.sendImage(frame);
      _logger.log('camera_frame_sent', metadata: {'bytes': frame.length});
    }
  }

  /// End the session gracefully.
  Future<void> endSession() async {
    if (_isEnded) return;
    _isEnded = true;
    _logger.log('session_ending');
    await _logger.flush(
      sessionId:
          _state.sessionId ?? _state.correlationId ?? 'local_live_session',
      clearAfterFlush: true,
    );
    await _teardown();
    _emitState(_state.copyWith(phase: LiveConnectionPhase.ended));
  }

  /// Dispose all resources.
  void disposeSession() {
    final sessionId = _state.sessionId ?? _state.correlationId;
    if (sessionId != null && _logger.hasEntries) {
      unawaited(_logger.flush(sessionId: sessionId, clearAfterFlush: true));
    }
    _teardown();
    _stateController.close();
    _turnDetector.dispose();
    _logger.clear();
  }

  // ═══════════════════════════════════════════════════
  // SESSION STARTUP
  // ═══════════════════════════════════════════════════

  Future<void> _startSession(
    LiveSessionConfig config, {
    bool resetReconnectPolicy = true,
  }) async {
    // Always start from a clean transport/mic state so retries don't stack listeners.
    _isEnded = false;
    await _teardown(keepState: true);
    final previousState = _state;
    final preserveProgress = !resetReconnectPolicy;
    _activeConfig = config;
    if (resetReconnectPolicy) {
      _reconnectPolicy.reset();
    }
    if (resetReconnectPolicy) {
      _hintCount = 0;
      _repeatCount = 0;
    }
    _lastCommandTime = DateTime(2000);

    // Enforce max session duration
    _sessionDurationTimer?.cancel();
    _silenceGuardTimer?.cancel();
    _sessionDurationTimer = Timer(config.maxSessionDuration, () {
      _logger.log('session_duration_cap_reached');
      endSession();
    });
    final correlationId = 'live_${DateTime.now().millisecondsSinceEpoch}';
    _sessionStartupStartedAt = DateTime.now();
    _tokenFetchStartedAt = null;
    _wsConnectStartedAt = null;
    _sessionReadyAt = null;
    _firstAudioChunkAt = null;
    _silenceGuardQuestionKey = null;
    _silencePromptCount = 0;

    _emitState(LiveSessionState(
      mode: config.mode,
      phase: LiveConnectionPhase.idle,
      correlationId: correlationId,
      sessionId: preserveProgress ? previousState.sessionId : null,
      currentPrompt: preserveProgress ? previousState.currentPrompt : null,
      currentRoundId: preserveProgress ? previousState.currentRoundId : null,
      currentQuestionId:
          preserveProgress ? previousState.currentQuestionId : null,
      questionCount: preserveProgress ? previousState.questionCount : 0,
      currentQuestionIndex:
          preserveProgress ? previousState.currentQuestionIndex : 0,
      roundTopic: preserveProgress ? previousState.roundTopic : null,
      roundDifficultyPreference:
          preserveProgress ? previousState.roundDifficultyPreference : null,
      grantedXp: preserveProgress ? previousState.grantedXp : 0,
      grantedSectors: preserveProgress ? previousState.grantedSectors : 0,
      grantedStone: preserveProgress ? previousState.grantedStone : 0,
      grantedGlass: preserveProgress ? previousState.grantedGlass : 0,
      grantedWood: preserveProgress ? previousState.grantedWood : 0,
      grantedComboXp: preserveProgress ? previousState.grantedComboXp : 0,
      reconnectAttempts: _reconnectPolicy.attempts,
      silencePromptCount: 0,
    ));

    unawaited(
      _telemetry?.track(
            'live_session_start_requested',
            route: '/play',
            correlationId: correlationId,
            metadata: {
              'mode': config.mode.name,
              'sessionType': config.sessionTypeOverride ?? config.mode.name,
              if (config.eventId != null) 'eventId': config.eventId,
              'preserveProgress': preserveProgress,
            },
          ) ??
          Future.value(),
    );

    // Use mock adapter in dev mode
    if (useMock && _mockAdapter != null) {
      return _startMockSession(config);
    }

    // 0. Auth/bootstrap precondition — block start with actionable message if invalid
    final preconditionError = authPreconditionError?.call();
    if (preconditionError != null && preconditionError.isNotEmpty) {
      unawaited(
        _telemetry?.track(
              'live_session_blocked',
              route: '/play',
              correlationId: correlationId,
              metadata: {
                'mode': config.mode.name,
                'reason': preconditionError,
              },
            ) ??
            Future.value(),
      );
      _emitState(_state.copyWith(
        phase: LiveConnectionPhase.failed,
        error: LiveError(
          code: LiveErrorCode.tokenFetchFailed,
          message: preconditionError,
          recovery: LiveErrorRecovery.fatal,
        ),
      ));
      return;
    }

    // 1. Check permissions
    _emitState(_state.copyWith(phase: LiveConnectionPhase.connecting));
    final permError = await _permissions.checkPermissions(
      needsMicrophone: config.enableAudioCapture,
      needsCamera: config.enableCamera,
      needsLocation: false,
    );
    if (permError != null) {
      unawaited(
        _telemetry?.track(
              'live_session_permission_blocked',
              route: '/play',
              correlationId: correlationId,
              metadata: {
                'mode': config.mode.name,
                'code': permError.code.name,
              },
            ) ??
            Future.value(),
      );
      _emitState(_state.copyWith(
        phase: LiveConnectionPhase.failed,
        error: permError,
      ));
      return;
    }

    final primedRoundFuture = _primeRoundIfNeeded(config);

    // 2. Fetch token
    _emitState(_state.copyWith(phase: LiveConnectionPhase.connecting));
    _logger.log('fetching_token', metadata: {'correlationId': correlationId});
    _tokenFetchStartedAt = DateTime.now();

    try {
      final tokenFuture = _tokenClient.fetchToken(
        sessionType: config.sessionTypeOverride ?? config.mode.name,
        correlationId: correlationId,
        eventId: config.eventId,
      );
      final token = await tokenFuture;
      final primedRound = await primedRoundFuture;
      if (primedRound != null) {
        _applyPrimedRound(primedRound);
      }

      // 3. Connect WebSocket
      _emitState(_state.copyWith(phase: LiveConnectionPhase.connecting));
      _logger.log('connecting_ws', metadata: {
        'correlationId': correlationId,
        'model': token.model,
        if (_tokenFetchStartedAt != null)
          'tokenFetchMs':
              DateTime.now().difference(_tokenFetchStartedAt!).inMilliseconds,
      });
      _wsConnectStartedAt = DateTime.now();

      _setupEventListeners();

      await _ws.connect(
        token: token.token,
        authType: token.authType,
        model: token.model,
        // Prefer backend-personalized instruction (has user name, interests, difficulty).
        // Fall back to static config preset if backend didn't return one.
        systemInstruction: token.systemInstruction ?? config.systemInstruction,
        voiceName: config.voiceName,
        responseModalities: config.responseModalities,
        tools: token.tools,
        websocketUrl: token.websocketUrl,
      );
      _emitState(
        _state.copyWith(phase: LiveConnectionPhase.waitingForOpeningPrompt),
      );
      if (token.sessionId != null && token.sessionId!.isNotEmpty) {
        // Keep backend-issued session id for tool execution authorization.
        _emitState(_state.copyWith(sessionId: token.sessionId));
      }

      _ws.setInactivityTimeout(config.inactivityTimeout);

      // If server never sends setupComplete, fail after handshake timeout
      _handshakeTimer?.cancel();
      _handshakeTimer = Timer(_handshakeTimeout, () {
        if (_state.phase == LiveConnectionPhase.connecting ||
            _state.phase == LiveConnectionPhase.waitingForOpeningPrompt) {
          _logger.log('handshake_timeout');
          _emitState(_state.copyWith(
            phase: LiveConnectionPhase.failed,
            error: const LiveError(
              code: LiveErrorCode.wsConnectFailed,
              message:
                  "Live session didn't start in time. Check your connection and try again.",
              recovery: LiveErrorRecovery.retry,
            ),
          ));
          _teardown(keepState: true);
        }
      });
    } on LiveError catch (e) {
      unawaited(
        _telemetry?.track(
              'live_session_start_failed',
              route: '/play',
              correlationId: _state.correlationId,
              metadata: {
                'mode': config.mode.name,
                'code': e.code.name,
                'recovery': e.recovery.name,
                'tokenFetchMs': _tokenFetchStartedAt == null
                    ? null
                    : DateTime.now()
                        .difference(_tokenFetchStartedAt!)
                        .inMilliseconds,
              },
            ) ??
            Future.value(),
      );
      _logger.log('startup_live_error', metadata: {
        'correlationId': _state.correlationId,
        'code': e.code.name,
      });
      _emitState(_state.copyWith(
        phase: LiveConnectionPhase.failed,
        error: e,
      ));
    } catch (e) {
      unawaited(
        _telemetry?.track(
              'live_session_start_failed',
              route: '/play',
              correlationId: _state.correlationId,
              metadata: {
                'mode': config.mode.name,
                'code': 'unexpected',
                'detail': e.toString(),
              },
            ) ??
            Future.value(),
      );
      _logger.log('startup_unexpected_error', metadata: {
        'correlationId': _state.correlationId,
        'detail': e.toString(),
      });
      _emitState(_state.copyWith(
        phase: LiveConnectionPhase.failed,
        error: LiveError(
          code: LiveErrorCode.unknown,
          message: 'Session startup failed',
          detail: e.toString(),
          recovery: LiveErrorRecovery.retry,
        ),
      ));
    }
  }

  void _startMockSession(LiveSessionConfig config) {
    final mock = _mockAdapter;
    if (mock == null) return;

    _mockSub = mock.events.listen(_handleEvent);
    if (config.mode == LiveSessionMode.quiz) {
      mock.replayQuizSession();
    } else {
      mock.replayOnboardingSession();
    }
  }

  // ═══════════════════════════════════════════════════
  // EVENT HANDLING
  // ═══════════════════════════════════════════════════

  void _setupEventListeners() {
    _wsEventSub = _ws.events.listen(_handleEvent);

    // Audio capture → WebSocket + amplitude + client-side speech detection
    _audioCaptureSub = _audioCapture.audioStream.listen((chunk) {
      _ws.sendAudio(chunk);
    });
    _amplitudeSub = _audioCapture.amplitudeStream.listen((amp) {
      if (!_state.isMicActive) return;

      // Throttle UI state emissions to ~12fps to reduce widget rebuilds.
      final now = DateTime.now();
      if (now.difference(_lastAmplitudeEmit) >= _amplitudeEmitInterval) {
        _lastAmplitudeEmit = now;
        _emitState(_state.copyWith(audioAmplitude: amp));
      }

      // Drive client-side speech detection from RMS amplitude.
      // The turn detector transitions userSpeaking ↔ idle, which updates the
      // UI phase so users see visual feedback that they're being heard.
      final isSpeaking = amp > _speechActivityThreshold;
      if (isSpeaking != _userSpeechActive) {
        _userSpeechActive = isSpeaking;
        _turnDetector.onMicActivity(isSpeaking);
      }
    });

    // Camera frames → WebSocket (vision quest only)
    _cameraFrameSub = _camera.frameStream.listen((frame) {
      _ws.sendImage(frame);
    });

    // Playback state → turn detector
    _playbackStateSub = _audioPlayback.playbackStateStream.listen((playing) {
      _turnDetector.onPlaybackState(playing);
      if (playing) {
        unawaited(_pauseMicCapture());
      } else if (_activeConfig?.enableAudioCapture == true &&
          _state.phase != LiveConnectionPhase.grading &&
          _state.phase != LiveConnectionPhase.roundComplete &&
          _state.phase != LiveConnectionPhase.failed &&
          _state.phase != LiveConnectionPhase.ended) {
        unawaited(_resumeMicCapture());
      }
      _emitState(_state.copyWith(
        isPlaybackActive: playing,
        phase: playing ? LiveConnectionPhase.modelSpeaking : _state.phase,
      ));
    });

    // Turn detector → state
    _turnSub = _turnDetector.turnStream.listen((turn) {
      switch (turn) {
        case TurnState.userSpeaking:
          if (_state.phase == LiveConnectionPhase.listeningForAnswer) {
            _emitState(_state.copyWith(phase: LiveConnectionPhase.listeningForAnswer));
          }
        case TurnState.modelSpeaking:
          _emitState(_state.copyWith(phase: LiveConnectionPhase.modelSpeaking));
        case TurnState.idle:
          if (_state.phase == LiveConnectionPhase.modelSpeaking &&
              !_state.isRoundComplete) {
            _emitState(
              _state.copyWith(phase: LiveConnectionPhase.listeningForAnswer),
            );
          }
      }
    });
  }

  void _handleEvent(LiveEvent event) {
    _logger.logEvent(event);
    _turnDetector.processEvent(event);

    switch (event) {
      case SessionStarted(sessionId: final id):
        _onSessionStarted(id);
      case SessionClosed():
        _onSessionClosed();
      case ModelTurnStarted():
        unawaited(_pauseMicCapture());
        _emitState(_state.copyWith(
          phase: LiveConnectionPhase.modelSpeaking,
          modelTranscript: '',
          isModelTranscriptFinal: false,
        ));
      case ModelTurnEnded():
        // Don't reset phase if we're waiting for a tool result — the model
        // sends turnComplete immediately after a tool call, but the tool is
        // still being executed. The phase will be reset by _handleToolCall.
        if (_state.phase != LiveConnectionPhase.grading &&
            _state.phase != LiveConnectionPhase.roundComplete &&
            !_audioPlayback.isPlaying) {
          if (_activeConfig?.enableAudioCapture != true &&
              _state.mode == LiveSessionMode.onboarding) {
            unawaited(endSession());
            return;
          }
          unawaited(_resumeMicCapture());
          _emitState(_state.copyWith(
            phase: LiveConnectionPhase.listeningForAnswer,
            isModelTranscriptFinal: true,
            silencePromptCount: 0,
          ));
        }
      case TranscriptDelta(text: final t, isModel: final m):
        if (m) {
          _emitState(_state.copyWith(
            modelTranscript: _state.modelTranscript + t,
          ));
        } else {
          _emitState(_state.copyWith(
            userTranscript: t,
            silencePromptCount: 0,
          ));
        }
      case TranscriptFinal(text: final t, isModel: final m):
        if (m) {
          _emitState(_state.copyWith(
            modelTranscript: t,
            isModelTranscriptFinal: true,
          ));
        } else {
          _emitState(_state.copyWith(
            userTranscript: t,
            isUserTranscriptFinal: true,
            silencePromptCount: 0,
          ));
        }
      case AudioChunkReceived(data: final d, mimeType: final m):
        _firstAudioChunkAt ??= DateTime.now();
        if (_sessionStartupStartedAt != null && _sessionReadyAt != null) {
          unawaited(
            _telemetry?.track(
                  'live_first_audio',
                  route: '/play',
                  correlationId: _state.correlationId,
                  dedupeKey:
                      'live-first-audio-${_state.correlationId ?? _state.sessionId ?? _state.mode.name}',
                  metadata: {
                    'mode': _state.mode.name,
                    'startupMs': _firstAudioChunkAt!
                        .difference(_sessionStartupStartedAt!)
                        .inMilliseconds,
                    'postConnectMs': _firstAudioChunkAt!
                        .difference(_sessionReadyAt!)
                        .inMilliseconds,
                  },
                ) ??
                Future.value(),
          );
          _logger.log('first_audio_received', metadata: {
            'startupMs':
                _firstAudioChunkAt!.difference(_sessionStartupStartedAt!).inMilliseconds,
            'postConnectMs':
                _firstAudioChunkAt!.difference(_sessionReadyAt!).inMilliseconds,
          });
        }
        _audioPlayback.enqueue(Uint8List.fromList(d), m);
        _emitState(_state.copyWith(isPlaybackActive: true));
      case ToolCallRequested():
        _handleToolCall(event);
      case ToolCallCompleted():
        _emitState(_state.copyWith(clearToolCall: true));
      case ToolCallCancelled(cancelledIds: final ids):
        // Server cancelled one or more pending tool calls because the user
        // interrupted. Reset the waitingForToolResult phase so the UI doesn't
        // stay stuck showing "CHECKING..." indefinitely.
        _logger.log('tool_call_cancelled', metadata: {'ids': ids.join(',')});
        unawaited(_resumeMicCapture());
        _emitState(_state.copyWith(
          phase: LiveConnectionPhase.listeningForAnswer,
          silencePromptCount: 0,
          clearToolCall: true,
        ));
      case InterruptionDetected():
        interruptWithUserSpeech();
      case SessionError(error: final e):
        _handleError(e);
      case SessionWarning(message: final m):
        _logger.log('warning', metadata: {'message': m});
      default:
        break;
    }
  }

  void _onSessionStarted(String sessionId) {
    _handshakeTimer?.cancel();
    _handshakeTimer = null;
    _sessionReadyAt = DateTime.now();
    _emitState(_state.copyWith(
      phase: LiveConnectionPhase.waitingForOpeningPrompt,
      // Prefer backend-minted session id; websocket session id can differ by transport.
      sessionId: _state.sessionId ?? sessionId,
      isMicActive: false,
      clearError: true,
    ));

    // Start camera if vision quest
    if (_activeConfig?.enableCamera == true) {
      _camera.initialize().then((_) {
        _camera.startPeriodicCapture();
        _emitState(_state.copyWith(isCameraActive: true));
      });
    }

    _logger.log('session_ready', metadata: {'sessionId': sessionId});
    if (_sessionStartupStartedAt != null) {
      final startupMs =
          _sessionReadyAt!.difference(_sessionStartupStartedAt!).inMilliseconds;
      final tokenFetchMs = _tokenFetchStartedAt != null
          ? (_wsConnectStartedAt ?? _sessionReadyAt!)
              .difference(_tokenFetchStartedAt!)
              .inMilliseconds
          : null;
      final connectMs = _wsConnectStartedAt != null
          ? _sessionReadyAt!.difference(_wsConnectStartedAt!).inMilliseconds
          : null;
      unawaited(
        _telemetry?.track(
              'live_session_ready',
              route: '/play',
              correlationId: _state.correlationId,
              metadata: {
                'mode': _state.mode.name,
                'startupMs': startupMs,
                if (tokenFetchMs != null) 'tokenFetchMs': tokenFetchMs,
                if (connectMs != null) 'connectMs': connectMs,
              },
            ) ??
            Future.value(),
      );
      _logger.log('session_startup_timing', metadata: {
        'startupMs': startupMs,
        if (tokenFetchMs != null) 'tokenFetchMs': tokenFetchMs,
        if (connectMs != null) 'connectMs': connectMs,
      });
    }

    final primedPrompt = _state.currentPrompt;
    if (primedPrompt != null &&
        primedPrompt.isNotEmpty &&
        _state.currentRoundId != null) {
      _logger.log('opening_prompt_primed', metadata: {
        'roundId': _state.currentRoundId,
        'questionId': _state.currentQuestionId,
      });
      _ws.sendText(
        'A backend-authored round is already active. '
        'Do not call start_live_round. '
        'Ask this exact backend-authored question now, then pause for the player answer: $primedPrompt',
      );
      return;
    }

    // The native audio model requires a user turn to begin generating.
    // Send an empty kickstart turn so Gemini starts its opening response.
    _ws.sendKickstart();
  }

  void _onSessionClosed() {
    // Server closed the connection normally — log and clean up.
    _logger.log('session_closed_by_server');
    endSession();
  }

  // ═══════════════════════════════════════════════════
  // TOOL CALL HANDLING
  // ═══════════════════════════════════════════════════

  Future<void> _handleToolCall(ToolCallRequested call) async {
    _emitState(_state.copyWith(
      phase: LiveConnectionPhase.grading,
      activeToolCallId: call.callId,
      activeToolName: call.toolName,
    ));

    try {
      final result = await _toolBridge.execute(
        call,
        sessionId: _state.sessionId ?? '',
        correlationId: _state.correlationId,
      );

      // Send result back to Gemini
      _ws.sendToolResponse(call.callId, call.toolName, result.data);

      final roundJustCompleted = call.toolName == 'end_round' && result.success;

      // Accumulate backend-granted totals from tool results
      int addXp = 0,
          addSectors = 0,
          addStone = 0,
          addGlass = 0,
          addWood = 0,
          addComboXp = 0;
      final d = result.data;
      String? currentRoundId = _state.currentRoundId;
      String? currentQuestionId = _state.currentQuestionId;
      String? currentPrompt = _state.currentPrompt;
      int questionCount = _state.questionCount;
      int currentQuestionIndex = _state.currentQuestionIndex;
      String? roundTopic = _state.roundTopic;
      String? roundDifficultyPreference = _state.roundDifficultyPreference;
      var clearPrompt = false;
      if (call.toolName == 'grade_answer') {
        addXp = (d['xpAwarded'] as num?)?.toInt() ??
            (d['pointsAwarded'] as num?)?.toInt() ??
            0;
        addSectors = (d['sectorsGained'] as num?)?.toInt() ?? 0;
        addComboXp = (d['comboXp'] as num?)?.toInt() ?? 0;
        final mats = d['materialsEarned'];
        if (mats is Map) {
          addStone = (mats['stone'] as num?)?.toInt() ?? 0;
          addGlass = (mats['glass'] as num?)?.toInt() ?? 0;
          addWood = (mats['wood'] as num?)?.toInt() ?? 0;
        }
        currentRoundId = d['roundId'] as String? ?? currentRoundId;
        currentQuestionIndex = (d['currentQuestionIndex'] as num?)?.toInt() ??
            currentQuestionIndex;
        questionCount = (d['questionCount'] as num?)?.toInt() ?? questionCount;
        roundTopic = d['topic'] as String? ?? roundTopic;
        roundDifficultyPreference =
            _normalizeDifficultyLabel(d['difficulty']) ??
                roundDifficultyPreference;
        final nextQuestion = _mapFromDynamic(d['nextQuestion']);
        if (nextQuestion != null) {
          currentQuestionId =
              nextQuestion['id'] as String? ?? currentQuestionId;
          currentPrompt = _promptFromQuestion(nextQuestion) ?? currentPrompt;
        }
        if (d['roundComplete'] == true) {
          clearPrompt = true;
          currentQuestionId = null;
        }
      } else if (call.toolName == 'award_territory') {
        addSectors = (d['sectorsAdded'] as num?)?.toInt() ??
            (d['sectorsGained'] as num?)?.toInt() ??
            0;
      } else if (call.toolName == 'grant_materials') {
        addStone = (d['stone'] as num?)?.toInt() ?? 0;
        addGlass = (d['glass'] as num?)?.toInt() ?? 0;
        addWood = (d['wood'] as num?)?.toInt() ?? 0;
      } else if (call.toolName == 'apply_combo_bonus') {
        addComboXp = (d['bonusXp'] as num?)?.toInt() ?? 0;
        final mats = d['bonusMaterials'];
        if (mats is Map) {
          addStone = (mats['stone'] as num?)?.toInt() ?? 0;
          addGlass = (mats['glass'] as num?)?.toInt() ?? 0;
          addWood = (mats['wood'] as num?)?.toInt() ?? 0;
        }
      } else if (call.toolName == 'start_live_round') {
        currentRoundId = d['roundId'] as String? ?? currentRoundId;
        roundTopic = d['topic'] as String? ?? roundTopic;
        roundDifficultyPreference =
            _normalizeDifficultyLabel(d['difficulty']) ??
                roundDifficultyPreference;
        questionCount = (d['questionCount'] as num?)?.toInt() ?? questionCount;
        currentQuestionIndex =
            (d['currentQuestionIndex'] as num?)?.toInt() ?? 0;
        _hintCount = (d['hintCount'] as num?)?.toInt() ?? 0;
        _repeatCount = (d['repeatCount'] as num?)?.toInt() ?? 0;
        final currentQuestion = _mapFromDynamic(d['currentQuestion']);
        if (currentQuestion != null) {
          currentQuestionId =
              currentQuestion['id'] as String? ?? currentQuestionId;
          currentPrompt = _promptFromQuestion(currentQuestion) ?? currentPrompt;
        }
      } else if (call.toolName == 'request_round_hint') {
        currentRoundId = d['roundId'] as String? ?? currentRoundId;
        currentQuestionId = d['questionId'] as String? ?? currentQuestionId;
        _hintCount = (d['hintCount'] as num?)?.toInt() ?? _hintCount;
        final currentQuestion = _mapFromDynamic(d['currentQuestion']);
        if (currentQuestion != null) {
          currentPrompt = _promptFromQuestion(currentQuestion) ?? currentPrompt;
        } else {
          currentPrompt = d['prompt'] as String? ?? currentPrompt;
        }
      } else if (call.toolName == 'request_round_repeat') {
        currentRoundId = d['roundId'] as String? ?? currentRoundId;
        currentQuestionId = d['questionId'] as String? ?? currentQuestionId;
        _repeatCount = (d['repeatCount'] as num?)?.toInt() ?? _repeatCount;
        final currentQuestion = _mapFromDynamic(d['currentQuestion']);
        if (currentQuestion != null) {
          currentPrompt = _promptFromQuestion(currentQuestion) ?? currentPrompt;
        } else {
          currentPrompt = d['prompt'] as String? ?? currentPrompt;
        }
      } else if (call.toolName == 'end_round') {
        addXp = (d['dailyBonusXp'] as num?)?.toInt() ?? 0;
        clearPrompt = true;
        currentQuestionId = null;
      }

      final nextPhase = switch (call.toolName) {
        'end_round' => LiveConnectionPhase.roundComplete,
        'start_live_round' ||
        'grade_answer' ||
        'request_round_hint' ||
        'request_round_repeat' =>
          LiveConnectionPhase.waitingForOpeningPrompt,
        _ => currentQuestionId != null
            ? LiveConnectionPhase.listeningForAnswer
            : LiveConnectionPhase.waitingForOpeningPrompt,
      };

      _emitState(_state.copyWith(
        phase: roundJustCompleted ? LiveConnectionPhase.roundComplete : nextPhase,
        currentRoundId: currentRoundId,
        currentQuestionId: currentQuestionId,
        currentPrompt: currentPrompt,
        questionCount: questionCount,
        currentQuestionIndex: currentQuestionIndex,
        roundTopic: roundTopic,
        roundDifficultyPreference: roundDifficultyPreference,
        silencePromptCount: 0,
        lastRewardPayload: result.data,
        clearToolCall: true,
        clearPrompt: clearPrompt,
        isRoundComplete: roundJustCompleted ? true : null,
        grantedXp: _state.grantedXp + addXp + addComboXp,
        grantedSectors: _state.grantedSectors + addSectors,
        grantedStone: _state.grantedStone + addStone,
        grantedGlass: _state.grantedGlass + addGlass,
        grantedWood: _state.grantedWood + addWood,
        grantedComboXp: _state.grantedComboXp + addComboXp,
      ));

      if (roundJustCompleted) {
        unawaited(
          _telemetry?.track(
                'live_round_completed',
                route: '/play',
                correlationId: _state.correlationId,
                metadata: {
                  'mode': _state.mode.name,
                  'roundId': currentRoundId,
                  'questionCount': questionCount,
                  'xpGranted': _state.grantedXp + addXp + addComboXp,
                  'sectorsGranted': _state.grantedSectors + addSectors,
                },
              ) ??
              Future.value(),
        );
      }

      _logger.log('tool_result_sent', metadata: {
        'tool': call.toolName,
        'success': result.success,
      });
    } catch (e) {
      _logger.log('tool_call_error', metadata: {
        'tool': call.toolName,
        'callId': call.callId,
        'error': e.toString(),
      });
      // Send error back to Gemini so it can respond gracefully.
      _ws.sendToolResponse(call.callId, call.toolName, {
        'error': 'Tool execution failed',
        'toolName': call.toolName,
        'detail': e.toString(),
      });
      _emitState(_state.copyWith(
        phase: LiveConnectionPhase.listeningForAnswer,
        silencePromptCount: 0,
        clearToolCall: true,
      ));
    }
  }

  // ═══════════════════════════════════════════════════
  // ERROR + RECONNECT
  // ═══════════════════════════════════════════════════

  void _handleError(LiveError error) {
    _handshakeTimer?.cancel();
    _handshakeTimer = null;
    _logger.log('error', metadata: {
      'code': error.code.name,
      'recovery': error.recovery.name,
    });
    unawaited(
      _telemetry?.track(
            'live_session_error',
            route: '/play',
            correlationId: _state.correlationId,
            metadata: {
              'mode': _state.mode.name,
              'phase': _state.phase.name,
              'code': error.code.name,
              'recovery': error.recovery.name,
              'reconnectAttempts': _reconnectPolicy.attempts,
            },
          ) ??
          Future.value(),
    );

    switch (error.recovery) {
      case LiveErrorRecovery.reconnect:
        _attemptReconnect();
        return;
      case LiveErrorRecovery.refreshToken:
        _tokenClient.invalidate();
        _attemptReconnect();
        return;
      case LiveErrorRecovery.retry:
        _emitState(_state.copyWith(
          phase: LiveConnectionPhase.failed,
          error: error,
        ));
        return;
      case LiveErrorRecovery.openSettings:
      case LiveErrorRecovery.fatal:
        _emitState(_state.copyWith(
          phase: LiveConnectionPhase.failed,
          error: error,
        ));
        return;
    }
  }

  Future<void> _attemptReconnect() async {
    if (!_reconnectPolicy.canRetry) {
      unawaited(
        _telemetry?.track(
              'live_reconnect_exhausted',
              route: '/play',
              correlationId: _state.correlationId,
              metadata: {
                'mode': _state.mode.name,
                'attempts': _reconnectPolicy.attempts,
              },
            ) ??
            Future.value(),
      );
      _emitState(_state.copyWith(
        phase: LiveConnectionPhase.failed,
        error: const LiveError(
          code: LiveErrorCode.wsConnectFailed,
          message: 'Could not reconnect after multiple attempts',
          recovery: LiveErrorRecovery.fatal,
        ),
      ));
      return;
    }

    _reconnectPolicy.recordAttempt();
    _emitState(_state.copyWith(
      phase: LiveConnectionPhase.reconnecting,
      reconnectAttempts: _reconnectPolicy.attempts,
    ));

    final delay = _reconnectPolicy.nextDelay;
    _logger.log('reconnecting', metadata: {
      'attempt': _reconnectPolicy.attempts,
      'delay': delay.inMilliseconds,
    });
    unawaited(
      _telemetry?.track(
            'live_reconnect_attempt',
            route: '/play',
            correlationId: _state.correlationId,
            metadata: {
              'mode': _state.mode.name,
              'attempt': _reconnectPolicy.attempts,
              'delayMs': delay.inMilliseconds,
            },
          ) ??
          Future.value(),
    );

    // Wait with backoff
    await Future.delayed(delay);

    // Invalidate token if needed
    if (_reconnectPolicy.shouldRefreshToken) {
      _tokenClient.invalidate();
    }

    // Teardown current connection and retry
    await _teardown(keepState: true);
    if (_activeConfig != null) {
      await _startSession(_activeConfig!, resetReconnectPolicy: false);
    }
  }

  // ═══════════════════════════════════════════════════
  // TEARDOWN
  // ═══════════════════════════════════════════════════

  Future<void> _teardown({bool keepState = false}) async {
    _sessionDurationTimer?.cancel();
    _handshakeTimer?.cancel();
    _silenceGuardTimer?.cancel();
    _handshakeTimer = null;
    _silenceGuardTimer = null;
    await _wsEventSub?.cancel();
    await _audioCaptureSub?.cancel();
    await _amplitudeSub?.cancel();
    await _cameraFrameSub?.cancel();
    await _playbackStateSub?.cancel();
    await _turnSub?.cancel();
    await _mockSub?.cancel();
    _wsEventSub = null;
    _audioCaptureSub = null;
    _amplitudeSub = null;
    _cameraFrameSub = null;
    _playbackStateSub = null;
    _turnSub = null;
    _mockSub = null;

    _userSpeechActive = false;
    await _audioCapture.stopCapture();
    await _audioPlayback.stopImmediately();
    _camera.stopPeriodicCapture();
    await _ws.disconnect();
    _mockAdapter?.stop();

    if (!keepState) {
      _emitState(_state.copyWith(
        isMicActive: false,
        isPlaybackActive: false,
        isCameraActive: false,
        audioAmplitude: 0.0,
      ));
    }
  }

  // ═══════════════════════════════════════════════════
  // STATE EMISSION
  // ═══════════════════════════════════════════════════

  void _emitState(LiveSessionState newState) {
    _state = newState;
    _syncSilenceGuard();
    _stateController.add(newState);
  }

  Map<String, dynamic>? _mapFromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, dynamicValue) => MapEntry('$key', dynamicValue));
    }
    return null;
  }

  String? _promptFromQuestion(Map<String, dynamic> question) {
    return question['spokenPhrase'] as String? ?? question['text'] as String?;
  }

  String? _normalizeDifficultyLabel(dynamic value) {
    final raw = value as String?;
    if (raw == null || raw.isEmpty) return null;
    if (raw == 'easy' || raw == 'hard' || raw == 'dynamic') return raw;
    if (raw == 'medium') return 'dynamic';
    return null;
  }

  void _syncSilenceGuard() {
    _silenceGuardTimer?.cancel();
    _silenceGuardTimer = null;

    if (_state.phase != LiveConnectionPhase.listeningForAnswer ||
        _state.currentRoundId == null ||
        _state.currentQuestionId == null ||
        _state.isRoundComplete ||
        _state.isPlaybackActive) {
      return;
    }

    final key =
        '${_state.currentRoundId}:${_state.currentQuestionId}:${_state.currentQuestionIndex}';
    if (_silenceGuardQuestionKey != key) {
      _silenceGuardQuestionKey = key;
      _silencePromptCount = 0;
    }

    if (_silencePromptCount >= 2) return;

    final timeout = _silencePromptCount == 0
        ? const Duration(seconds: 8)
        : const Duration(seconds: 6);
    _silenceGuardTimer = Timer(timeout, _handleListeningSilence);
  }

  void _handleListeningSilence() {
    if (_state.phase != LiveConnectionPhase.listeningForAnswer ||
        _state.isPlaybackActive ||
        _state.isRoundComplete ||
        _userSpeechActive) {
      _syncSilenceGuard();
      return;
    }

    if (_silencePromptCount == 0) {
      _silencePromptCount = 1;
      _logger.log('listening_silence_reprompt', metadata: {
        'roundId': _state.currentRoundId,
        'questionId': _state.currentQuestionId,
      });
      _emitState(_state.copyWith(
        phase: LiveConnectionPhase.waitingForOpeningPrompt,
        silencePromptCount: 1,
      ));
      _ws.sendText(
        'The player is still silent. Repeat the same backend-authored question once, gently and briefly, then pause for their answer.',
      );
      return;
    }

    if (_silencePromptCount == 1) {
      _silencePromptCount = 2;
      _logger.log('listening_silence_guidance', metadata: {
        'roundId': _state.currentRoundId,
        'questionId': _state.currentQuestionId,
      });
      _emitState(_state.copyWith(
        phase: LiveConnectionPhase.waitingForOpeningPrompt,
        silencePromptCount: 2,
      ));
      _ws.sendText(
        'The player is still silent. In one short line, tell them they can answer now, say hint, or say repeat. Then stop talking.',
      );
    }
  }

  Future<Map<String, dynamic>?> _primeRoundIfNeeded(
    LiveSessionConfig config,
  ) async {
    if (config.mode == LiveSessionMode.onboarding ||
        config.mode == LiveSessionMode.visionQuest) {
      return null;
    }
    if (_state.currentRoundId != null && _state.currentQuestionId != null) {
      return null;
    }

    final startedAt = DateTime.now();
    try {
      final response = await _apiClient.startRound(
        mode: switch (config.mode) {
          LiveSessionMode.sprint => 'sprint',
          LiveSessionMode.quiz => 'quiz',
          _ => 'event',
        },
        eventId: config.eventId,
      );
      _logger.log('round_primed', metadata: {
        'mode': config.mode.name,
        'durationMs': DateTime.now().difference(startedAt).inMilliseconds,
        'roundId': response['roundId'],
      });
      unawaited(
        _telemetry?.track(
              'live_round_primed',
              route: '/play',
              correlationId: _state.correlationId,
              metadata: {
                'mode': config.mode.name,
                'durationMs':
                    DateTime.now().difference(startedAt).inMilliseconds,
              },
            ) ??
            Future.value(),
      );
      return response;
    } catch (e) {
      _logger.log('round_prime_failed', metadata: {
        'mode': config.mode.name,
        'detail': e.toString(),
      });
      unawaited(
        _telemetry?.track(
              'live_round_prime_failed',
              route: '/play',
              correlationId: _state.correlationId,
              metadata: {
                'mode': config.mode.name,
                'detail': e.toString(),
              },
            ) ??
            Future.value(),
      );
      return null;
    }
  }

  void _applyPrimedRound(Map<String, dynamic> response) {
    final currentQuestion = _mapFromDynamic(response['currentQuestion']);
    final prompt = currentQuestion != null
        ? _promptFromQuestion(currentQuestion)
        : response['prompt'] as String?;
    _hintCount = (response['hintCount'] as num?)?.toInt() ?? 0;
    _repeatCount = (response['repeatCount'] as num?)?.toInt() ?? 0;
    _emitState(_state.copyWith(
      currentRoundId: response['roundId'] as String? ?? _state.currentRoundId,
      currentQuestionId:
          currentQuestion?['id'] as String? ?? _state.currentQuestionId,
      currentPrompt: prompt ?? _state.currentPrompt,
      questionCount:
          (response['questionCount'] as num?)?.toInt() ?? _state.questionCount,
      currentQuestionIndex:
          (response['currentQuestionIndex'] as num?)?.toInt() ??
              _state.currentQuestionIndex,
      roundTopic: response['topic'] as String? ?? _state.roundTopic,
      roundDifficultyPreference:
          _normalizeDifficultyLabel(response['difficulty']) ??
              _state.roundDifficultyPreference,
      silencePromptCount: 0,
    ));
  }
}
