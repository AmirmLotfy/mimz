import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mimz_app/features/onboarding/presentation/district_naming_screen.dart';
import 'package:mimz_app/features/onboarding/presentation/emblem_selection_screen.dart';
import '../../test_helpers/test_app_wrapper.dart';
import '../../test_helpers/provider_overrides.dart';
import '../../test_helpers/mocks.dart';

void main() {
  late MockApiClient mockApiClient;
  late MockAuthService mockAuthService;

  setUp(() {
    mockApiClient = MockApiClient();
    mockAuthService = MockAuthService();
    
    // Stub API patch
    when(() => mockApiClient.patch(any(), any())).thenAnswer((_) async => {'success': true});
  });

  testWidgets('DistrictNamingScreen renders and allows text input', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestAppWrapper(
        overrides: createTestOverrides(
          apiClient: mockApiClient,
          authService: mockAuthService,
        ),
        child: const DistrictNamingScreen(),
      ),
    );

    // Verify initial rendering
    expect(find.text('Name Your District'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Enter a new name
    await tester.enterText(find.byType(TextField), 'Test District');
    await tester.pump();

    // Verify confirm button exists
    expect(find.text('ESTABLISH DISTRICT  →'), findsOneWidget);
  });

  testWidgets('EmblemSelectionScreen renders grid and allows selection', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestAppWrapper(
        overrides: createTestOverrides(
          apiClient: mockApiClient,
        ),
        child: const EmblemSelectionScreen(),
      ),
    );

    // Verify initial rendering
    expect(find.text('Choose your\nemblem'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);

    // Verify next button exists
    expect(find.text('CONTINUE  →'), findsOneWidget);
  });
}
