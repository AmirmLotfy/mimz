import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists user preferences securely.
///
/// All toggles (notifications, haptic, sound, location sharing) are read
/// and written to `flutter_secure_storage` so they survive app restarts.
class SettingsService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _kNotifications   = 'pref_notifications_enabled';
  static const _kHaptic          = 'pref_haptic_enabled';
  static const _kSound           = 'pref_sound_enabled';
  static const _kLocationSharing = 'pref_location_sharing';

  // ─── Notifications ────────────────────────────────
  Future<bool> getNotifications() async =>
      await _readBool(_kNotifications, defaultValue: true);
  Future<void> setNotifications(bool v) => _writeBool(_kNotifications, v);

  // ─── Haptic ───────────────────────────────────────
  Future<bool> getHaptic() async =>
      await _readBool(_kHaptic, defaultValue: true);
  Future<void> setHaptic(bool v) => _writeBool(_kHaptic, v);

  // ─── Sound ────────────────────────────────────────
  Future<bool> getSound() async =>
      await _readBool(_kSound, defaultValue: true);
  Future<void> setSound(bool v) => _writeBool(_kSound, v);

  // ─── Location Sharing ─────────────────────────────
  Future<bool> getLocationSharing() async =>
      await _readBool(_kLocationSharing, defaultValue: true);
  Future<void> setLocationSharing(bool v) => _writeBool(_kLocationSharing, v);

  // ─── Helpers ──────────────────────────────────────
  Future<bool> _readBool(String key, {required bool defaultValue}) async {
    final val = await _storage.read(key: key);
    if (val == null) return defaultValue;
    return val == 'true';
  }

  Future<void> _writeBool(String key, bool v) async {
    await _storage.write(key: key, value: v.toString());
  }

  Future<void> resetAll() async {
    await _storage.delete(key: _kNotifications);
    await _storage.delete(key: _kHaptic);
    await _storage.delete(key: _kSound);
    await _storage.delete(key: _kLocationSharing);
  }
}
