import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mimz_app/features/settings/presentation/settings_screen.dart';
import 'package:mimz_app/features/district/presentation/district_detail_screen.dart';
import '../../test_helpers/test_app_wrapper.dart';
import '../../test_helpers/provider_overrides.dart';
import '../../test_helpers/mocks.dart';

void main() {
  late MockApiClient mockApiClient;
  late MockAuthService mockAuthService;

  setUp(() {
    mockApiClient = MockApiClient();
    mockAuthService = MockAuthService();
    when(() => mockApiClient.getDistrict()).thenAnswer((_) async => {});
  });

  testWidgets('SettingsScreen renders standard preference fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestAppWrapper(
        overrides: createTestOverrides(
          apiClient: mockApiClient,
          authService: mockAuthService,
        ),
        child: const SettingsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('PREFERENCES'), findsOneWidget);
    
    // Toggles exist
    expect(find.byType(Switch), findsWidgets);
  });

  testWidgets('DistrictDetailScreen renders HUD and resources', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestAppWrapper(
        overrides: createTestOverrides(
          apiClient: mockApiClient,
          authService: mockAuthService,
        ),
        child: const DistrictDetailScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Your District'), findsOneWidget);
    expect(find.text('RESOURCES'), findsOneWidget);
  });
}
