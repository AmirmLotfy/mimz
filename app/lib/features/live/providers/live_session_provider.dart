import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../data/models/quiz_state.dart';
import '../../../services/gemini_live_client.dart';

/// Live session connection state
final liveSessionStateProvider = StreamProvider<LiveSessionState>((ref) {
  final client = ref.watch(geminiLiveClientProvider);
  return client.stateStream;
});

/// Incoming Gemini messages
final geminiMessageProvider = StreamProvider<GeminiMessage>((ref) {
  final client = ref.watch(geminiLiveClientProvider);
  return client.messageStream;
});

/// Incoming tool calls from Gemini
final geminiToolCallProvider = StreamProvider<GeminiToolCall>((ref) {
  final client = ref.watch(geminiLiveClientProvider);
  return client.toolCallStream;
});

/// Quiz game state
final quizStateProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier();
});

class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier() : super(QuizState.demo);

  void setQuestion(String id, String text) {
    state = state.copyWith(
      questionId: id,
      questionText: text,
      status: QuizStatus.listening,
    );
  }

  void scoreAnswer({required bool correct, int points = 100}) {
    state = state.copyWith(
      score: state.score + (correct ? points * state.streak : 0),
      streak: correct ? state.streak + 1 : 0,
      status: correct ? QuizStatus.correct : QuizStatus.incorrect,
    );
  }

  void finishRound() {
    state = state.copyWith(status: QuizStatus.finished);
  }

  void reset() {
    state = const QuizState();
  }
}

/// Vision quest camera state
final visionQuestActiveProvider = StateProvider<bool>((ref) => false);
final visionQuestTargetProvider = StateProvider<String>(
  (ref) => 'Show something related to architecture or design.',
);
