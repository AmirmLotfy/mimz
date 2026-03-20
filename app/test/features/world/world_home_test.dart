import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mimz_app/features/world/presentation/world_home_screen.dart';
import 'package:mimz_app/features/world/presentation/leaderboard_screen.dart';
import 'package:mimz_app/features/world/providers/leaderboard_provider.dart';
import 'package:mimz_app/data/models/user.dart';
import '../../test_helpers/test_app_wrapper.dart';
import '../../test_helpers/provider_overrides.dart';
import '../../test_helpers/mocks.dart';

void main() {
  late MockApiClient mockApiClient;
  late MockAuthService mockAuthService;
  late MockLocationService mockLocationService;

  setUp(() {
    mockApiClient = MockApiClient();
    mockAuthService = MockAuthService();
    mockLocationService = MockLocationService();

    // No general get() method on ApiClient, but we'll mock what we need
    when(() => mockApiClient.getDistrict()).thenAnswer((_) async => {});
    when(() => mockApiClient.getGameState()).thenAnswer((_) async => {
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
    when(() => mockLocationService.hasPermission()).thenAnswer((_) async => true);
    when(() => mockLocationService.getCurrentPosition()).thenAnswer((_) async => null);
  });

  testWidgets('WorldHomeScreen renders map container and interactive viewer', skip: true, (WidgetTester tester) async {
    await tester.pumpWidget(
      TestAppWrapper(
        overrides: createTestOverrides(
          apiClient: mockApiClient,
          authService: mockAuthService,
          locationService: mockLocationService,
        ),
        child: const WorldHomeScreen(),
      ),
    );

    // Give time for initial frames/animations without waiting for infinite loops
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Verify map elements
    expect(find.byType(InteractiveViewer), findsOneWidget);
    // There might be custom painters, but we can just check if InteractiveViewer booted
  });

  testWidgets('LeaderboardScreen renders tabs', skip: true, (WidgetTester tester) async {
    final overrides = createTestOverrides(
      apiClient: mockApiClient,
    );
    // Override leaderboard to return data to avoid loading spinner loop
    overrides.add(leaderboardProvider.overrideWith((ref, scope) async => []));

    await tester.pumpWidget(
      TestAppWrapper(
        overrides: overrides,
        child: const LeaderboardScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Let tab animation settle
    
    // Initial state
    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.text('GLOBAL'), findsOneWidget);
    expect(find.text('WEEKLY'), findsOneWidget);
    expect(find.text('SQUAD'), findsOneWidget);
  });
}
