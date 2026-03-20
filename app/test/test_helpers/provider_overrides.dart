import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mimz_app/core/providers.dart';
import 'package:mimz_app/features/auth/providers/auth_provider.dart';
import 'package:mimz_app/services/api_client.dart';
import 'package:mimz_app/services/auth_service.dart';
import 'package:mimz_app/services/audio_service.dart';
import 'package:mimz_app/services/location_service.dart';
import 'package:mimz_app/services/gemini_live_client.dart';
import 'package:mimz_app/services/settings_service.dart';
import 'package:mimz_app/data/models/user.dart';

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
  // Ensure mock auth provides a non-null Future return for getIdToken().
  final auth = authService ?? MockAuthService();
  final client = apiClient ?? MockApiClient();
  if (auth is MockAuthService) {
    when(() => auth.getIdToken()).thenAnswer((_) async => null);
  }
  if (client is MockApiClient) {
    when(() => client.getGameState()).thenAnswer((_) async => {
          'user': MimzUser.demo.toJson(),
          'district': {
            'id': 'district_demo',
            'ownerId': MimzUser.demo.id,
            'name': 'Verdant Reach',
            'sectors': 7,
            'area': '7.7 sq km',
            'structures': const [],
            'resources': {'stone': 50, 'glass': 20, 'wood': 40},
            'prestigeLevel': 2,
            'influence': 120,
            'influenceThreshold': 500,
            'cells': const [],
            'createdAt': DateTime.now().toIso8601String(),
          },
          'currentMission': 'Build your district',
          'eventZones': const [],
          'streakState': const {'liveStreak': 0, 'dailyStreak': 0, 'bestStreak': 0},
          'structureEffects': const {},
          'structureProgress': const {'unlockedCount': 0, 'totalAvailable': 5, 'readyToBuild': false},
          'notifications': const [],
          'leaderboardSnippets': const [],
          'activeConflicts': const [],
        });
  }

  return [
    apiClientProvider.overrideWithValue(client),
    authServiceProvider.overrideWithValue(auth),
    audioServiceProvider.overrideWithValue(audioService ?? MockAudioService()),
    locationServiceProvider.overrideWithValue(locationService ?? MockLocationService()),
    geminiLiveClientProvider.overrideWithValue(geminiClient ?? MockGeminiLiveClient()),
    settingsServiceProvider.overrideWithValue(settingsService ?? MockSettingsService()),
    isAuthenticatedProvider.overrideWith((ref) => isAuthenticated),
    isOnboardedProvider.overrideWith((ref) => TestOnboardingNotifier(isOnboarded)),
  ];
}
