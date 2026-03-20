import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../domain/live_event.dart';

int _callIdSeq = 0;
String _nextCallId() => 'call_${++_callIdSeq}';

/// Encodes outgoing messages and decodes incoming Gemini Live API messages
/// into typed [LiveEvent]s.
///
/// This is the ONLY place that touches raw WebSocket JSON. Nothing else in
/// the app should parse or build protocol messages directly.
class LiveMessageCodec {
  // ─── Outgoing messages ──────────────────────────

  /// Build the initial setup message sent after WebSocket connect.
  ///
  /// Uses snake_case field names as required by the Vertex AI Live API
  /// (google.cloud.aiplatform.v1.LlmBidiService/BidiGenerateContent).
  String encodeSetup({
    required String model,
    required String systemInstruction,
    required String voiceName,
    required List<String> responseModalities,
    required List<Map<String, dynamic>> tools,
  }) {
    // Vertex AI returns full resource path (projects/.../models/...); API-key mode uses short name.
    final modelPath = model.startsWith('projects/') ? model : 'models/$model';

    // Flatten all functionDeclarations from all tool objects into one list,
    // normalising both camelCase (functionDeclarations) and snake_case keys.
    final functionDecls = <Map<String, dynamic>>[];
    for (final tool in tools) {
      final decls = (tool['functionDeclarations'] ?? tool['function_declarations']) as List?;
      if (decls != null) {
        for (final d in decls) {
          functionDecls.add(Map<String, dynamic>.from(d as Map));
        }
      }
    }

    final setup = <String, dynamic>{
      'model': modelPath,
      // Vertex AI Live API uses snake_case for all setup fields.
      'generation_config': {
        'response_modalities': responseModalities,
        'speech_config': {
          'voice_config': {
            'prebuilt_voice_config': {
              'voice_name': voiceName,
            },
          },
        },
      },
      'system_instruction': {
        'parts': [
          {'text': systemInstruction},
        ],
      },
      // ─── VAD configuration ─────────────────────────────
      // HIGH start sensitivity: detects the beginning of speech quickly so the
      // model registers even short answers.
      // LOW end sensitivity: doesn't cut the user off mid-sentence during pauses.
      // START_OF_ACTIVITY_INTERRUPTS: user speech immediately stops model playback
      // (barge-in). TURN_INCLUDES_ONLY_ACTIVITY: the model only responds to
      // voiced content, not background noise / silence.
      'realtime_input_config': {
        'automatic_activity_detection': {
          'disabled': false,
          'start_of_speech_sensitivity': 'START_SENSITIVITY_HIGH',
          'end_of_speech_sensitivity': 'END_SENSITIVITY_LOW',
          'prefix_padding_ms': 100,
          'silence_duration_ms': 800,
        },
        'activity_handling': 'START_OF_ACTIVITY_INTERRUPTS',
        'turn_coverage': 'TURN_INCLUDES_ONLY_ACTIVITY',
      },
      // ─── Transcription ─────────────────────────────────
      // Enables server-side ASR so we receive text transcripts of what the
      // user says AND what the model says. Used to populate the UI transcript.
      'input_audio_transcription': {},
      'output_audio_transcription': {},
      // ─── Context window compression ────────────────────
      // Native audio consumes ~25 tokens/second. A 5-minute session burns
      // ~7,500 tokens of audio alone. Compression slides the window when
      // context exceeds 15k tokens, targeting a 10k token budget.
      'context_window_compression': {
        'sliding_window': {
          'target_tokens': 10000,
        },
        'trigger_tokens': 15000,
      },
      // ─── Session resumption ────────────────────────────
      // Sessions have a ~10-minute connection lifetime. Session resumption
      // allows reconnects to continue the same session instead of starting
      // fresh, saving system prompt + tool re-send tokens.
      'session_resumption': <String, dynamic>{},
    };

    if (functionDecls.isNotEmpty) {
      setup['tools'] = [
        {'function_declarations': functionDecls},
      ];
    }

    return jsonEncode({'setup': setup});
  }

  /// Encode a PCM audio chunk for streaming to the model.
  ///
  /// Uses snake_case realtime_input / media_chunks to match Vertex AI Live API.
  /// Input format: 16-bit PCM, 16kHz, little-endian (as required by the API).
  String encodeAudioChunk(Uint8List pcmData, {String mimeType = 'audio/pcm;rate=16000'}) {
    return jsonEncode({
      'realtime_input': {
        'media_chunks': [
          {
            'mime_type': mimeType,
            'data': base64Encode(pcmData),
          },
        ],
      },
    });
  }

