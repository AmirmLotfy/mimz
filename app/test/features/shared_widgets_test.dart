import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mimz_app/design_system/components/mimz_button.dart';

void main() {
  group('MimzButton Widget Tests', () {
    testWidgets('renders primary button correctly', (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MimzButton(
                label: 'PRIMARY',
                onPressed: () => pressed = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('PRIMARY'), findsOneWidget);
      
      await tester.tap(find.byType(MimzButton));
      await tester.pumpAndSettle();
      
      expect(pressed, isTrue);
    });

    testWidgets('renders disabled button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MimzButton(
                label: 'DISABLED',
                onPressed: null,
              ),
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.enabled, isFalse);
    });
  });
}
