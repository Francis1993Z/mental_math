class Question {
  final int a;
  final int b;
  final String operator;
  final int correctAnswer;
  int? userAnswer;
  bool? isCorrect;

  Question({
    required this.a,
    required this.b,
    required this.operator,
    required this.correctAnswer,
  });

  String get display => '$a $operator $b = ?';

  void answer(int value) {
    userAnswer = value;
    isCorrect = value == correctAnswer;
  }
}
