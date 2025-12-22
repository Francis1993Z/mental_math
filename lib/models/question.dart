class Question {
  final int a;
  final int b;
  final String operator;
  final int correctAnswer;
  int? userAnswer;
  bool? isCorrect;
  int? responseTimeMs;

  Question({
    required this.a,
    required this.b,
    required this.operator,
    required this.correctAnswer,
  });

  String get display => '$a $operator $b = ?';

  void answer(int value, {int? timeMs}) {
    userAnswer = value;
    isCorrect = value == correctAnswer;
    responseTimeMs = timeMs;
  }
}
