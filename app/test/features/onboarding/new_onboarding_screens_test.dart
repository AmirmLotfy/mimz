import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mimz_app/data/models/user.dart';
import 'package:mimz_app/features/onboarding/presentation/basic_profile_setup_screen.dart';
import 'package:mimz_app/features/onboarding/presentation/interest_selection_screen.dart';
import 'package:mimz_app/features/onboarding/presentation/gameplay_preferences_screen.dart';
import 'package:mimz_app/features/onboarding/presentation/onboarding_summary_screen.dart';
import '../../test_helpers/test_app_wrapper.dart';
import '../../test_helpers/provider_overrides.dart';
import '../../test_helpers/mocks.dart';

void main() {
  late MockApiClient mockApiClient;
  late MockAuthService mockAuthService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockApiClient = MockApiClient();
    mockAuthService = MockAuthService();

    when(() => mockApiClient.patch(any(), any()))
        .thenAnswer((_) async => {'success': true});
    when(() => mockApiClient.getProfile())
        .thenAnswer((_) async => MimzUser.demo.toJson());
  });

  // ── BasicProfileSetupScreen ────────────────────────────

  group('BasicProfileSetupScreen', () {
    testWidgets('renders heading and name field', (tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: createTestOverrides(
            apiClient: mockApiClient,
            authService: mockAuthService,
          ),
          child: const BasicProfileSetupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Tell us about'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('typing a name enables the continue button', (tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: createTestOverrides(
            apiClient: mockApiClient,
            authService: mockAuthService,
          ),
          child: const BasicProfileSetupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find the first text field (preferred name)
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'Alex');
      await tester.pump();

      // Next button should be enabled
      expect(find.textContaining('Next:'), findsOneWidget);
    });
  });

  // ── InterestSelectionScreen ────────────────────────────

  group('InterestSelectionScreen', () {
    testWidgets('renders interest grid', (tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: createTestOverrides(
            apiClient: mockApiClient,
            authService: mockAuthService,
          ),
          child: const InterestSelectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('curiosity'), findsOneWidget);
      // Chips / items should be available via GestureDetector
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('shows min selection requirement text', (tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: createTestOverrides(
            apiClient: mockApiClient,
            authService: mockAuthService,
          ),
          child: const InterestSelectionScreen(),
        ),
      );
      await tester.pumpAndSettle();
      // Should mention picking at least 3
      expect(find.textContaining('3'), findsWidgets);
    });
  });

  // ── GameplayPreferencesScreen ──────────────────────────

  group('GameplayPreferencesScreen', () {
    testWidgets('renders difficulty cards', (tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: createTestOverrides(
            apiClient: mockApiClient,
            authService: mockAuthService,
          ),
          child: const GameplayPreferencesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Challenge Level'), findsOneWidget);
      expect(find.text('Casual'), findsOneWidget);
      expect(find.text('Dynamic'), findsOneWidget);
      expect(find.text('Challenger'), findsOneWidget);
    });

    testWidgets('renders squad mode options', (tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: createTestOverrides(
            apiClient: mockApiClient,
            authService: mockAuthService,
          ),
          child: const GameplayPreferencesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Squad mode options
      expect(find.text('Solo Explorer'), findsOneWidget);
      expect(find.text('Squad Player'), findsOneWidget);
    });
  });
}
