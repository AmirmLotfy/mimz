import 'dart:async';
import 'dart:typed_data';
import '../domain/live_event.dart';
// import 'package:camera/camera.dart';
// import 'package:image/image.dart' as img;

/// Camera streaming service for Vision Quests.
///
/// Supports two modes:
/// - **One-shot**: Capture a single frame for analysis
/// - **Periodic**: Stream frames at controlled intervals
///
/// Frame throttling and encoding are isolated here — consumers just
/// receive ready-to-send JPEG bytes.
class LiveCameraStreamService {
  // CameraController? _controller;
  Timer? _periodicTimer;
  bool _isActive = false;
  bool _isDisposed = false;

  /// Minimum interval between periodic frame captures.
  final Duration frameInterval;

  /// JPEG quality (0-100) for frame compression.
  final int jpegQuality;

  /// Max dimension for downscaling (preserves aspect ratio).
  final int maxDimension;

  final _frameController = StreamController<Uint8List>.broadcast();

  LiveCameraStreamService({
    this.frameInterval = const Duration(seconds: 2),
    this.jpegQuality = 70,
    this.maxDimension = 640,
  });

  bool get isActive => _isActive;
  Stream<Uint8List> get frameStream => _frameController.stream;

  /// Initialize the camera.
  Future<void> initialize() async {
    try {
      // final cameras = await availableCameras();
      // if (cameras.isEmpty) throw Exception('No cameras available');
      //
      // _controller = CameraController(
      //   cameras.first,
      //   ResolutionPreset.medium,
      //   enableAudio: false,
      //   imageFormatGroup: ImageFormatGroup.jpeg,
      // );
      // await _controller!.initialize();
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
      // final file = await _controller!.takePicture();
      // final bytes = await file.readAsBytes();
      // return _processFrame(bytes);
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Start periodic frame capture.
  void startPeriodicCapture() {
    if (_isActive || _isDisposed) return;
    _isActive = true;

    _periodicTimer = Timer.periodic(frameInterval, (_) async {
      final frame = await captureOneShot();
      if (frame != null && !_isDisposed) {
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

  /// Process a raw camera frame: downscale + compress to JPEG.
  Uint8List _processFrame(Uint8List rawBytes) {
    // Real implementation with image package:
    // final decoded = img.decodeImage(rawBytes);
    // if (decoded == null) return rawBytes;
    //
    // // Downscale if needed
    // img.Image resized = decoded;
    // if (decoded.width > maxDimension || decoded.height > maxDimension) {
    //   resized = img.copyResize(decoded,
    //     width: decoded.width > decoded.height ? maxDimension : null,
    //     height: decoded.height >= decoded.width ? maxDimension : null,
    //   );
    // }
    //
    // return Uint8List.fromList(img.encodeJpg(resized, quality: jpegQuality));
    return rawBytes;
  }

  /// Release camera resources.
  void dispose() {
    _isDisposed = true;
    stopPeriodicCapture();
    _frameController.close();
    // _controller?.dispose();
  }
}
