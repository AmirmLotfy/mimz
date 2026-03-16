import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';

/// Abstract interface for audio playback.
abstract class AudioPlaybackService {
  bool get isPlaying;
  Stream<bool> get playbackStateStream;

  /// Queue a chunk of raw PCM 16-bit 24kHz mono audio.
  void enqueue(Uint8List audioData, String mimeType);

  /// Stop playback immediately (for barge-in).
  Future<void> stopImmediately();

  /// Flush the queue without playing remaining chunks.
  void flushQueue();

  /// Release all resources.
  void dispose();
}

/// Plays raw PCM data in memory by prepending a WAV header and piping to just_audio.
class LiveAudioPlaybackService implements AudioPlaybackService {
  final AudioPlayer _player = AudioPlayer();

  final _queue = Queue<_AudioChunk>();
  bool _isPlaying = false;
  bool _isDisposed = false;
  final _stateController = StreamController<bool>.broadcast();

  @override
  bool get isPlaying => _isPlaying;

  @override
  Stream<bool> get playbackStateStream => _stateController.stream;

  @override
  void enqueue(Uint8List audioData, String mimeType) {
    if (_isDisposed) return;
    _queue.add(_AudioChunk(data: audioData, mimeType: mimeType));
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isPlaying || _queue.isEmpty || _isDisposed) return;

    _isPlaying = true;
    _stateController.add(true);

    while (_queue.isNotEmpty && !_isDisposed) {
      final chunk = _queue.removeFirst();

      try {
        // Gemini outputs 24kHz 16-bit mono PCM.
        final wavData = _addWavHeader(chunk.data, 24000);
        final source = _MemoryAudioSource(wavData);
        
        await _player.setAudioSource(source);
        await _player.play();
        
        // Wait until this specific chunk is finished playing
        if (_player.playing) {
          await _player.playerStateStream.firstWhere(
            (state) => state.processingState == ProcessingState.completed || !_isPlaying,
          );
        }
      } catch (e) {
        // Ignore playback errors from interrupted chunks
      }
    }

    _isPlaying = false;
    if (!_isDisposed) _stateController.add(false);
  }

  @override
  Future<void> stopImmediately() async {
    _queue.clear();
    _isPlaying = false;
    await _player.stop();
    if (!_isDisposed) _stateController.add(false);
  }

  @override
  void flushQueue() {
    _queue.clear();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _queue.clear();
    _isPlaying = false;
    _stateController.close();
    _player.dispose();
  }

  /// Adds a standard WAV header to raw PCM 16-bit data.
  Uint8List _addWavHeader(Uint8List pcmBytes, int sampleRate) {
    const channels = 1;
    final byteRate = sampleRate * channels * 2;
    
    final header = ByteData(44);
    header.setUint8(0, 82); header.setUint8(1, 73); header.setUint8(2, 70); header.setUint8(3, 70); // "RIFF"
    header.setUint32(4, 36 + pcmBytes.length, Endian.little);
    header.setUint8(8, 87); header.setUint8(9, 65); header.setUint8(10, 86); header.setUint8(11, 69); // "WAVE"
    header.setUint8(12, 102); header.setUint8(13, 109); header.setUint8(14, 116); header.setUint8(15, 32); // "fmt "
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little); // Format = PCM
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, channels * 2, Endian.little); // Block align
    header.setUint16(34, 16, Endian.little); // Bits per sample
    header.setUint8(36, 100); header.setUint8(37, 97); header.setUint8(38, 116); header.setUint8(39, 97); // "data"
    header.setUint32(40, pcmBytes.length, Endian.little);

    final builder = BytesBuilder();
    builder.add(header.buffer.asUint8List());
    builder.add(pcmBytes);
    return builder.toBytes();
  }
}

class _AudioChunk {
  final Uint8List data;
  final String mimeType;
  const _AudioChunk({required this.data, required this.mimeType});
}

class _MemoryAudioSource extends StreamAudioSource {
  final Uint8List _buffer;
  
  _MemoryAudioSource(this._buffer);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _buffer.length;
    return StreamAudioResponse(
      sourceLength: _buffer.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_buffer.sublist(start, end)),
      contentType: 'audio/wav',
    );
  }
}