  /// Encode a camera frame for vision input.
  String encodeImageFrame(Uint8List jpegData) {
    return jsonEncode({
      'realtime_input': {
        'media_chunks': [
          {
            'mime_type': 'image/jpeg',
            'data': base64Encode(jpegData),
          },
        ],
      },
    });
  }

  /// Encode a kickstart signal.
  ///
  /// Sends an empty client_content with turn_complete: true. This satisfies
  /// the native audio model's requirement for a user turn before it begins
  /// speaking unprompted.
  String encodeKickstart() {
    return jsonEncode({
      'client_content': {
        'turn_complete': true,
      },
    });
  }

  /// Encode a text message from the user.
  String encodeText(String text) {
    return jsonEncode({
      'client_content': {
        'turns': [
          {
            'role': 'user',
            'parts': [
              {'text': text},
            ],
          },
        ],
        'turn_complete': true,
      },
    });
  }

  /// Encode a tool response back to Gemini.
  ///
  /// Vertex AI Live API function_responses only accepts `name` and `response` —
  /// the `id` field is NOT part of the schema and causes a 1007 close if sent.
  String encodeToolResponse(String callId, String toolName, Map<String, dynamic> result) {
    return jsonEncode({
      'tool_response': {
        'function_responses': [
          {
            'name': toolName,
            'response': result,
          },
        ],
      },
    });
  }

  // ─── Incoming message parsing ───────────────────

  /// Look up a key supporting both camelCase and snake_case variants.
  static dynamic _get(Map<String, dynamic> m, String camelKey, [String? snakeKey]) {
    return m[camelKey] ?? (snakeKey != null ? m[snakeKey] : null);
  }

