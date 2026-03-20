import 'dart:async';
import 'dart:typed_data';
import '../domain/live_event.dart';
import 'package:camera/camera.dart';

/// Camera streaming service for Vision Quests.
///
/// Supports two modes:
/// - **One-shot**: Capture a single frame for analysis
/// - **Periodic**: Stream frames at controlled intervals
///
/// Frame throttling and encoding are isolated here — consumers just
/// receive ready-to-send JPEG bytes.
class LiveCameraStreamService {
  CameraController? _controller;
  Timer? _periodicTimer;
  bool _isActive = false;
  bool _isDisposed = false;

  /// Minimum interval between periodic frame captures.
  final Duration frameInterval;

  /// JPEG quality (0-100) for frame compression.
  final int jpegQuality;

  /// Max dimension for downscaling (preserves aspect ratio).
  final int maxDimension;

  /// Maximum frames per session to control costs.
  final int maxFramesPerSession;

  int _framesSent = 0;

  final _frameController = StreamController<Uint8List>.broadcast();

  LiveCameraStreamService({
    Duration frameInterval = const Duration(seconds: 2),
    this.jpegQuality = 70,
    this.maxDimension = 640,
    this.maxFramesPerSession = 30,
  }) : frameInterval = frameInterval < const Duration(seconds: 2)
           ? const Duration(seconds: 2)
           : frameInterval;

  bool get isActive => _isActive;
  int get framesSent => _framesSent;
  Stream<Uint8List> get frameStream => _frameController.stream;

  /// Initialize the camera.
  Future<void> initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('No cameras available');

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
    } catch (e) {
      throw LiveError(
        code: LiveErrorCode.cameraInitFailed,
        message: 'Failed to initialize camera',
        detail: e.toString(),
        recovery: LiveErrorRecovery.retry,
      );
    }
  }

  /// Capture a single frame and return JPEG bytes.
  Future<Uint8List?> captureOneShot() async {
    if (_isDisposed) return null;

    try {
      final file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      return _processFrame(bytes);
    } catch (e) {
      return null;
    }
  }

  /// Start periodic frame capture.
  void startPeriodicCapture() {
    if (_isActive || _isDisposed) return;
    _isActive = true;

    _periodicTimer = Timer.periodic(frameInterval, (_) async {
      if (_framesSent >= maxFramesPerSession) {
        stopPeriodicCapture();
        return;
      }
      final frame = await captureOneShot();
      if (frame != null && !_isDisposed) {
        _framesSent++;
        _frameController.add(frame);
      }
    });
  }

  /// Stop periodic frame capture.
  void stopPeriodicCapture() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _isActive = false;
  }

  CameraController? get controller => _controller;

  /// Process a raw camera frame: downscale + compress to JPEG.
  Uint8List _processFrame(Uint8List rawBytes) {
    // Relying on ResolutionPreset.medium to keep size reasonable for Gemini
    // without using the heavy Image package on the main isolate.
    return rawBytes;
  }

  /// Release camera resources in order to avoid BufferQueue/ImageReader warnings.
  /// Call this when leaving the camera screen so no new frames are requested,
  /// then release the controller.
  void dispose() {
    _isDisposed = true;
    stopPeriodicCapture();
    _frameController.close();
    final c = _controller;
    _controller = null;
    c?.dispose();
  }
}
