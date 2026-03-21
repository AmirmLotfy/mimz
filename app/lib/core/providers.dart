import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../services/gemini_live_client.dart';
import '../../services/audio_service.dart';
import '../../services/location_service.dart';
import '../../services/settings_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/telemetry_service.dart';

/// ─── Singleton Service Providers ────────────────────────

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final authServiceProvider = Provider<AuthService>((ref) {
  final service = AuthService();
  ref.onDispose(() => service.dispose());
  return service;
});

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService();
  ref.onDispose(() => service.dispose());
  return service;
});

final geminiLiveClientProvider = Provider<GeminiLiveClient>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final client = GeminiLiveClient(apiClient: apiClient);
  ref.onDispose(() => client.dispose());
  return client;
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

final telemetryServiceProvider = Provider<TelemetryService>((ref) {
  return TelemetryService(ref.watch(apiClientProvider));
});

/// Reactive toggle — true if biometrics are currently enabled
final biometricEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.read(biometricServiceProvider).isEnabled();
});

/// Connectivity state
final connectivityProvider = StateNotifierProvider<ConnectivityService, ConnectivityStatus>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ConnectivityService(apiClient);
});
