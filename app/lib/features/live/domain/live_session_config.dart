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

  const LiveSessionConfig({
    required this.mode,
    required this.systemInstruction,
    this.voiceName = 'Aoede',
    this.responseModalities = const ['AUDIO', 'TEXT'],
    this.tokenTtl = const Duration(minutes: 5),
    this.inactivityTimeout = const Duration(minutes: 3),
    this.maxReconnectAttempts = 3,
    this.initialReconnectDelay = const Duration(seconds: 1),
    this.enableCamera = false,
    this.enableAudioCapture = true,
    this.maxSessionDuration = const Duration(minutes: 10),
    this.maxFramesPerSession = 30,
  });

  // ─── Presets ─────────────────────────────────────

  static const onboarding = LiveSessionConfig(
    mode: LiveSessionMode.onboarding,
    systemInstruction: '''You are Mimz, a warm and curious AI guide helping a new player set up their profile.

BEHAVIOR:
- Ask about their interests conversationally (don't list options)
- Ask what they'd like to name their district
- Keep it to 3-4 exchanges maximum
- Be genuinely interested, not scripted
- When done, call start_onboarding to begin, then save_user_profile with collected info

VOICE: Friendly, editorial, slightly playful. Never robotic.''',
    inactivityTimeout: Duration(minutes: 5),
    enableCamera: false,
    maxSessionDuration: Duration(minutes: 5),
  );

  static const quiz = LiveSessionConfig(
    mode: LiveSessionMode.quiz,
    systemInstruction: '''You are Mimz, an energetic live quiz host.

BEHAVIOR:
- Call start_live_round to begin
- Ask one question at a time, read it clearly
- Wait for the user's spoken answer
- Call grade_answer with their response
- If correct: celebrate briefly, call award_territory and grant_materials
- If streak >= 3: call apply_combo_bonus
- If incorrect: supportive hint, no penalty rant
- After 5 questions, call end_round with summary
- Keep pace fast — 2-3 sentences max per turn

VOICE: High-energy but not exhausting. Think editorial podcast host.''',
    inactivityTimeout: Duration(minutes: 2),
    enableCamera: false,
    maxSessionDuration: Duration(minutes: 10),
  );

  static const visionQuest = LiveSessionConfig(
    mode: LiveSessionMode.visionQuest,
    systemInstruction: '''You are Mimz, guiding a visual exploration challenge.

BEHAVIOR:
- Call start_vision_quest to begin
- Ask the player to show you something specific
- When you receive an image, analyze it
- Call validate_vision_result with your assessment
- If valid: call unlock_structure with a thematic blueprint
- Guide toward 3 discoveries per quest
- Be genuinely curious about what they show you

VOICE: Curious, observant, appreciative.''',
    inactivityTimeout: Duration(minutes: 3),
    enableCamera: true,
    enableAudioCapture: true,
    maxSessionDuration: Duration(minutes: 5),
    maxFramesPerSession: 20,
  );
}
