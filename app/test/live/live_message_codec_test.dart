import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mimz/features/live/data/live_message_codec.dart';
import 'package:mimz/features/live/domain/live_event.dart';

void main() {
  late LiveMessageCodec codec;

  setUp(() {
    codec = LiveMessageCodec();
  });

  group('LiveMessageCodec - Encoding', () {
    test('encodeSetup produces valid JSON with correct structure', () {
      final msg = codec.encodeSetup(
        model: 'gemini-2.0-flash-live-001',
        systemInstruction: 'You are Mimz.',
        voiceName: 'Aoede',
        responseModalities: ['AUDIO', 'TEXT'],
        tools: [],
      );

      final parsed = jsonDecode(msg) as Map<String, dynamic>;
      expect(parsed.containsKey('setup'), isTrue);
      expect(parsed['setup']['model'], 'models/gemini-2.0-flash-live-001');
      expect(parsed['setup']['systemInstruction']['parts'][0]['text'], 'You are Mimz.');
    });

    test('encodeAudioChunk base64-encodes PCM data', () {
      final pcm = Uint8List.fromList([0, 1, 2, 3, 4, 5]);
      final msg = codec.encodeAudioChunk(pcm);
      final parsed = jsonDecode(msg) as Map<String, dynamic>;

      expect(parsed['realtimeInput']['mediaChunks'][0]['mimeType'], 'audio/pcm;rate=16000');
      final encoded = parsed['realtimeInput']['mediaChunks'][0]['data'] as String;
      expect(base64Decode(encoded), equals(pcm));
    });

    test('encodeText produces clientContent with turnComplete', () {
      final msg = codec.encodeText('Hello Mimz');
      final parsed = jsonDecode(msg) as Map<String, dynamic>;

      expect(parsed['clientContent']['turnComplete'], isTrue);
      expect(parsed['clientContent']['turns'][0]['parts'][0]['text'], 'Hello Mimz');
    });

    test('encodeToolResponse includes callId and name', () {
      final msg = codec.encodeToolResponse('tc_001', 'grade_answer', {'correct': true});
      final parsed = jsonDecode(msg) as Map<String, dynamic>;

      expect(parsed['toolResponse']['functionResponses'][0]['id'], 'tc_001');
      expect(parsed['toolResponse']['functionResponses'][0]['name'], 'grade_answer');
    });
  });

  group('LiveMessageCodec - Decoding', () {
    test('decodes setupComplete into SessionStarted', () {
      final raw = jsonEncode({'setupComplete': {}});
      final events = codec.decode(raw);

      expect(events.length, 1);
      expect(events.first, isA<SessionStarted>());
    });

    test('decodes serverContent with text into TranscriptDelta + ModelTurnStarted', () {
      final raw = jsonEncode({
        'serverContent': {
          'modelTurn': {
            'parts': [
              {'text': 'Hello player!'},
            ],
          },
        },
      });
      final events = codec.decode(raw);

      expect(events.any((e) => e is ModelTurnStarted), isTrue);
      expect(events.whereType<TranscriptDelta>().first.text, 'Hello player!');
    });

    test('decodes serverContent with audio into AudioChunkReceived', () {
      final audioData = base64Encode([0, 1, 2, 3]);
      final raw = jsonEncode({
        'serverContent': {
          'modelTurn': {
            'parts': [
              {
                'inlineData': {
                  'mimeType': 'audio/pcm;rate=24000',
                  'data': audioData,
                },
              },
            ],
          },
        },
      });
      final events = codec.decode(raw);

      final audioEvent = events.whereType<AudioChunkReceived>().first;
      expect(audioEvent.data, equals([0, 1, 2, 3]));
      expect(audioEvent.mimeType, 'audio/pcm;rate=24000');
    });

    test('decodes turnComplete into ModelTurnEnded', () {
      final raw = jsonEncode({
        'serverContent': {'turnComplete': true},
      });
      final events = codec.decode(raw);

      expect(events.any((e) => e is ModelTurnEnded), isTrue);
    });

    test('decodes toolCall into ToolCallRequested', () {
      final raw = jsonEncode({
        'toolCall': {
          'functionCalls': [
            {
              'id': 'tc_001',
              'name': 'grade_answer',
              'args': {'answer': 'Asia'},
            },
          ],
        },
      });
      final events = codec.decode(raw);

      final toolEvent = events.whereType<ToolCallRequested>().first;
      expect(toolEvent.callId, 'tc_001');
      expect(toolEvent.toolName, 'grade_answer');
      expect(toolEvent.arguments['answer'], 'Asia');
    });

    test('handles malformed JSON gracefully', () {
      final events = codec.decode('not json at all');
      expect(events.any((e) => e is SessionError), isTrue);
    });
  });
}
