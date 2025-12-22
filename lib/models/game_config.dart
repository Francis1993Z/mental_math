enum GameMode { timed, fixedQuestions }

class GameConfig {
  final int minValue;
  final int maxValue;
  final List<String> operators;
  final GameMode mode;
  final int? duration; // seconds for timed mode
  final int? questionCount; // for fixed questions mode
  final bool showImmediateFeedback;

  GameConfig({
    required this.minValue,
    required this.maxValue,
    required this.operators,
    required this.mode,
    this.duration,
    this.questionCount,
    required this.showImmediateFeedback,
  });
}
