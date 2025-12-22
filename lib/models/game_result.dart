import 'question.dart';

class GameResult {
  final List<Question> questions;
  final int totalTime; // in seconds
  final int correctCount;
  final int totalCount;

  GameResult({required this.questions, required this.totalTime})
    : correctCount = questions.where((q) => q.isCorrect == true).length,
      totalCount = questions.length;

  double get accuracy => totalCount > 0 ? correctCount / totalCount * 100 : 0;
  double get averageTimePerQuestion =>
      totalCount > 0 ? totalTime / totalCount : 0;

  List<Question> get incorrectQuestions =>
      questions.where((q) => q.isCorrect == false).toList();
}
