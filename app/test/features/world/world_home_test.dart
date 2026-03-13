import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mimz_app/features/world/presentation/world_home_screen.dart';
import 'package:mimz_app/features/world/presentation/leaderboard_screen.dart';
import 'package:mimz_app/features/world/providers/leaderboard_provider.dart';
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
    overrides.add(globalLeaderboardProvider.overrideWith((ref) => []));

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
    expect(find.text('DISTRICT'), findsOneWidget);
    expect(find.text('SQUAD'), findsOneWidget);
  });
}
