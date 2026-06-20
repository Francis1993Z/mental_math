import 'game_config.dart';
import 'algebra_question.dart';

/// Configuration for an Algebre & Trigo session.
///
/// Reuses [GameMode] from the existing arithmetic mode so the timer/flow
/// behaviour stays consistent across the app.
class AlgebraConfig {
  final List<AlgebraCategory> categories;
  final int difficulty; // 1..3
  final GameMode mode;
  final int? duration; // seconds, for timed mode
  final int? questionCount; // for fixed-questions mode
  final bool showImmediateFeedback;

  /// When true, after a WRONG answer the screen shows the correct answer and
  /// waits for the player to tap "Continuer" instead of auto-advancing.
  /// Only relevant when [showImmediateFeedback] is true.
  final bool pauseOnError;

  AlgebraConfig({
    required this.categories,
    required this.difficulty,
    required this.mode,
    this.duration,
    this.questionCount,
    required this.showImmediateFeedback,
    this.pauseOnError = false,
  });
}
