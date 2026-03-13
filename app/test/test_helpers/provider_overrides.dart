import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mimz_app/core/providers.dart';
import 'package:mimz_app/features/auth/providers/auth_provider.dart';

import 'mocks.dart';

class TestOnboardingNotifier extends OnboardingNotifier {
  TestOnboardingNotifier(bool initial) {
    state = initial;
  }

  @override
  Future<void> _load() async {}
}

/// Returns common provider overrides for testing, injecting mocked services.
List<Override> createTestOverrides({
  MockApiClient? apiClient,
  MockAuthService? authService,
  MockAudioService? audioService,
  MockLocationService? locationService,
  MockGeminiLiveClient? geminiClient,
  bool isAuthenticated = true,
  bool isOnboarded = true,
}) {
  return [
    apiClientProvider.overrideWithValue(apiClient ?? MockApiClient()),
    authServiceProvider.overrideWithValue(authService ?? MockAuthService()),
    audioServiceProvider.overrideWithValue(audioService ?? MockAudioService()),
    locationServiceProvider.overrideWithValue(locationService ?? MockLocationService()),
    geminiLiveClientProvider.overrideWithValue(geminiClient ?? MockGeminiLiveClient()),
    isAuthenticatedProvider.overrideWith((ref) => isAuthenticated),
    isOnboardedProvider.overrideWith((ref) => TestOnboardingNotifier(isOnboarded)),
  ];
}
