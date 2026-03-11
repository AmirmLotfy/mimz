/// Live quiz state
class QuizState {
  final String? questionId;
  final String questionText;
  final int score;
  final int streak;
  final int timeLeft;
  final QuizStatus status;

  const QuizState({
    this.questionId,
    this.questionText = '',
    this.score = 0,
    this.streak = 0,
    this.timeLeft = 30,
    this.status = QuizStatus.waiting,
  });

  QuizState copyWith({
    String? questionId,
    String? questionText,
    int? score,
    int? streak,
    int? timeLeft,
    QuizStatus? status,
  }) =>
      QuizState(
        questionId: questionId ?? this.questionId,
        questionText: questionText ?? this.questionText,
        score: score ?? this.score,
        streak: streak ?? this.streak,
        timeLeft: timeLeft ?? this.timeLeft,
        status: status ?? this.status,
      );

  static QuizState get demo => const QuizState(
        questionId: 'q1',
        questionText: 'Which architect designed the "Fallingwater" house in Pennsylvania?',
        score: 12450,
        streak: 8,
        timeLeft: 22,
        status: QuizStatus.listening,
      );
}

enum QuizStatus { waiting, listening, answered, correct, incorrect, finished }
