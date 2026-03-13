import 'dart:async';
import '../../../services/gemini_live_client.dart';
import '../../../services/audio_service.dart';
import '../../../services/api_client.dart';

/// @deprecated — Use `features/live/application/live_session_controller.dart` instead.
/// This legacy manager is superseded by `LiveSessionController` which provides
/// layered architecture with proper reconnect, error handling, and turn detection.

/// Manages the full lifecycle of a Gemini Live session:
/// token → connect → audio → tool calls → disconnect
class LiveSessionManager {
  final GeminiLiveClient _gemini;
  final AudioService _audio;
  final ApiClient _apiClient;

  StreamSubscription? _audioSub;
  StreamSubscription? _messageSub;
  StreamSubscription? _toolCallSub;

  final _transcriptController = StreamController<String>.broadcast();
  Stream<String> get transcriptStream => _transcriptController.stream;

  LiveSessionManager({
    required GeminiLiveClient gemini,
    required AudioService audio,
    required ApiClient apiClient,
  })  : _gemini = gemini,
        _audio = audio,
        _apiClient = apiClient;

  /// Start a full live session (quiz, onboarding, etc.)
  Future<void> startSession({String? systemInstruction}) async {
    // 1. Connect to Gemini
    await _gemini.connect(systemInstruction: systemInstruction);

    // 2. Route audio from mic → Gemini
    _audioSub = _audio.audioStream.listen((audioData) {
      _gemini.sendAudio(audioData.toList());
    });

    // 3. Route Gemini audio responses → speaker
    _messageSub = _gemini.messageStream.listen((message) {
      if (message.type == GeminiMessageType.audio && message.audioData != null) {
        _audio.playAudio(message.audioData!, mimeType: message.mimeType ?? 'audio/pcm;rate=24000');
      }
      if (message.type == GeminiMessageType.text && message.text != null) {
        _transcriptController.add(message.text!);
      }
    });

    // 4. Route tool calls → backend → Gemini
    _toolCallSub = _gemini.toolCallStream.listen((toolCall) async {
      final result = await _apiClient.executeToolCall(
        toolName: toolCall.name,
        args: toolCall.args,
        sessionId: _gemini.sessionId ?? '',
      );
      _gemini.sendToolResponse(toolCall.id, result);
    });

    // 5. Start recording
    await _audio.startRecording();
  }

  /// Send a text message (for typed input fallback)
  void sendText(String text) {
    _gemini.sendText(text);
  }

  /// Pause mic
  Future<void> pauseMic() async {
    await _audio.stopRecording();
  }

  /// Resume mic
  Future<void> resumeMic() async {
    await _audio.startRecording();
  }

  /// End the session
  Future<void> endSession() async {
    await _audio.stopRecording();
    await _audio.stopPlayback();
    await _audioSub?.cancel();
    await _messageSub?.cancel();
    await _toolCallSub?.cancel();
    await _gemini.disconnect();
  }

  void dispose() {
    endSession();
    _transcriptController.close();
  }
}
