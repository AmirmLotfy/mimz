import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

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

  /// Fires if setupComplete is not received from server within handshake window.
  static const _handshakeTimeout = Duration(seconds: 18);
  Timer? _handshakeTimer;

  LiveSessionController({
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
    LiveMockAdapter? mockAdapter,
    this.useMock = false,
    this.authPreconditionError,
  })  : _ws = ws,
        _tokenClient = tokenClient,
        _toolBridge = toolBridge,
        _audioCapture = audioCapture,
        _audioPlayback = audioPlayback,
        _camera = camera,
        _permissions = permissions ?? LivePermissionGuard(),
        _turnDetector = turnDetector ?? LiveTurnDetector(),
        _reconnectPolicy = reconnectPolicy ?? LiveReconnectPolicy(),
        _logger = logger ?? LiveSessionLogger(),
        _mockAdapter = mockAdapter;

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
    if (!_state.phase.isActive) return;
    _logger.log('barge_in_requested');

    // Stop playback immediately
    await _audioPlayback.stopImmediately();

    // Resume mic capture
    if (!_audioCapture.isCapturing) {
      await _audioCapture.startCapture();
    }

    _emitState(_state.copyWith(
      phase: LiveConnectionPhase.userSpeaking,
      isPlaybackActive: false,
      isMicActive: true,
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
    if (_state.mode != LiveSessionMode.visionQuest || !_state.phase.isActive)
      return;
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
  void requestRepeat() {
    if (!_isCommandAllowed()) return;
    if (_repeatCount >= maxRepeatsPerRound) {
      _logger.log('repeat_capped', metadata: {'count': _repeatCount});
      return;
    }
    sendTextFallback('Please repeat the current question exactly.');
  }

  /// Request a hint from the model.
  void requestHint() {
    if (!_isCommandAllowed()) return;
    if (_hintCount >= maxHintsPerRound) {
      _logger.log('hint_capped', metadata: {'count': _hintCount});
      return;
    }
    sendTextFallback('Please give me a hint for the current question.');
  }

  /// Request difficulty change.
  void requestDifficultyChange({bool harder = false}) {
    if (!_isCommandAllowed()) return;
    sendTextFallback(harder ? 'Make it harder.' : 'Can you make it easier?');
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
    _activeConfig = config;
    if (resetReconnectPolicy) {
      _reconnectPolicy.reset();
    }
    _hintCount = 0;
    _repeatCount = 0;
    _lastCommandTime = DateTime(2000);

    // Enforce max session duration
    _sessionDurationTimer?.cancel();
    _sessionDurationTimer = Timer(config.maxSessionDuration, () {
      _logger.log('session_duration_cap_reached');
      endSession();
    });
    final correlationId = 'live_${DateTime.now().millisecondsSinceEpoch}';

    _emitState(LiveSessionState(
      mode: config.mode,
      phase: LiveConnectionPhase.idle,
      correlationId: correlationId,
      reconnectAttempts: _reconnectPolicy.attempts,
    ));

    // Use mock adapter in dev mode
    if (useMock && _mockAdapter != null) {
      return _startMockSession(config);
    }

    // 0. Auth/bootstrap precondition — block start with actionable message if invalid
    final preconditionError = authPreconditionError?.call();
    if (preconditionError != null && preconditionError.isNotEmpty) {
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
    _emitState(_state.copyWith(phase: LiveConnectionPhase.idle));
    final permError = await _permissions.checkPermissions(
      needsMicrophone: config.enableAudioCapture,
      needsCamera: config.enableCamera,
      needsLocation: false,
    );
    if (permError != null) {
      _emitState(_state.copyWith(
        phase: LiveConnectionPhase.failed,
        error: permError,
      ));
      return;
    }

    // 2. Fetch token
    _emitState(_state.copyWith(phase: LiveConnectionPhase.fetchingToken));
    _logger.log('fetching_token', metadata: {'correlationId': correlationId});

    try {
      final token = await _tokenClient.fetchToken(
        sessionType: config.sessionTypeOverride ?? config.mode.name,
        correlationId: correlationId,
        eventId: config.eventId,
      );

      // 3. Connect WebSocket
      _emitState(_state.copyWith(phase: LiveConnectionPhase.connecting));
      _logger.log('connecting_ws', metadata: {
        'correlationId': correlationId,
        'model': token.model,
      });

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
      _emitState(_state.copyWith(phase: LiveConnectionPhase.handshaking));
      if (token.sessionId != null && token.sessionId!.isNotEmpty) {
        // Keep backend-issued session id for tool execution authorization.
        _emitState(_state.copyWith(sessionId: token.sessionId));
      }

      _ws.setInactivityTimeout(config.inactivityTimeout);

      // If server never sends setupComplete, fail after handshake timeout
      _handshakeTimer?.cancel();
      _handshakeTimer = Timer(_handshakeTimeout, () {
        if (_state.phase == LiveConnectionPhase.connecting ||
            _state.phase == LiveConnectionPhase.handshaking) {
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
      _logger.log('startup_live_error', metadata: {
        'correlationId': _state.correlationId,
        'code': e.code.name,
      });
      _emitState(_state.copyWith(
        phase: LiveConnectionPhase.failed,
        error: e,
      ));
    } catch (e) {
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
      _emitState(_state.copyWith(isPlaybackActive: playing));
    });

    // Turn detector → state
    _turnSub = _turnDetector.turnStream.listen((turn) {
      switch (turn) {
        case TurnState.userSpeaking:
          _emitState(_state.copyWith(phase: LiveConnectionPhase.userSpeaking));
        case TurnState.modelSpeaking:
          _emitState(_state.copyWith(phase: LiveConnectionPhase.modelSpeaking));
        case TurnState.idle:
          if (_state.phase == LiveConnectionPhase.userSpeaking ||
              _state.phase == LiveConnectionPhase.modelSpeaking) {
            _emitState(_state.copyWith(phase: LiveConnectionPhase.connected));
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
        _emitState(_state.copyWith(
          phase: LiveConnectionPhase.modelSpeaking,
          modelTranscript: '',
          isModelTranscriptFinal: false,
        ));
      case ModelTurnEnded():
        // Don't reset phase if we're waiting for a tool result — the model
        // sends turnComplete immediately after a tool call, but the tool is
        // still being executed. The phase will be reset by _handleToolCall.
        if (_state.phase != LiveConnectionPhase.waitingForToolResult) {
          _emitState(_state.copyWith(
            phase: LiveConnectionPhase.connected,
            isModelTranscriptFinal: true,
          ));
        }
      case TranscriptDelta(text: final t, isModel: final m):
        if (m) {
          _emitState(_state.copyWith(
            modelTranscript: _state.modelTranscript + t,
          ));
        } else {
          _emitState(_state.copyWith(userTranscript: t));
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
          ));
        }
      case AudioChunkReceived(data: final d, mimeType: final m):
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
        _emitState(_state.copyWith(
          phase: LiveConnectionPhase.connected,
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
    _emitState(_state.copyWith(
      phase: LiveConnectionPhase.connected,
      // Prefer backend-minted session id; websocket session id can differ by transport.
      sessionId: _state.sessionId ?? sessionId,
      clearError: true,
    ));

    // Start mic capture
    if (_activeConfig?.enableAudioCapture == true) {
      _audioCapture.startCapture();
      _emitState(_state.copyWith(isMicActive: true));
    }

    // Start camera if vision quest
    if (_activeConfig?.enableCamera == true) {
      _camera.initialize().then((_) {
        _camera.startPeriodicCapture();
        _emitState(_state.copyWith(isCameraActive: true));
      });
    }

    _logger.log('session_ready', metadata: {'sessionId': sessionId});

    // The native audio model requires a user turn to begin generating.
    // Send an empty kickstart turn so Gemini starts its opening response
    // (e.g. calling start_live_round) immediately after setup.
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
      phase: LiveConnectionPhase.waitingForToolResult,
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
        clearPrompt = true;
        currentQuestionId = null;
      }

      _emitState(_state.copyWith(
        phase: LiveConnectionPhase.connected,
        currentRoundId: currentRoundId,
        currentQuestionId: currentQuestionId,
        currentPrompt: currentPrompt,
        questionCount: questionCount,
        currentQuestionIndex: currentQuestionIndex,
        roundTopic: roundTopic,
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
        phase: LiveConnectionPhase.connected,
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
    _handshakeTimer = null;
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
    _stateController.add(newState);
  }

  Map<String, dynamic>? _mapFromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map)
      return value.map((key, dynamicValue) => MapEntry('$key', dynamicValue));
    return null;
  }

  String? _promptFromQuestion(Map<String, dynamic> question) {
    return question['spokenPhrase'] as String? ?? question['text'] as String?;
  }
}
