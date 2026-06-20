import 'algebra_question.dart';

/// Result/score for an Algebre & Trigo session.
///
/// Mirrors the arithmetic [GameResult] so the result screen can present
/// the same statistics.
class AlgebraResult {
  final List<AlgebraQuestion> questions;
  final int totalTime; // in seconds
  final int correctCount;
  final int totalCount;

  AlgebraResult({required this.questions, required this.totalTime})
      : correctCount = questions.where((q) => q.isCorrect == true).length,
        totalCount = questions.length;

  double get accuracy => totalCount > 0 ? correctCount / totalCount * 100 : 0;

  double get averageTimePerQuestion =>
      totalCount > 0 ? totalTime / totalCount : 0;

  List<AlgebraQuestion> get incorrectQuestions =>
      questions.where((q) => q.isCorrect == false).toList();
}
