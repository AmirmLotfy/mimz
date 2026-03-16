import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mimz_app/core/providers.dart';
import 'package:mimz_app/features/auth/providers/auth_provider.dart';
import 'package:mimz_app/services/api_client.dart';
import 'package:mimz_app/services/auth_service.dart';
import 'package:mimz_app/services/audio_service.dart';
import 'package:mimz_app/services/location_service.dart';
import 'package:mimz_app/services/gemini_live_client.dart';
import 'package:mimz_app/services/settings_service.dart';

import 'mocks.dart';

class TestOnboardingNotifier extends OnboardingNotifier {
  TestOnboardingNotifier(bool initial) {
    state = AsyncValue.data(initial);
  }

}

/// Returns common provider overrides for testing, injecting mocked services.
List<Override> createTestOverrides({
  ApiClient? apiClient,
  AuthService? authService,
  AudioService? audioService,
  LocationService? locationService,
  GeminiLiveClient? geminiClient,
  SettingsService? settingsService,
  bool isAuthenticated = true,
  bool isOnboarded = true,
}) {
  return [
    apiClientProvider.overrideWithValue(apiClient ?? MockApiClient()),
    authServiceProvider.overrideWithValue(authService ?? MockAuthService()),
    audioServiceProvider.overrideWithValue(audioService ?? MockAudioService()),
    locationServiceProvider.overrideWithValue(locationService ?? MockLocationService()),
    geminiLiveClientProvider.overrideWithValue(geminiClient ?? MockGeminiLiveClient()),
    settingsServiceProvider.overrideWithValue(settingsService ?? MockSettingsService()),
    isAuthenticatedProvider.overrideWith((ref) => isAuthenticated),
    isOnboardedProvider.overrideWith((ref) => TestOnboardingNotifier(isOnboarded)),
  ];
}
