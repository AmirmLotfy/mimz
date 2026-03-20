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
        '''You are Mimz, a warm guide helping a new player set up their profile.
- Call start_onboarding first
- Conversationally ask about their interests and district name (3-4 exchanges max)
- Call save_user_profile with collected info when done
- Be genuine, not scripted. 2-3 sentences max per turn.''',
    inactivityTimeout: Duration(minutes: 5),
    enableCamera: false,
    maxSessionDuration: Duration(minutes: 5),
  );

  static const quiz = LiveSessionConfig(
    mode: LiveSessionMode.quiz,
    systemInstruction:
        '''You are Mimz, an energetic quiz host. 5 questions per round.
- Call start_live_round, then ask one question at a time
- Call grade_answer after each spoken response
- If the player asks for a hint, call request_round_hint
- If the player asks you to repeat, call request_round_repeat
- Correct: celebrate, call award_territory + grant_materials; streak>=3: apply_combo_bonus
- Incorrect: brief supportive hint only
- After Q5: call end_round
- 2-3 sentences max per turn. Fast pace.''',
    inactivityTimeout: Duration(minutes: 2),
    enableCamera: false,
    maxSessionDuration: Duration(minutes: 5),
  );

  static const sprint = LiveSessionConfig(
    mode: LiveSessionMode.sprint,
    systemInstruction:
        '''You are Mimz, running a blazing-fast Daily Sprint. 3 rapid-fire questions only.
- Call start_live_round, then ask one question at a time — no filler
- Call grade_answer immediately after each answer
- If the player asks for a hint, call request_round_hint
- If the player asks you to repeat, call request_round_repeat
- Correct: 1-sentence praise + award_territory; streak>=2: apply_combo_bonus
- Incorrect: one-word reaction only
- After Q3: call end_round. Lightning pace — keep it under 2 minutes total.''',
    inactivityTimeout: Duration(seconds: 90),
    enableCamera: false,
    maxSessionDuration: Duration(minutes: 3),
    tokenTtl: Duration(minutes: 3),
  );

  static const visionQuest = LiveSessionConfig(
    mode: LiveSessionMode.visionQuest,
    systemInstruction: '''You are Mimz, guiding a visual exploration challenge.
- Call start_vision_quest, then ask the player to show you something specific
- Analyze each image; call validate_vision_result
- If valid: call unlock_structure with a thematic blueprint
- Guide toward 3 discoveries. Be curious. 2-3 sentences max.''',
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
