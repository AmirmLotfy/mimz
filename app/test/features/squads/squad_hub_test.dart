import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mimz_app/features/squads/presentation/squad_hub_screen.dart';
import 'package:mimz_app/features/events/presentation/events_screen.dart';
import 'package:mimz_app/features/squads/providers/squad_provider.dart';
import 'package:mimz_app/features/events/providers/events_provider.dart';
import 'package:mimz_app/services/settings_service.dart';
import 'package:mimz_app/services/api_client.dart';
import 'package:mimz_app/data/models/user.dart';

import '../../test_helpers/test_app_wrapper.dart';
import '../../test_helpers/provider_overrides.dart';
import '../../test_helpers/mocks.dart';

// Use a Fake for SettingsService to avoid flaky mocktail stubs for concrete classes
class FakeSettingsService extends Fake implements SettingsService {
  @override
  Future<bool> getNotifications() async => true;
  @override
  Future<bool> getHaptic() async => true;
  @override
  Future<bool> getSound() async => true;
  @override
  Future<bool> getLocationSharing() async => true;
}

// Use a Fake for ApiClient to avoid flaky mocktail stubs for concrete classes
class FakeApiClient extends Fake implements ApiClient {
  @override
  Future<Map<String, dynamic>> getGameState() async => {
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
      };

  @override
  Future<Map<String, dynamic>> getEvents() async => {'events': []};
  @override
  Future<Map<String, dynamic>> getDistrict() async => <String, dynamic>{};
  @override
  Future<Map<String, dynamic>> getProfile() async => MimzUser.demo.toJson();
}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  testWidgets('SquadHubScreen renders empty states initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestAppWrapper(
        overrides: [
          ...createTestOverrides(
            apiClient: FakeApiClient(),
            authService: mockAuthService,
            settingsService: FakeSettingsService(),
          ),
          squadMissionsProvider.overrideWithValue([]),
          squadMembersProvider.overrideWithValue([]),
          eventsProvider.overrideWith((ref) async => []),
        ],
        child: const SquadHubScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Initial buttons
    expect(find.text('CREATE'), findsOneWidget);
    expect(find.text('JOIN'), findsOneWidget);

    // Empty state text
    expect(find.text('No active missions'), findsOneWidget);
    expect(find.text('No members yet'), findsOneWidget);
    
    // Cleanup
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('EventsScreen renders empty state when no events exist', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestAppWrapper(
        overrides: [
          ...createTestOverrides(
            apiClient: FakeApiClient(),
            authService: mockAuthService,
            settingsService: FakeSettingsService(),
          ),
          eventsProvider.overrideWith((ref) async => []),
        ],
        child: const EventsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Events'), findsWidgets);
    expect(find.text('No events scheduled'), findsOneWidget);
    
    // Cleanup
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
  });
}
