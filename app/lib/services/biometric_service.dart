import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Manages biometric authentication: availability, enrollment check,
/// preference persistence, and authentication gate.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: _androidOptions,
  );


  static const _kBiometricsEnabled = 'biometrics_enabled';

  // ─── Availability ─────────────────────────────────

  /// Whether biometrics are supported on this device.
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Whether biometrics are enrolled (fingerprints/face registered).
  Future<bool> isEnrolled() async {
    try {
      final available = await isAvailable();
      if (!available) return false;
      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Available biometric types (fingerprint, face, iris).
  Future<List<BiometricType>> availableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  // ─── Preference ───────────────────────────────────

  /// Whether the user has enabled biometrics for app lock.
  Future<bool> isEnabled() async {
    final val = await _storage.read(key: _kBiometricsEnabled);
    return val == 'true';
  }

  /// Enable biometric lock.
  Future<void> enable() async {
    await _storage.write(key: _kBiometricsEnabled, value: 'true');
  }

  /// Disable biometric lock.
  Future<void> disable() async {
    await _storage.write(key: _kBiometricsEnabled, value: 'false');
  }

  // ─── Authentication ───────────────────────────────

  /// Authenticate the user with biometrics or device PIN.
  ///
  /// Returns `true` if authenticated, `false` otherwise.
  /// Never throws — gracefully handles all failure modes.
  Future<bool> authenticate({
    String reason = 'Confirm your identity to access Mimz.',
  }) async {
    try {
      final available = await isAvailable();
      if (!available) return true; // Device doesn't support — allow through

      final enrolled = await isEnrolled();
      if (!enrolled) return true; // Not enrolled — allow through gracefully

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // Allow fallback to PIN/pattern
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return true; // Fail open — don't lock the user out on unexpected errors
    }
  }

  /// Should we gate app resume with biometrics?
  Future<bool> shouldGateOnResume() async {
    final enabled = await isEnabled();
    if (!enabled) return false;
    return isEnrolled();
  }
}
