import 'dart:async';
import 'dart:typed_data';
import '../domain/live_event.dart';

/// Mock adapter that replays canned event sequences for local development
/// without requiring a real Gemini API key or backend.
///
/// Use feature flags to switch between real and mock implementations.
class LiveMockAdapter {
  final _eventController = StreamController<LiveEvent>.broadcast();
  Stream<LiveEvent> get events => _eventController.stream;

  bool _isActive = false;
  Timer? _replayTimer;

  /// Simulate a quiz session with canned events.
  Future<void> replayQuizSession() async {
    _isActive = true;
    final events = _quizSessionFixture();
    var index = 0;

    _replayTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (index >= events.length || !_isActive) {
        timer.cancel();
        return;
      }
      _eventController.add(events[index]);
      index++;
    });
  }

  /// Simulate an onboarding session.
  Future<void> replayOnboardingSession() async {
    _isActive = true;
    final events = _onboardingSessionFixture();
    var index = 0;

    _replayTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (index >= events.length || !_isActive) {
        timer.cancel();
        return;
      }
      _eventController.add(events[index]);
      index++;
    });
  }

  void stop() {
    _isActive = false;
    _replayTimer?.cancel();
  }

  void dispose() {
    stop();
    _eventController.close();
  }

  // ─── Fixtures ───────────────────────────────────

  List<LiveEvent> _quizSessionFixture() => [
    const SessionStarted('mock_session_001'),
    const ModelTurnStarted(),
    const TranscriptDelta(text: 'Welcome to Mimz Quiz! ', isModel: true),
    const TranscriptDelta(text: 'Let\'s test your knowledge. ', isModel: true),
    AudioChunkReceived(data: Uint8List(640).toList(), mimeType: 'audio/pcm;rate=24000'),
    const ModelTurnEnded(),
    const ToolCallRequested(
      callId: 'tc_001',
      toolName: 'start_live_round',
      arguments: {'topic': 'Geography', 'difficulty': 'medium'},
    ),
    const ToolCallCompleted(
      callId: 'tc_001',
      toolName: 'start_live_round',
      result: {'roundId': 'round_001', 'topic': 'Geography'},
      success: true,
    ),
    const ModelTurnStarted(),
    const TranscriptDelta(
      text: 'Question 1: What is the largest continent by area?',
      isModel: true,
    ),
    const ModelTurnEnded(),
    // Simulate user answering
    const UserTurnStarted(),
    const TranscriptDelta(text: 'Asia', isModel: false),
    const UserTurnEnded(),
    const ToolCallRequested(
      callId: 'tc_002',
      toolName: 'grade_answer',
      arguments: {'answer': 'Asia', 'correct': true},
    ),
    const ToolCallCompleted(
      callId: 'tc_002',
      toolName: 'grade_answer',
      result: {'correct': true, 'score': 100},
      success: true,
    ),
    const ModelTurnStarted(),
    const TranscriptDelta(text: 'That\'s correct! 🎉 Asia it is!', isModel: true),
    const ModelTurnEnded(),
  ];

  List<LiveEvent> _onboardingSessionFixture() => [
    const SessionStarted('mock_onboard_001'),
    const ModelTurnStarted(),
    const TranscriptDelta(
      text: 'Hey there! Welcome to Mimz. I\'m going to help you set up your world. What topics interest you most?',
      isModel: true,
    ),
    const ModelTurnEnded(),
    const UserTurnStarted(),
    const TranscriptDelta(text: 'I love science and technology', isModel: false),
    const UserTurnEnded(),
    const ModelTurnStarted(),
    const TranscriptDelta(
      text: 'Great taste! Science and tech it is. Now, what would you like to name your district?',
      isModel: true,
    ),
    const ModelTurnEnded(),
  ];
}
