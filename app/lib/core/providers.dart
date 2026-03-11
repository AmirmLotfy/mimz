import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/gemini_live_client.dart';
import '../../services/audio_service.dart';
import '../../services/location_service.dart';

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
