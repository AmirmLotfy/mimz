/// Connection lifecycle phases for a Gemini Live session.
///
/// These represent the WebSocket connection state, not the conversational state.
/// UI should combine this with [LiveSessionState] for full picture.
enum LiveConnectionPhase {
  /// No session active.
  idle,

  /// Fetching ephemeral token from backend.
  fetchingToken,

  /// WebSocket connection in progress.
  connecting,

  /// WebSocket open, setup message sent, waiting for setupComplete.
  handshaking,

  /// Session is live and ready for interaction.
  connected,

  /// Model is currently generating / streaming a response.
  modelSpeaking,

  /// User mic is active, audio is being streamed.
  userSpeaking,

  /// A tool call was issued; waiting for backend result.
  waitingForToolResult,

  /// Connection lost; attempting reconnect.
  reconnecting,

  /// Session intentionally ended by user or server.
  ended,

  /// Unrecoverable failure.
  failed;

  bool get isActive => this == connected || this == modelSpeaking ||
      this == userSpeaking || this == waitingForToolResult;

  bool get isTerminal => this == ended || this == failed;
}
