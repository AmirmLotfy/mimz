/// Connection lifecycle phases for a Gemini Live session.
///
/// These represent the WebSocket connection state, not the conversational state.
/// UI should combine this with [LiveSessionState] for full picture.
enum LiveConnectionPhase {
  /// No session active.
  idle,

  /// Booting the live session transport and token.
  connecting,

  /// Connected, waiting for Mimz to deliver the opening prompt.
  waitingForOpeningPrompt,

  /// Model is currently generating / streaming a response.
  modelSpeaking,

  /// The user can answer; mic is actively listening.
  listeningForAnswer,

  /// A backend action is in progress (grading, hint, repeat, difficulty, etc).
  grading,

  /// The round has completed and the result is ready.
  roundComplete,

  /// Connection lost; attempting reconnect.
  reconnecting,

  /// Session intentionally ended by user or server.
  ended,

  /// Unrecoverable failure.
  failed;

  bool get isActive =>
      this == waitingForOpeningPrompt ||
      this == modelSpeaking ||
      this == listeningForAnswer ||
      this == grading ||
      this == roundComplete;

  bool get isTerminal => this == ended || this == failed;
}
