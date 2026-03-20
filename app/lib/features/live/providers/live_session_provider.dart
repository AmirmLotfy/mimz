import 'dart:math' show max;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/quiz_state.dart';
import '../../../data/models/district.dart';
import 'live_providers.dart' show liveSessionStateProvider;

/// Quiz game state
final quizStateProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier();
});

class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier() : super(const QuizState());

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

/// Rewards derived from backend-granted totals accumulated during the live session.
final roundRewardsProvider = Provider<RoundRewards>((ref) {
  final session = ref.watch(liveSessionStateProvider).valueOrNull;
  if (session == null) return const RoundRewards();
  return RoundRewards(
    sectorsEarned: session.grantedSectors,
    materialsEarned: Resources(
      stone: session.grantedStone,
      glass: session.grantedGlass,
      wood: session.grantedWood,
    ),
    xpEarned: session.grantedXp,
    streakBonus: session.grantedComboXp,
  );
});

class RoundRewards {
  final int sectorsEarned;
  final Resources materialsEarned;
  final int xpEarned;
  final int streakBonus;

  const RoundRewards({
    this.sectorsEarned = 0,
    this.materialsEarned = const Resources(),
    this.xpEarned = 0,
    this.streakBonus = 0,
  });
}

/// Vision quest camera state
final visionQuestActiveProvider = StateProvider<bool>((ref) => false);
final visionQuestTargetProvider = StateProvider<String>(
  (ref) => 'Show me something interesting around you.',
);

/// Label of the object Gemini identified in the vision quest image.
final visionQuestResultLabelProvider = StateProvider<String>(
  (ref) => '',
);

/// XP awarded for the vision quest validation
final visionQuestXpProvider = StateProvider<int>((ref) => 0);

/// Whether the vision quest validation was valid
final visionQuestValidProvider = StateProvider<bool>((ref) => false);
