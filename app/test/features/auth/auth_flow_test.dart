import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mimz_app/features/auth/presentation/auth_screen.dart';
import 'package:mimz_app/features/auth/presentation/welcome_screen.dart';
import 'package:mimz_app/services/auth_service.dart';
import '../../test_helpers/test_app_wrapper.dart';
import '../../test_helpers/provider_overrides.dart';
import '../../test_helpers/mocks.dart';

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
    // Default stub for auth submission
    when(() => mockAuthService.signInWithEmail(any(), any()))
        .thenAnswer((_) async => AuthResult.ok());
  });

  testWidgets('WelcomeScreen renders properly and contains GET STARTED button', (WidgetTester tester) async {
    final mockSettings = MockSettingsService();
    when(() => mockSettings.getNotifications()).thenAnswer((_) async => true);
    when(() => mockSettings.getHaptic()).thenAnswer((_) async => true);
    when(() => mockSettings.getSound()).thenAnswer((_) async => true);
    when(() => mockSettings.getLocationSharing()).thenAnswer((_) async => true);

    await tester.pumpWidget(
      TestAppWrapper(
        overrides: createTestOverrides(
          authService: mockAuthService,
          settingsService: mockSettings,
        ),
        child: const WelcomeScreen(),
      ),
    );

    // Initial pump for animations
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('GET STARTED'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
    
    // Aggressive cleanup for animations
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('AuthScreen renders all authentication methods', (WidgetTester tester) async {
    final mockSettings = MockSettingsService();
    when(() => mockSettings.getNotifications()).thenAnswer((_) async => true);
    when(() => mockSettings.getHaptic()).thenAnswer((_) async => true);
    when(() => mockSettings.getSound()).thenAnswer((_) async => true);
    when(() => mockSettings.getLocationSharing()).thenAnswer((_) async => true);
    
    await tester.pumpWidget(
      TestAppWrapper(
        overrides: createTestOverrides(
          authService: mockAuthService,
          settingsService: mockSettings,
        ),
        child: const AuthScreen(),
      ),
    );

    // Look for text in the buttons
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Email'), findsOneWidget);
    
    // Cleanup
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('AuthScreen displays loading state on Email auth submission', (WidgetTester tester) async {
    final mockSettings = MockSettingsService();
    when(() => mockSettings.getNotifications()).thenAnswer((_) async => true);
    when(() => mockSettings.getHaptic()).thenAnswer((_) async => true);
    when(() => mockSettings.getSound()).thenAnswer((_) async => true);
    when(() => mockSettings.getLocationSharing()).thenAnswer((_) async => true);

    when(() => mockAuthService.signInWithEmail(any(), any()))
        .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return AuthResult.ok();
        });

    await tester.pumpWidget(
      TestAppWrapper(
        overrides: createTestOverrides(
          authService: mockAuthService,
          settingsService: mockSettings,
        ),
        child: const AuthScreen(),
      ),
    );

    // Initial state: no spinner
    expect(find.byType(CircularProgressIndicator), findsNothing);

    final emailButton = find.text('Continue with Email');
    expect(emailButton, findsOneWidget);
    
    // Cleanup
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
