import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mimz_app/features/live/presentation/vision_quest_camera_screen.dart';
import 'package:mimz_app/features/live/providers/live_session_provider.dart';
import '../../test_helpers/test_app_wrapper.dart';
import '../../test_helpers/provider_overrides.dart';

void main() {
  testWidgets('VisionQuestCameraScreen renders camera placeholder when loading', (WidgetTester tester) async {
    final overrides = createTestOverrides();
    // Override the target provider so the UI shows something
    overrides.add(visionQuestTargetProvider.overrideWith((ref) => 'A green leaf'));

    await tester.pumpWidget(
      TestAppWrapper(
        overrides: overrides,
        child: const VisionQuestCameraScreen(),
      ),
    );

    // Since we can't easily mock the native camera controller inline without massive setup,
    // we expect the placeholder videocam icon to be visible initially.
    expect(find.byIcon(Icons.videocam), findsOneWidget);
    
    // We also expect the scanning UI elements
    expect(find.text('VISION QUEST'), findsOneWidget);
    expect(find.text('CURRENT TARGET'), findsOneWidget);
  });
}
