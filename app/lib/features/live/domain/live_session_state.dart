import 'live_connection_phase.dart';
import 'live_event.dart';

/// The session mode determines which Gemini tools and persona are active.
enum LiveSessionMode {
  onboarding,
  quiz,
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

  // ─── Active tool call ────────────────────────────
  final String? activeToolCallId;
  final String? activeToolName;

  // ─── Media state ─────────────────────────────────
  final bool isMicActive;
  final bool isPlaybackActive;
  final bool isCameraActive;

  // ─── Error ───────────────────────────────────────
  final LiveError? error;
  final int reconnectAttempts;

  // ─── Latest backend-confirmed reward ─────────────
  final Map<String, dynamic>? lastRewardPayload;

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
    this.activeToolCallId,
    this.activeToolName,
    this.isMicActive = false,
    this.isPlaybackActive = false,
    this.isCameraActive = false,
    this.error,
    this.reconnectAttempts = 0,
    this.lastRewardPayload,
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
    String? activeToolCallId,
    String? activeToolName,
    bool? isMicActive,
    bool? isPlaybackActive,
    bool? isCameraActive,
    LiveError? error,
    int? reconnectAttempts,
    Map<String, dynamic>? lastRewardPayload,
    Duration? latency,
    // Allow explicit null clearing
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
      activeToolCallId: clearToolCall ? null : (activeToolCallId ?? this.activeToolCallId),
      activeToolName: clearToolCall ? null : (activeToolName ?? this.activeToolName),
      isMicActive: isMicActive ?? this.isMicActive,
      isPlaybackActive: isPlaybackActive ?? this.isPlaybackActive,
      isCameraActive: isCameraActive ?? this.isCameraActive,
      error: clearError ? null : (error ?? this.error),
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      lastRewardPayload: lastRewardPayload ?? this.lastRewardPayload,
      latency: latency ?? this.latency,
    );
  }
}
