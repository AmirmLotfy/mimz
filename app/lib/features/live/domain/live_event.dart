/// Typed domain events emitted by the live session layer.
///
/// These are the normalized events that the controller and UI consume.
/// Raw WebSocket messages must never leak past the codec layer.
sealed class LiveEvent {
  const LiveEvent();
}

// ─── Connection lifecycle ─────────────────────────────────

class SessionStarted extends LiveEvent {
  final String sessionId;
  const SessionStarted(this.sessionId);
}

class SessionClosed extends LiveEvent {
  final int? closeCode;
  final String? reason;
  const SessionClosed({this.closeCode, this.reason});
}

class SessionWarning extends LiveEvent {
  final String message;
  const SessionWarning(this.message);
}

class SessionError extends LiveEvent {
  final LiveError error;
  const SessionError(this.error);
}

// ─── Turn lifecycle ───────────────────────────────────────

class ModelTurnStarted extends LiveEvent {
  const ModelTurnStarted();
}

class ModelTurnEnded extends LiveEvent {
  const ModelTurnEnded();
}

class UserTurnStarted extends LiveEvent {
  const UserTurnStarted();
}

class UserTurnEnded extends LiveEvent {
  const UserTurnEnded();
}

// ─── Content ──────────────────────────────────────────────

class TranscriptDelta extends LiveEvent {
  final String text;
  final bool isModel;
  const TranscriptDelta({required this.text, required this.isModel});
}

class TranscriptFinal extends LiveEvent {
  final String text;
  final bool isModel;
  const TranscriptFinal({required this.text, required this.isModel});
}

class AudioChunkReceived extends LiveEvent {
  final List<int> data;
  final String mimeType;
  const AudioChunkReceived({required this.data, required this.mimeType});
}

// ─── Tool calls ───────────────────────────────────────────

class ToolCallRequested extends LiveEvent {
  final String callId;
  final String toolName;
  final Map<String, dynamic> arguments;
  const ToolCallRequested({
    required this.callId,
    required this.toolName,
    required this.arguments,
  });
}

class ToolCallCompleted extends LiveEvent {
  final String callId;
  final String toolName;
  final Map<String, dynamic> result;
  final bool success;
  const ToolCallCompleted({
    required this.callId,
    required this.toolName,
    required this.result,
    required this.success,
  });
}

// ─── Vision ───────────────────────────────────────────────

class VisionInputRequested extends LiveEvent {
  final String prompt;
  const VisionInputRequested({required this.prompt});
}

// ─── Interruption ─────────────────────────────────────────

class InterruptionDetected extends LiveEvent {
  const InterruptionDetected();
}

// ─── Error domain model ───────────────────────────────────

class LiveError {
  final LiveErrorCode code;
  final String message;
  final String? detail;
  final LiveErrorRecovery recovery;

  const LiveError({
    required this.code,
    required this.message,
    this.detail,
    required this.recovery,
  });

  @override
  String toString() => 'LiveError($code: $message)';
}

enum LiveErrorCode {
  permissionDenied,
  tokenFetchFailed,
  tokenExpired,
  wsConnectFailed,
  wsUnexpectedClose,
  wsMalformedMessage,
  audioCaptureFailed,
  audioPlaybackFailed,
  cameraInitFailed,
  toolExecutionFailed,
  backendTimeout,
  sessionExpired,
  rateLimited,
  unknown,
}

enum LiveErrorRecovery {
  /// User can retry the action.
  retry,
  /// Need to fetch a new token first.
  refreshToken,
  /// Need to fully reconnect.
  reconnect,
  /// Need to open system settings.
  openSettings,
  /// Unrecoverable — end session.
  fatal,
}
