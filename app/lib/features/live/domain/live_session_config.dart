import 'live_session_state.dart';

/// Configuration for a specific session type.
///
/// The controller uses this to determine persona, tools, and behavior
/// without branching on mode throughout the codebase.
class LiveSessionConfig {
  final LiveSessionMode mode;
  final String systemInstruction;
  final String voiceName;
  final List<String> responseModalities;
  final Duration tokenTtl;
  final Duration inactivityTimeout;
  final int maxReconnectAttempts;
  final Duration initialReconnectDelay;
  final bool enableCamera;
  final bool enableAudioCapture;
  final Duration maxSessionDuration;
  final int maxFramesPerSession;

  /// Override the session type string sent to the backend (defaults to mode.name).
  final String? sessionTypeOverride;

  /// Event ID for event challenge sessions.
  final String? eventId;

  const LiveSessionConfig({
    required this.mode,
    required this.systemInstruction,
    this.voiceName = 'Aoede',
    // Native-audio live models currently require AUDIO-only setup.
    // Requesting TEXT causes immediate WS close during setup.
    this.responseModalities = const ['AUDIO'],
    this.tokenTtl = const Duration(minutes: 5),
    this.inactivityTimeout = const Duration(minutes: 3),
    this.maxReconnectAttempts = 3,
    this.initialReconnectDelay = const Duration(seconds: 1),
    this.enableCamera = false,
    this.enableAudioCapture = true,
    this.maxSessionDuration = const Duration(minutes: 10),
    this.maxFramesPerSession = 30,
    this.sessionTypeOverride,
    this.eventId,
  });

  // ─── Presets ─────────────────────────────────────

  static const onboarding = LiveSessionConfig(
    mode: LiveSessionMode.onboarding,
    systemInstruction:
        '''You are Mimz, delivering a short welcome after onboarding.
- Give one brief premium welcome to the player's district
- Do not ask profile questions
- Do not collect or save any onboarding data
- End cleanly after the welcome so the player can continue''',
    inactivityTimeout: Duration(minutes: 5),
    enableCamera: false,
    enableAudioCapture: false,
    maxSessionDuration: Duration(minutes: 5),
  );

  static const quiz = LiveSessionConfig(
    mode: LiveSessionMode.quiz,
    systemInstruction:
        '''You are Mimz, an energetic quiz host.
- Call start_live_round, then ask exactly one backend-authored question at a time
- Call grade_answer after each spoken response
- If the player asks for a hint, call request_round_hint
- If the player asks you to repeat, call request_round_repeat
- The backend owns correctness, rewards, streaks, and territory
- After the last question, call end_round
- Keep every turn concise and fast''',
    inactivityTimeout: Duration(minutes: 2),
    enableCamera: false,
    maxSessionDuration: Duration(minutes: 5),
  );

  static const sprint = LiveSessionConfig(
    mode: LiveSessionMode.sprint,
    systemInstruction:
        '''You are Mimz, running a blazing-fast Daily Sprint.
- Call start_live_round in sprint mode
- Ask exactly 3 backend-authored questions with no filler
- Call grade_answer immediately after each answer
- If the player asks for a hint, call request_round_hint
- If the player asks you to repeat, call request_round_repeat
- The backend owns correctness, rewards, streaks, and territory
- After question 3, call end_round''',
    inactivityTimeout: Duration(seconds: 90),
    enableCamera: false,
    maxSessionDuration: Duration(minutes: 3),
    tokenTtl: Duration(minutes: 3),
  );

  static const visionQuest = LiveSessionConfig(
    mode: LiveSessionMode.visionQuest,
    systemInstruction: '''You are Mimz, guiding a visual exploration challenge.
- Call start_vision_quest, then ask the player to show you something specific
- When the player shares an observation, call validate_vision_result
- The backend decides whether the quest counts and what rewards it grants
- Be concise and curious''',
    inactivityTimeout: Duration(minutes: 3),
    enableCamera: true,
    enableAudioCapture: true,
    maxSessionDuration: Duration(minutes: 5),
    maxFramesPerSession: 20,
  );

  static LiveSessionConfig event({
    required String eventId,
    required String eventTitle,
  }) =>
      LiveSessionConfig(
        mode: LiveSessionMode.quiz,
        systemInstruction: 'You are hosting the "$eventTitle" event challenge.',
        inactivityTimeout: const Duration(seconds: 120),
        maxSessionDuration: const Duration(minutes: 5),
        tokenTtl: const Duration(minutes: 5),
        sessionTypeOverride: 'event',
        eventId: eventId,
      );
}
