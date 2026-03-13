import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_client.dart';

enum LiveSessionState { disconnected, connecting, connected, listening, speaking, error }

/// @deprecated — Use `features/live/data/live_websocket_client.dart` +
/// `features/live/application/live_session_controller.dart` instead.
/// This legacy client is superseded by the layered live architecture.
/// Retained temporarily for backward-compatible Riverpod providers.

/// Manages a Gemini Live API session via WebSocket
class GeminiLiveClient {
  final ApiClient _apiClient;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final _stateController = StreamController<LiveSessionState>.broadcast();
  Stream<LiveSessionState> get stateStream => _stateController.stream;

  final _messageController = StreamController<GeminiMessage>.broadcast();
  Stream<GeminiMessage> get messageStream => _messageController.stream;

  final _toolCallController = StreamController<GeminiToolCall>.broadcast();
  Stream<GeminiToolCall> get toolCallStream => _toolCallController.stream;

  LiveSessionState _state = LiveSessionState.disconnected;
  LiveSessionState get state => _state;

  String? _sessionId;
  String? get sessionId => _sessionId;

  GeminiLiveClient({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Start a new live session
  Future<void> connect({String? systemInstruction}) async {
    _setState(LiveSessionState.connecting);

    try {
      // 1. Get ephemeral token from backend
      final tokenResponse = await _apiClient.getEphemeralToken();
      final session = tokenResponse['session'] as Map<String, dynamic>;
      final token = session['token'] as String;
      final model = session['model'] as String;

      _sessionId = token;

      // 2. Connect to Gemini Live WebSocket
      // TODO: Replace with actual Gemini Live endpoint
      final wsUrl = Uri.parse(
        'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent'
        '?key=$token',
      );

      _channel = WebSocketChannel.connect(wsUrl);

      // 3. Send setup message
      final setupMessage = {
        'setup': {
          'model': 'models/$model',
          'generationConfig': {
            'responseModalities': ['AUDIO', 'TEXT'],
            'speechConfig': {
              'voiceConfig': {
                'prebuiltVoiceConfig': {
                  'voiceName': 'Aoede',
                },
              },
            },
          },
          'systemInstruction': {
            'parts': [
              {
                'text': systemInstruction ??
                    'You are Mimz, a friendly and energetic AI game host. '
                        'You guide players through live trivia quizzes, vision quests, and exploration challenges. '
                        'Keep responses concise, enthusiastic, and encouraging. '
                        'When a player answers correctly, celebrate briefly. '
                        'When wrong, be supportive and give a quick hint.',
              },
            ],
          },
          'tools': session['tools'] ?? [],
        },
      };

      _channel!.sink.add(jsonEncode(setupMessage));

      // 4. Listen for responses
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );

      _setState(LiveSessionState.connected);
    } catch (e) {
      _setState(LiveSessionState.error);
      rethrow;
    }
  }

  /// Send audio data (PCM bytes)
  void sendAudio(List<int> audioBytes) {
    if (_state != LiveSessionState.connected &&
        _state != LiveSessionState.listening) {
      return;
    }

    final message = {
      'realtimeInput': {
        'mediaChunks': [
          {
            'mimeType': 'audio/pcm;rate=16000',
            'data': base64Encode(audioBytes),
          },
        ],
      },
    };

    _channel?.sink.add(jsonEncode(message));
    _setState(LiveSessionState.listening);
  }

  /// Send image data (JPEG bytes)
  void sendImage(Uint8List imageBytes) {
    if (_state != LiveSessionState.connected &&
        _state != LiveSessionState.listening) {
      return;
    }

    final message = {
      'realtimeInput': {
        'mediaChunks': [
          {
            'mimeType': 'image/jpeg',
            'data': base64Encode(imageBytes),
          },
        ],
      },
    };

    _channel?.sink.add(jsonEncode(message));
    _setState(LiveSessionState.listening);
  }

  /// Send text message
  void sendText(String text) {
    if (_state != LiveSessionState.connected &&
        _state != LiveSessionState.listening) {
      return;
    }

    final message = {
      'clientContent': {
        'turns': [
          {
            'role': 'user',
            'parts': [
              {'text': text},
            ],
          },
        ],
        'turnComplete': true,
      },
    };

    _channel?.sink.add(jsonEncode(message));
  }

  /// Send tool response back to Gemini
  void sendToolResponse(String functionCallId, Map<String, dynamic> result) {
    final message = {
      'toolResponse': {
        'functionResponses': [
          {
            'id': functionCallId,
            'name': result['toolName'],
            'response': result,
          },
        ],
      },
    };

    _channel?.sink.add(jsonEncode(message));
  }

  /// Disconnect the session
  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _sessionId = null;
    _setState(LiveSessionState.disconnected);
  }

  void _handleMessage(dynamic rawMessage) {
    try {
      final data = jsonDecode(rawMessage as String) as Map<String, dynamic>;

      // Check for setup complete
      if (data.containsKey('setupComplete')) {
        _setState(LiveSessionState.connected);
        return;
      }

      // Check for server content (AI response)
      if (data.containsKey('serverContent')) {
        final content = data['serverContent'] as Map<String, dynamic>;
        final parts = (content['modelTurn']?['parts'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        for (final part in parts) {
          if (part.containsKey('text')) {
            _messageController.add(GeminiMessage(
              type: GeminiMessageType.text,
              text: part['text'] as String,
            ));
          }
          if (part.containsKey('inlineData')) {
            final inlineData = part['inlineData'] as Map<String, dynamic>;
            _messageController.add(GeminiMessage(
              type: GeminiMessageType.audio,
              audioData: base64Decode(inlineData['data'] as String),
              mimeType: inlineData['mimeType'] as String?,
            ));
            _setState(LiveSessionState.speaking);
          }
        }

        // Check if turn is complete
        if (content['turnComplete'] == true) {
          _setState(LiveSessionState.connected);
        }
      }

      // Check for tool calls
      if (data.containsKey('toolCall')) {
        final toolCall = data['toolCall'] as Map<String, dynamic>;
        final functionCalls = (toolCall['functionCalls'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        for (final call in functionCalls) {
          _toolCallController.add(GeminiToolCall(
            id: call['id'] as String,
            name: call['name'] as String,
            args: call['args'] as Map<String, dynamic>? ?? {},
          ));
        }
      }
    } catch (e) {
      // Malformed message — log but don't crash
    }
  }

  void _handleError(dynamic error) {
    _setState(LiveSessionState.error);
  }

  void _handleDone() {
    _setState(LiveSessionState.disconnected);
  }

  void _setState(LiveSessionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  void dispose() {
    disconnect();
    _stateController.close();
    _messageController.close();
    _toolCallController.close();
  }
}

enum GeminiMessageType { text, audio }

class GeminiMessage {
  final GeminiMessageType type;
  final String? text;
  final List<int>? audioData;
  final String? mimeType;

  GeminiMessage({required this.type, this.text, this.audioData, this.mimeType});
}

class GeminiToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> args;

  GeminiToolCall({required this.id, required this.name, required this.args});
}
