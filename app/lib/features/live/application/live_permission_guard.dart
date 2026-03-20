import '../domain/live_event.dart';
import 'package:permission_handler/permission_handler.dart';

/// Guards all permission checks needed before a live session starts.
///
/// Returns typed [LiveError]s so the controller can handle failures
/// uniformly rather than catching per-permission exceptions.
class LivePermissionGuard {
  /// Check all required permissions for a session.
  /// Returns null if all permissions are granted, or a [LiveError] describing the first failure.
  Future<LiveError?> checkPermissions({
    required bool needsMicrophone,
    required bool needsCamera,
    required bool needsLocation,
  }) async {
    if (needsMicrophone) {
      final mic = await _checkMicrophone();
      if (mic != null) return mic;
    }

    if (needsCamera) {
      final cam = await _checkCamera();
      if (cam != null) return cam;
    }

    if (needsLocation) {
      final loc = await _checkLocation();
      if (loc != null) return loc;
    }

    return null;
  }

  Future<LiveError?> _checkMicrophone() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) return null;
    if (status.isPermanentlyDenied) {
      return const LiveError(
        code: LiveErrorCode.permissionDenied,
        message: 'Voice is core to the experience. Enable microphone in Settings to play live rounds.',
        recovery: LiveErrorRecovery.openSettings,
      );
    }
    return const LiveError(
      code: LiveErrorCode.permissionDenied,
      message: 'Microphone access is needed for live rounds. Tap Allow or open Settings to enable.',
      recovery: LiveErrorRecovery.retry,
    );
  }

  Future<LiveError?> _checkCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) return null;
    if (status.isPermanentlyDenied) {
      return const LiveError(
        code: LiveErrorCode.permissionDenied,
        message: 'Camera permission permanently denied',
        recovery: LiveErrorRecovery.openSettings,
      );
    }
    return const LiveError(
      code: LiveErrorCode.permissionDenied,
      message: 'Camera permission denied',
      recovery: LiveErrorRecovery.retry,
    );
  }

  Future<LiveError?> _checkLocation() async {
    final status = await Permission.location.request();
    if (status.isGranted || status.isLimited) return null;
    if (status.isPermanentlyDenied) {
      return const LiveError(
        code: LiveErrorCode.permissionDenied,
        message: 'Location permission permanently denied',
        recovery: LiveErrorRecovery.openSettings,
      );
    }
    return const LiveError(
      code: LiveErrorCode.permissionDenied,
      message: 'Location permission denied',
      recovery: LiveErrorRecovery.retry,
    );
  }
}
