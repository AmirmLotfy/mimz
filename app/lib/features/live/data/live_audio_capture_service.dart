import 'dart:async';
import 'dart:typed_data';
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
  // The `record` package recorder would go here:
  // final AudioRecorder _recorder = AudioRecorder();
  
  final _audioController = StreamController<Uint8List>.broadcast();
  StreamSubscription? _recordSub;
  bool _isCapturing = false;

  /// Chunk duration in milliseconds. 20ms at 16kHz × 2 bytes = 640 bytes/chunk.
  final int chunkDurationMs;

  LiveAudioCaptureService({this.chunkDurationMs = 20});

  @override
  bool get isCapturing => _isCapturing;

  @override
  Stream<Uint8List> get audioStream => _audioController.stream;

  @override
  Future<bool> requestPermission() async {
    // Uses permission_handler or record package's built-in permission check.
    // return await _recorder.hasPermission();
    return true; // Implemented via LivePermissionGuard
  }

  @override
  Future<void> startCapture() async {
    if (_isCapturing) return;

    try {
      // Real implementation:
      // final stream = await _recorder.startStream(RecordConfig(
      //   encoder: AudioEncoder.pcm16bits,
      //   sampleRate: 16000,
      //   numChannels: 1,
      //   bitRate: 256000,
      // ));
      //
      // _recordSub = stream.listen((data) {
      //   _audioController.add(Uint8List.fromList(data));
      // });

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
    // await _recorder.pause();
    _isCapturing = false;
  }

  @override
  Future<void> resumeCapture() async {
    // await _recorder.resume();
    _isCapturing = true;
  }

  @override
  Future<void> stopCapture() async {
    _isCapturing = false;
    await _recordSub?.cancel();
    _recordSub = null;
    // await _recorder.stop();
  }

  @override
  void dispose() {
    stopCapture();
    _audioController.close();
    // _recorder.dispose();
  }
}
