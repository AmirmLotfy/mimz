import 'dart:async';
import '../domain/live_event.dart';

/// Detects speaking/listening turn transitions by combining:
/// - mic activity
/// - server/model events
/// - playback state
///
/// Debounces rapid transitions to avoid UI flicker.
class LiveTurnDetector {
  /// Minimum silence before we consider the user done speaking.
  final Duration silenceThreshold;

  /// Minimum time between state changes to avoid flicker.
  final Duration debounceInterval;

  Timer? _silenceTimer;
  Timer? _debounceTimer;
  DateTime? _lastTransition;

  bool _micActive = false;
  bool _modelSpeaking = false;
  bool _playbackActive = false;

  final _turnController = StreamController<TurnState>.broadcast();
  Stream<TurnState> get turnStream => _turnController.stream;

  TurnState _currentTurn = TurnState.idle;
  TurnState get currentTurn => _currentTurn;

  LiveTurnDetector({
    this.silenceThreshold = const Duration(milliseconds: 800),
    this.debounceInterval = const Duration(milliseconds: 200),
  });

  /// Called when the mic starts/stops receiving audio energy.
  void onMicActivity(bool isActive) {
    _micActive = isActive;

    if (isActive) {
      _silenceTimer?.cancel();
      _transition(TurnState.userSpeaking);
    } else {
      // Wait for silence threshold before transitioning
      _silenceTimer?.cancel();
      _silenceTimer = Timer(silenceThreshold, () {
        if (!_modelSpeaking) {
          _transition(TurnState.idle);
        }
      });
    }
  }

  /// Called when a model turn starts/ends via server events.
  void onModelTurn(bool started) {
    _modelSpeaking = started;

    if (started) {
      _transition(TurnState.modelSpeaking);
    } else if (!_micActive) {
      _transition(TurnState.idle);
    }
  }

  /// Called when playback state changes.
  void onPlaybackState(bool isPlaying) {
    _playbackActive = isPlaying;
    if (!isPlaying && !_micActive && !_modelSpeaking) {
      _transition(TurnState.idle);
    }
  }

  /// Process a live event to detect turn changes.
  void processEvent(LiveEvent event) {
    switch (event) {
      case ModelTurnStarted():
        onModelTurn(true);
      case ModelTurnEnded():
        onModelTurn(false);
      case UserTurnStarted():
        onMicActivity(true);
      case UserTurnEnded():
        onMicActivity(false);
      case InterruptionDetected():
        _transition(TurnState.userSpeaking);
      default:
        break;
    }
  }

  /// Detect if a barge-in should occur.
  bool shouldBargeIn() {
    return _micActive && (_modelSpeaking || _playbackActive);
  }

  void _transition(TurnState newState) {
    if (newState == _currentTurn) return;

    // Debounce rapid transitions
    final now = DateTime.now();
    if (_lastTransition != null &&
        now.difference(_lastTransition!) < debounceInterval) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(debounceInterval, () {
        _applyTransition(newState);
      });
      return;
    }

    _applyTransition(newState);
  }

  void _applyTransition(TurnState newState) {
    _currentTurn = newState;
    _lastTransition = DateTime.now();
    _turnController.add(newState);
  }

  void dispose() {
    _silenceTimer?.cancel();
    _debounceTimer?.cancel();
    _turnController.close();
  }
}

enum TurnState {
  idle,
  userSpeaking,
  modelSpeaking,
}
