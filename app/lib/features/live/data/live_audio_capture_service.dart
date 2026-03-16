import 'dart:async';
import 'dart:typed_data';
import 'package:record/record.dart';
import '../domain/live_event.dart';

/// Abstract interface for audio capture.
///
/// Hides the specific recording package behind an interface so
/// the implementation can be swapped without touching the rest of the stack.
abstract class AudioCaptureService {
  /// Whether the mic is currently capturing.
  bool get isCapturing;

  /// Stream of PCM audio chunks. Each chunk is raw PCM 16-bit LE @ 16kHz mono.
  Stream<Uint8List> get audioStream;

  /// Real-time amplitude (0.0–1.0 RMS). Emits once per audio chunk (~20ms).
  Stream<double> get amplitudeStream;

  /// Request microphone permission.
  Future<bool> requestPermission();

  /// Start capturing audio from the microphone.
  Future<void> startCapture();

  /// Pause capture (keeps resources allocated).
  Future<void> pauseCapture();

  /// Resume a paused capture.
  Future<void> resumeCapture();

  /// Stop capture and release resources.
  Future<void> stopCapture();

  /// Release all resources.
  void dispose();
}

/// Production implementation using the `record` package.
class LiveAudioCaptureService implements AudioCaptureService {
  final AudioRecorder _recorder = AudioRecorder();
  final _audioController = StreamController<Uint8List>.broadcast();
  final _amplitudeController = StreamController<double>.broadcast();

  StreamSubscription<Uint8List>? _recordSub;
  bool _isCapturing = false;

  /// Chunk duration in milliseconds. 20ms at 16kHz × 2 bytes = 640 bytes/chunk.
  final int chunkDurationMs;

  LiveAudioCaptureService({this.chunkDurationMs = 20});

  @override
  bool get isCapturing => _isCapturing;

  @override
  Stream<Uint8List> get audioStream => _audioController.stream;

  @override
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  @override
  Future<bool> requestPermission() async {
    return await _recorder.hasPermission();
  }

  @override
  Future<void> startCapture() async {
    if (_isCapturing) return;

    try {
      if (!await _recorder.hasPermission()) {
        throw const LiveError(
          code: LiveErrorCode.audioCaptureFailed,
          message: 'Microphone permission denied',
          recovery: LiveErrorRecovery.fatal,
        );
      }

      final stream = await _recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ));

      _recordSub = stream.listen((data) {
        _audioController.add(data);
        // Compute RMS amplitude of this PCM chunk for the waveform visualizer.
        // PCM is 16-bit signed little-endian: 2 bytes per sample.
        if (data.length >= 2) {
          double sumSquares = 0;
          final samples = data.length ~/ 2;
          for (int i = 0; i < data.length - 1; i += 2) {
            // Interpret 2 bytes as a signed 16-bit integer
            final int raw = data[i] | (data[i + 1] << 8);
            final int signed = raw >= 0x8000 ? raw - 0x10000 : raw;
            final double normalized = signed / 32768.0;
            sumSquares += normalized * normalized;
          }
          final rms = (sumSquares / samples > 0)
              ? (sumSquares / samples).clamp(0.0, 1.0)
              : 0.0;
          _amplitudeController.add(rms.toDouble());
        }
      });

      _isCapturing = true;
    } catch (e) {
      throw LiveError(
        code: LiveErrorCode.audioCaptureFailed,
        message: 'Failed to start microphone',
        detail: e.toString(),
        recovery: LiveErrorRecovery.retry,
      );
    }
  }

  @override
  Future<void> pauseCapture() async {
    if (!_isCapturing) return;
    await _recorder.pause();
    _isCapturing = false;
  }

  @override
  Future<void> resumeCapture() async {
    await _recorder.resume();
    _isCapturing = true;
  }

  @override
  Future<void> stopCapture() async {
    _isCapturing = false;
    await _recordSub?.cancel();
    _recordSub = null;
    await _recorder.stop();
  }

  @override
  void dispose() {
    stopCapture();
    _audioController.close();
    _amplitudeController.close();
    _recorder.dispose();
  }
}
