import 'live_connection_phase.dart';
import 'live_event.dart';

/// The session mode determines which Gemini tools and persona are active.
enum LiveSessionMode {
  onboarding,
  quiz,
  sprint,
  visionQuest,
}

/// Immutable snapshot of the entire live session state.
///
/// The controller is the only writer; UI reads via Riverpod.
class LiveSessionState {
  final LiveConnectionPhase phase;
  final LiveSessionMode mode;
  final String? sessionId;
  final String? correlationId;

  // ─── Transcript ──────────────────────────────────
  final String modelTranscript;
  final String userTranscript;
  final bool isModelTranscriptFinal;
  final bool isUserTranscriptFinal;

  // ─── Current prompt / question ───────────────────
  final String? currentPrompt;
  final String? currentRoundId;
  final String? currentQuestionId;
  final int questionCount;
  final int currentQuestionIndex;
  final String? roundTopic;
  final String? roundDifficultyPreference;

  // ─── Active tool call ────────────────────────────
  final String? activeToolCallId;
  final String? activeToolName;

  // ─── Media state ─────────────────────────────────
  final bool isMicActive;
  final bool isPlaybackActive;
  final bool isCameraActive;

  // ─── Audio amplitude (0.0 – 1.0 RMS) ────────────
  /// Real-time mic amplitude for waveform visualizer.
  /// Updated every PCM chunk (~20ms) when user is speaking.
  final double audioAmplitude;

  // ─── Error ───────────────────────────────────────
  final LiveError? error;
  final int reconnectAttempts;
  final int silencePromptCount;

  // ─── Latest backend-confirmed reward ─────────────
  final Map<String, dynamic>? lastRewardPayload;

  // ─── Cumulative backend-granted totals ──────────────
  final int grantedXp;
  final int grantedSectors;
  final int grantedStone;
  final int grantedGlass;
  final int grantedWood;
  final int grantedComboXp;

  // ─── Round complete signal ────────────────────────
  /// True when the model has called end_round successfully. The UI uses this
  /// to auto-navigate to the result screen after Gemini's farewell audio.
  final bool isRoundComplete;

  // ─── Debug ───────────────────────────────────────
  final Duration? latency;

  const LiveSessionState({
    this.phase = LiveConnectionPhase.idle,
    this.mode = LiveSessionMode.quiz,
    this.sessionId,
    this.correlationId,
    this.modelTranscript = '',
    this.userTranscript = '',
    this.isModelTranscriptFinal = true,
    this.isUserTranscriptFinal = true,
    this.currentPrompt,
    this.currentRoundId,
    this.currentQuestionId,
    this.questionCount = 0,
    this.currentQuestionIndex = 0,
    this.roundTopic,
    this.roundDifficultyPreference,
    this.activeToolCallId,
    this.activeToolName,
    this.isMicActive = false,
    this.isPlaybackActive = false,
    this.isCameraActive = false,
    this.audioAmplitude = 0.0,
    this.error,
    this.reconnectAttempts = 0,
    this.silencePromptCount = 0,
    this.lastRewardPayload,
    this.grantedXp = 0,
    this.grantedSectors = 0,
    this.grantedStone = 0,
    this.grantedGlass = 0,
    this.grantedWood = 0,
    this.grantedComboXp = 0,
    this.isRoundComplete = false,
    this.latency,
  });

  LiveSessionState copyWith({
    LiveConnectionPhase? phase,
    LiveSessionMode? mode,
    String? sessionId,
    String? correlationId,
    String? modelTranscript,
    String? userTranscript,
    bool? isModelTranscriptFinal,
    bool? isUserTranscriptFinal,
    String? currentPrompt,
    String? currentRoundId,
    String? currentQuestionId,
    int? questionCount,
    int? currentQuestionIndex,
    String? roundTopic,
    String? roundDifficultyPreference,
    String? activeToolCallId,
    String? activeToolName,
    bool? isMicActive,
    bool? isPlaybackActive,
    bool? isCameraActive,
    double? audioAmplitude,
    LiveError? error,
    int? reconnectAttempts,
    int? silencePromptCount,
    Map<String, dynamic>? lastRewardPayload,
    int? grantedXp,
    int? grantedSectors,
    int? grantedStone,
    int? grantedGlass,
    int? grantedWood,
    int? grantedComboXp,
    bool? isRoundComplete,
    Duration? latency,
    bool clearError = false,
    bool clearToolCall = false,
    bool clearPrompt = false,
  }) {
    return LiveSessionState(
      phase: phase ?? this.phase,
      mode: mode ?? this.mode,
      sessionId: sessionId ?? this.sessionId,
      correlationId: correlationId ?? this.correlationId,
      modelTranscript: modelTranscript ?? this.modelTranscript,
      userTranscript: userTranscript ?? this.userTranscript,
      isModelTranscriptFinal: isModelTranscriptFinal ?? this.isModelTranscriptFinal,
      isUserTranscriptFinal: isUserTranscriptFinal ?? this.isUserTranscriptFinal,
      currentPrompt: clearPrompt ? null : (currentPrompt ?? this.currentPrompt),
      currentRoundId: currentRoundId ?? this.currentRoundId,
      currentQuestionId: currentQuestionId ?? this.currentQuestionId,
      questionCount: questionCount ?? this.questionCount,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      roundTopic: roundTopic ?? this.roundTopic,
      roundDifficultyPreference:
          roundDifficultyPreference ?? this.roundDifficultyPreference,
      activeToolCallId: clearToolCall ? null : (activeToolCallId ?? this.activeToolCallId),
      activeToolName: clearToolCall ? null : (activeToolName ?? this.activeToolName),
      isMicActive: isMicActive ?? this.isMicActive,
      isPlaybackActive: isPlaybackActive ?? this.isPlaybackActive,
      isCameraActive: isCameraActive ?? this.isCameraActive,
      audioAmplitude: audioAmplitude ?? this.audioAmplitude,
      error: clearError ? null : (error ?? this.error),
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      silencePromptCount: silencePromptCount ?? this.silencePromptCount,
      lastRewardPayload: lastRewardPayload ?? this.lastRewardPayload,
      grantedXp: grantedXp ?? this.grantedXp,
      grantedSectors: grantedSectors ?? this.grantedSectors,
      grantedStone: grantedStone ?? this.grantedStone,
      grantedGlass: grantedGlass ?? this.grantedGlass,
      grantedWood: grantedWood ?? this.grantedWood,
      grantedComboXp: grantedComboXp ?? this.grantedComboXp,
      isRoundComplete: isRoundComplete ?? this.isRoundComplete,
      latency: latency ?? this.latency,
    );
  }
}
