import 'dart:convert';
import 'dart:typed_data';
import '../domain/live_event.dart';

/// Encodes outgoing messages and decodes incoming Gemini Live API messages
/// into typed [LiveEvent]s.
///
/// This is the ONLY place that touches raw WebSocket JSON. Nothing else in
/// the app should parse or build protocol messages directly.
class LiveMessageCodec {
  // ─── Outgoing messages ──────────────────────────

  /// Build the initial setup message sent after WebSocket connect.
  String encodeSetup({
    required String model,
    required String systemInstruction,
    required String voiceName,
    required List<String> responseModalities,
    required List<Map<String, dynamic>> tools,
  }) {
    return jsonEncode({
      'setup': {
        'model': 'models/$model',
        'generationConfig': {
          'responseModalities': responseModalities,
          'speechConfig': {
            'voiceConfig': {
              'prebuiltVoiceConfig': {
                'voiceName': voiceName,
              },
            },
          },
        },
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction},
          ],
        },
        'tools': tools,
      },
    });
  }

  /// Encode a PCM audio chunk for streaming to the model.
  String encodeAudioChunk(Uint8List pcmData, {String mimeType = 'audio/pcm;rate=16000'}) {
    return jsonEncode({
      'realtimeInput': {
        'mediaChunks': [
          {
            'mimeType': mimeType,
            'data': base64Encode(pcmData),
          },
        ],
      },
    });
  }

  /// Encode a camera frame for vision input.
  String encodeImageFrame(Uint8List jpegData) {
    return jsonEncode({
      'realtimeInput': {
        'mediaChunks': [
          {
            'mimeType': 'image/jpeg',
            'data': base64Encode(jpegData),
          },
        ],
      },
    });
  }

  /// Encode a text message from the user.
  String encodeText(String text) {
    return jsonEncode({
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
    });
  }

  /// Encode a tool response back to Gemini.
  String encodeToolResponse(String callId, String toolName, Map<String, dynamic> result) {
    return jsonEncode({
      'toolResponse': {
        'functionResponses': [
          {
            'id': callId,
            'name': toolName,
            'response': result,
          },
        ],
      },
    });
  }

  // ─── Incoming message parsing ───────────────────

  /// Parse a raw WebSocket message into zero or more [LiveEvent]s.
  ///
  /// A single server message can produce multiple events (e.g., text + audio
  /// in the same modelTurn). Returns empty list for unrecognizable messages.
  List<LiveEvent> decode(dynamic rawMessage) {
    final events = <LiveEvent>[];

    try {
      final data = jsonDecode(rawMessage as String) as Map<String, dynamic>;

      // Setup complete
      if (data.containsKey('setupComplete')) {
        final sessionId = _extractString(data, 'setupComplete', 'sessionId') ?? 'session_${DateTime.now().millisecondsSinceEpoch}';
        events.add(SessionStarted(sessionId));
        return events;
      }

      // Server content (model speaking)
      if (data.containsKey('serverContent')) {
        _parseServerContent(data['serverContent'] as Map<String, dynamic>, events);
      }

      // Tool call
      if (data.containsKey('toolCall')) {
        _parseToolCall(data['toolCall'] as Map<String, dynamic>, events);
      }

      // Interruption signal
      if (data.containsKey('interrupted') && data['interrupted'] == true) {
        events.add(const InterruptionDetected());
      }

    } catch (e) {
      events.add(SessionError(LiveError(
        code: LiveErrorCode.wsMalformedMessage,
        message: 'Failed to parse server message',
        detail: e.toString(),
        recovery: LiveErrorRecovery.retry,
      )));
    }

    return events;
  }

  void _parseServerContent(Map<String, dynamic> content, List<LiveEvent> events) {
    final modelTurn = content['modelTurn'] as Map<String, dynamic>?;
    final turnComplete = content['turnComplete'] == true;

    if (modelTurn != null) {
      events.add(const ModelTurnStarted());

      final parts = (modelTurn['parts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final part in parts) {
        // Text content
        if (part.containsKey('text')) {
          final text = part['text'] as String;
          events.add(TranscriptDelta(text: text, isModel: true));
        }

        // Audio content
        if (part.containsKey('inlineData')) {
          final inlineData = part['inlineData'] as Map<String, dynamic>;
          final audioBytes = base64Decode(inlineData['data'] as String);
          final mimeType = inlineData['mimeType'] as String? ?? 'audio/pcm;rate=24000';
          events.add(AudioChunkReceived(data: audioBytes, mimeType: mimeType));
        }
      }
    }

    if (turnComplete) {
      events.add(const ModelTurnEnded());
    }
  }

  void _parseToolCall(Map<String, dynamic> toolCall, List<LiveEvent> events) {
    final functionCalls = (toolCall['functionCalls'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (final call in functionCalls) {
      events.add(ToolCallRequested(
        callId: call['id'] as String? ?? 'unknown',
        toolName: call['name'] as String? ?? 'unknown',
        arguments: call['args'] as Map<String, dynamic>? ?? {},
      ));
    }
  }

  String? _extractString(Map<String, dynamic> data, String key, String field) {
    final value = data[key];
    if (value is Map<String, dynamic>) {
      return value[field] as String?;
    }
    return null;
  }
}
