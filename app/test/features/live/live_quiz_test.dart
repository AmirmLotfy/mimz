import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mimz_app/features/live/presentation/live_quiz_screen.dart';
import 'package:mimz_app/features/live/providers/live_providers.dart';
import '../../test_helpers/test_app_wrapper.dart';
import '../../test_helpers/provider_overrides.dart';
import '../../test_helpers/mocks.dart';

void main() {
  late MockGeminiLiveClient mockGeminiClient;
  late MockAudioService mockAudioService;
  late MockLiveSessionController mockLiveController;

  setUp(() {
    mockGeminiClient = MockGeminiLiveClient();
    mockAudioService = MockAudioService();
    mockLiveController = MockLiveSessionController();

    // Stub Gemini connection
    when(() => mockGeminiClient.connect(systemInstruction: any(named: 'systemInstruction'))).thenAnswer((_) async {});
    when(() => mockGeminiClient.disconnect()).thenAnswer((_) async {});
    when(() => mockGeminiClient.stateStream).thenAnswer((_) => const Stream.empty());

    // Stub audio service
    when(() => mockAudioService.startRecording()).thenAnswer((_) async {});
    when(() => mockAudioService.stopRecording()).thenAnswer((_) async {});
    when(() => mockAudioService.dispose()).thenAnswer((_) async {});

    // Stub live session controller (returns Future<void>)
    when(() => mockLiveController.startQuizSession()).thenAnswer((_) async {});
    when(() => mockLiveController.endSession()).thenAnswer((_) async {});
    when(() => mockLiveController.stateStream).thenAnswer((_) => const Stream.empty());
    // UI reads these getters synchronously; default unstubbed mocktail values can be null.
    when(() => mockLiveController.hintCount).thenReturn(0);
    when(() => mockLiveController.repeatCount).thenReturn(0);
  });

  testWidgets('LiveQuizScreen renders waiting state initially', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    await tester.pumpWidget(
      TestAppWrapper(
        overrides: [
          ...createTestOverrides(
            geminiClient: mockGeminiClient,
            audioService: mockAudioService,
          ),
          liveSessionControllerProvider.overrideWithValue(mockLiveController),
        ],
        child: const LiveQuizScreen(),
      ),
    );

    // Verify it renders and tries to show connection phase
    expect(find.text('Starting...'), findsOneWidget);
    
    // Test the disconnect button existence
    expect(find.byIcon(Icons.close), findsOneWidget);

    // Cleanup
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