  /// Parse a raw WebSocket message into zero or more [LiveEvent]s.
  ///
  /// Handles both camelCase and snake_case response keys, as Vertex AI Live API
  /// (v1) uses snake_case while Google AI Live API uses camelCase.
  /// Handles both text and binary WebSocket frames.
  List<LiveEvent> decode(dynamic rawMessage) {
    final events = <LiveEvent>[];
    final isBinaryFrame = rawMessage is List<int>;

    try {
      // Vertex AI Live API may send binary WebSocket frames.
      // Convert bytes → UTF-8 string before JSON parsing.
      final String rawString;
      if (rawMessage is String) {
        rawString = rawMessage;
      } else if (rawMessage is List<int>) {
        rawString = utf8.decode(rawMessage);
      } else {
        // Unknown type — skip silently.
        return events;
      }

      // Empty frames (heartbeats) — ignore.
      if (rawString.trim().isEmpty) return events;

      if (kDebugMode) {
        // Log raw messages truncated to 500 chars; tool calls logged in full.
        final isTool = rawString.contains('"toolCall"') || rawString.contains('"tool_call"');
        final limit = isTool ? rawString.length : 500;
        debugPrint('[Mimz][WS] raw(${rawString.length}): ${rawString.substring(0, rawString.length.clamp(0, limit))}');
      }

      final data = jsonDecode(rawString) as Map<String, dynamic>;

      // Server error (e.g. invalid key, model not found) — fail fast, avoid reconnect loop
      if (data.containsKey('error')) {
        events.add(SessionError(_parseServerError(data['error'])));
        return events;
      }

      // Server will disconnect soon — treat as fatal so we don't blindly reconnect
      final goAway = data['goAway'] ?? data['go_away'];
      if (goAway != null) {
        events.add(SessionError(LiveError(
          code: LiveErrorCode.sessionExpired,
          message: 'Session ended by server',
          detail: 'Server sent goAway',
          recovery: LiveErrorRecovery.fatal,
        )));
        return events;
      }

      // Setup complete — accepts both camelCase and snake_case
      final setupComplete = data['setupComplete'] ?? data['setup_complete'];
      if (setupComplete != null) {
        final sessionId = setupComplete is Map<String, dynamic>
            ? (setupComplete['sessionId'] ?? setupComplete['session_id']) as String?
            : null;
        events.add(SessionStarted(
          sessionId ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
        ));
        return events;
      }

      // Server content (model speaking)
      final serverContent = (data['serverContent'] ?? data['server_content']) as Map<String, dynamic>?;
      if (serverContent != null) {
        _parseServerContent(serverContent, events);
      }

      // Tool call
      final toolCall = (data['toolCall'] ?? data['tool_call']) as Map<String, dynamic>?;
      if (toolCall != null) {
        _parseToolCall(toolCall, events);
      }

      // Tool call cancellation — sent by server when user barges in during a tool call
      final toolCallCancellation =
          (data['toolCallCancellation'] ?? data['tool_call_cancellation']) as Map<String, dynamic>?;
      if (toolCallCancellation != null) {
        final ids = ((toolCallCancellation['ids']) as List?)
                ?.cast<String>() ??
            [];
        events.add(ToolCallCancelled(cancelledIds: ids));
      }

      // Interruption signal
      final interrupted = data['interrupted'];
      if (interrupted == true) {
        events.add(const InterruptionDetected());
      }

    } catch (e) {
      // Binary frames are frequently used for non-JSON payloads / heartbeats.
      // Treat them as ignorable transport noise rather than a user-visible
      // connection failure (which can otherwise flicker in a loop).
      if (isBinaryFrame) {
        if (kDebugMode) {
          debugPrint('[Mimz][WS] ignoring binary frame parse failure: $e');
        }
        return events;
      }

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
    final modelTurn = (_get(content, 'modelTurn', 'model_turn')) as Map<String, dynamic>?;
    final turnComplete = (_get(content, 'turnComplete', 'turn_complete')) == true;

    if (modelTurn != null) {
      events.add(const ModelTurnStarted());

      final parts = (modelTurn['parts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final part in parts) {
        // Text content (model transcript when TEXT modality is enabled)
        if (part.containsKey('text')) {
          final text = part['text'] as String;
          events.add(TranscriptDelta(text: text, isModel: true));
        }

        // Audio content — handles both inlineData and inline_data
        final inlineData = (part['inlineData'] ?? part['inline_data']) as Map<String, dynamic>?;
        if (inlineData != null) {
          final audioBytes = base64Decode(inlineData['data'] as String);
          final mimeType = (inlineData['mimeType'] ?? inlineData['mime_type']) as String?
              ?? 'audio/pcm;rate=24000';
          events.add(AudioChunkReceived(data: audioBytes, mimeType: mimeType));
        }
      }
    }

    // Output audio transcription — server ASR of what the model said
    // Delivered in outputTranscription.text (camelCase) or output_transcription.text
    final outputTranscription =
        (_get(content, 'outputTranscription', 'output_transcription')) as Map<String, dynamic>?;
    if (outputTranscription != null) {
      final text = outputTranscription['text'] as String?;
      if (text != null && text.isNotEmpty) {
        events.add(TranscriptDelta(text: text, isModel: true));
      }
    }

    // Input audio transcription — server ASR of what the user said
    // Delivered in inputTranscription.text
    final inputTranscription =
        (_get(content, 'inputTranscription', 'input_transcription')) as Map<String, dynamic>?;
    if (inputTranscription != null) {
      final text = inputTranscription['text'] as String?;
      if (text != null && text.isNotEmpty) {
        events.add(TranscriptDelta(text: text, isModel: false));
      }
    }

    if (turnComplete) {
      events.add(const ModelTurnEnded());
    }
  }

  void _parseToolCall(Map<String, dynamic> toolCall, List<LiveEvent> events) {
    final functionCalls =
        ((_get(toolCall, 'functionCalls', 'function_calls')) as List?)
            ?.cast<Map<String, dynamic>>() ?? [];
    for (final call in functionCalls) {
      // Vertex AI Live API may omit the `id` field for non-parallel calls.
      // Generate a stable sequential ID so the tool response always has a
      // matching identifier.
      final rawId = call['id'] as String?;
      final callId = (rawId != null && rawId.isNotEmpty) ? rawId : _nextCallId();
      if (kDebugMode && rawId == null) {
        debugPrint('[Mimz][WS] toolCall missing id — assigned $callId for ${call['name']}');
      }
      events.add(ToolCallRequested(
        callId: callId,
        toolName: call['name'] as String? ?? 'unknown',
        arguments: call['args'] as Map<String, dynamic>? ?? {},
      ));
    }
  }

  /// Parse Gemini-style error (e.g. invalid API key, model not found). Use fatal
  /// recovery so we don't reconnect in a loop on config/auth errors.
  LiveError _parseServerError(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final message = raw['message'] as String? ?? raw['status'] as String? ?? 'Server returned an error';
      final code = raw['code'] as int?;
      final detail = raw['details'] ?? raw['detail'];
      final detailStr = detail is String ? detail : (detail is List && detail.isNotEmpty ? detail.first.toString() : null);
      // Permission/model/config errors should not trigger reconnect
      final isConfigError = code != null && (code == 3 || code == 7 || code == 16 || code == 401 || code == 403);
      return LiveError(
        code: isConfigError ? LiveErrorCode.permissionDenied : LiveErrorCode.wsUnexpectedClose,
        message: message,
        detail: detailStr ?? (code != null ? 'Code: $code' : null),
        recovery: isConfigError ? LiveErrorRecovery.fatal : LiveErrorRecovery.retry,
      );
    }
    return LiveError(
      code: LiveErrorCode.wsMalformedMessage,
      message: 'Server error',
      detail: raw?.toString(),
      recovery: LiveErrorRecovery.fatal,
    );
  }
}
