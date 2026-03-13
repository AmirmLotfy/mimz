import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../data/models/quiz_state.dart';
import '../../../data/models/district.dart';
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
      score: state.score + (correct ? points * max(state.streak, 1) : 0),
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

/// Calculated rewards from a quiz round — derived from quiz state
final roundRewardsProvider = Provider<RoundRewards>((ref) {
  final quiz = ref.watch(quizStateProvider);
  return RoundRewards.fromQuizState(quiz);
});

/// Computed rewards based on quiz performance
class RoundRewards {
  final int sectorsEarned;
  final Resources materialsEarned;
  final int xpEarned;
  final int streakBonus;

  const RoundRewards({
    required this.sectorsEarned,
    required this.materialsEarned,
    required this.xpEarned,
    required this.streakBonus,
  });

  /// Calculate rewards from quiz score:
  /// - 1 sector per 2000 points (min 1 if score > 0)
  /// - Materials scale with score and streak
  /// - XP = score
  /// - Streak bonus = extra materials
  factory RoundRewards.fromQuizState(QuizState quiz) {
    if (quiz.score <= 0) {
      return const RoundRewards(
        sectorsEarned: 0,
        materialsEarned: Resources(),
        xpEarned: 0,
        streakBonus: 0,
      );
    }

    final sectors = max(1, quiz.score ~/ 2000);
    final streakMult = max(1, quiz.streak);
    final stone = 20 + (quiz.score ~/ 100) + streakMult * 5;
    final glass = 10 + (quiz.score ~/ 250) + streakMult * 3;
    final wood = 15 + (quiz.score ~/ 150) + streakMult * 4;
    final bonus = streakMult * 50;

    return RoundRewards(
      sectorsEarned: sectors.clamp(1, 5),
      materialsEarned: Resources(stone: stone, glass: glass, wood: wood),
      xpEarned: quiz.score,
      streakBonus: bonus,
    );
  }
}

/// Vision quest camera state
final visionQuestActiveProvider = StateProvider<bool>((ref) => false);
final visionQuestTargetProvider = StateProvider<String>(
  (ref) => 'Show something related to architecture or design.',
);

/// Label of the object Gemini identified in the vision quest image.
/// Set on the camera screen before navigating to success.
final visionQuestResultLabelProvider = StateProvider<String>(
  (ref) => '',
);
