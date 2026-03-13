import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mimz_app/features/squads/presentation/squad_hub_screen.dart';
import 'package:mimz_app/features/events/presentation/events_screen.dart';
import '../../test_helpers/test_app_wrapper.dart';
import '../../test_helpers/provider_overrides.dart';
import '../../test_helpers/mocks.dart';

void main() {
  late MockApiClient mockApiClient;
  late MockAuthService mockAuthService;

  setUp(() {
    mockApiClient = MockApiClient();
    mockAuthService = MockAuthService();
    when(() => mockApiClient.get(any(), queryParameters: any(named: 'queryParameters'))).thenAnswer((_) async => {});
  });

  testWidgets('SquadHubScreen renders empty states initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestAppWrapper(
        overrides: createTestOverrides(
          apiClient: mockApiClient,
          authService: mockAuthService,
        ),
        child: const SquadHubScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Initial buttons
    expect(find.text('CREATE SQUAD'), findsOneWidget);
    expect(find.text('JOIN SQUAD'), findsOneWidget);

    // Empty state text (since there are no mocked missions/members passed in the override)
    expect(find.text('No active missions'), findsOneWidget);
    expect(find.text('No members yet'), findsOneWidget);
  });

  testWidgets('EventsScreen renders empty state when no events exist', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestAppWrapper(
        overrides: createTestOverrides(
          apiClient: mockApiClient,
          authService: mockAuthService,
        ),
        child: const EventsScreen(),
      ),
    );

    // Events triggers async loads so let's settle it.
    await tester.pumpAndSettle();

    expect(find.text('Events'), findsOneWidget);
    expect(find.text('No events scheduled'), findsOneWidget);
  });
}
