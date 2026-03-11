import '../domain/live_event.dart';

/// Maps [LiveError]s to user-facing messages and recovery actions.
///
/// Centralizes all error presentation logic so widgets never interpret
/// error codes directly.
class LiveErrorMapper {
  /// Convert a [LiveError] to a user-friendly message.
  static String userMessage(LiveError error) {
    return switch (error.code) {
      LiveErrorCode.permissionDenied =>
        'Mimz needs access to your microphone to play. Open Settings to grant permission.',
      LiveErrorCode.tokenFetchFailed =>
        'Couldn\'t connect to Mimz servers. Check your connection and try again.',
      LiveErrorCode.tokenExpired =>
        'Your session expired. Starting a fresh connection...',
      LiveErrorCode.wsConnectFailed =>
        'Connection failed. Retrying...',
      LiveErrorCode.wsUnexpectedClose =>
        'Connection dropped. Reconnecting...',
      LiveErrorCode.wsMalformedMessage =>
        'Received an unexpected response. Don\'t worry — continuing.',
      LiveErrorCode.audioCaptureFailed =>
        'Couldn\'t access the microphone. Try closing other audio apps.',
      LiveErrorCode.audioPlaybackFailed =>
        'Audio playback issue. Reconnecting...',
      LiveErrorCode.cameraInitFailed =>
        'Camera isn\'t available right now. Check permissions in Settings.',
      LiveErrorCode.toolExecutionFailed =>
        'Something went wrong in the game. Retrying...',
      LiveErrorCode.backendTimeout =>
        'Server took too long. Retrying...',
      LiveErrorCode.sessionExpired =>
        'Session timed out. Let\'s start a new round!',
      LiveErrorCode.rateLimited =>
        'Too many requests. Wait a moment and try again.',
      LiveErrorCode.unknown =>
        'Something unexpected happened. Try again.',
    };
  }

  /// Whether the error should be shown prominently (banner) or subtly (toast).
  static ErrorSeverity severity(LiveError error) {
    return switch (error.recovery) {
      LiveErrorRecovery.fatal => ErrorSeverity.blocking,
      LiveErrorRecovery.openSettings => ErrorSeverity.blocking,
      LiveErrorRecovery.reconnect => ErrorSeverity.banner,
      LiveErrorRecovery.refreshToken => ErrorSeverity.banner,
      LiveErrorRecovery.retry => ErrorSeverity.transient,
    };
  }

  /// Action label for the recovery button.
  static String? actionLabel(LiveError error) {
    return switch (error.recovery) {
      LiveErrorRecovery.retry => 'Retry',
      LiveErrorRecovery.refreshToken => null, // auto
      LiveErrorRecovery.reconnect => null, // auto
      LiveErrorRecovery.openSettings => 'Open Settings',
      LiveErrorRecovery.fatal => 'End Session',
    };
  }

  /// Internal log payload for debugging.
  static Map<String, dynamic> logPayload(LiveError error) {
    return {
      'code': error.code.name,
      'message': error.message,
      'detail': error.detail,
      'recovery': error.recovery.name,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

enum ErrorSeverity {
  /// Non-blocking, auto-dismissing toast.
  transient,
  /// Visible banner but session continues.
  banner,
  /// Blocks interaction until resolved.
  blocking,
}
