import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mimz_app/features/live/presentation/live_quiz_screen.dart';
import 'package:mimz_app/features/live/domain/live_connection_phase.dart';
import '../../test_helpers/test_app_wrapper.dart';
import '../../test_helpers/provider_overrides.dart';
import '../../test_helpers/mocks.dart';

void main() {
  late MockGeminiLiveClient mockGeminiClient;
  late MockAudioService mockAudioService;

  setUp(() {
    mockGeminiClient = MockGeminiLiveClient();
    mockAudioService = MockAudioService();

    // Stub Gemini connection
    when(() => mockGeminiClient.connect(any())).thenAnswer((_) async {});
    when(() => mockGeminiClient.disconnect()).thenAnswer((_) async {});
    when(() => mockGeminiClient.stateStream).thenAnswer((_) => const Stream.empty());

    // Stub audio service
    when(() => mockAudioService.initialize()).thenAnswer((_) async {});
    when(() => mockAudioService.startRecording(any())).thenAnswer((_) async {});
    when(() => mockAudioService.stopRecording()).thenAnswer((_) async {});
    when(() => mockAudioService.dispose()).thenAnswer((_) async {});
  });

  testWidgets('LiveQuizScreen renders waiting state initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestAppWrapper(
        overrides: createTestOverrides(
          geminiClient: mockGeminiClient,
          audioService: mockAudioService,
        ),
        child: const LiveQuizScreen(),
      ),
    );

    // Verify it renders and tries to show connection phase
    expect(find.text('Waiting...'), findsOneWidget);
    
    // Test the disconnect button existence
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
