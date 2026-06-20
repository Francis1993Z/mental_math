import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/algebra_question.dart';

/// Loads and parses the formula questions from assets/questions.json.
///
/// New questions can be added by editing the JSON file only; no code change
/// is required. Malformed entries are skipped (with a debug log) so a single
/// bad entry never breaks the whole bank.
class QuestionLoader {
  static const String _assetPath = 'assets/questions.json';

  List<AlgebraQuestion>? _cache;

  /// Loads all questions, caching the result for the app session.
  Future<List<AlgebraQuestion>> loadAll() async {
    if (_cache != null) return _cache!;

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw);

    final List<dynamic> entries;
    if (decoded is Map<String, dynamic> && decoded['questions'] is List) {
      entries = decoded['questions'] as List<dynamic>;
    } else if (decoded is List) {
      entries = decoded;
    } else {
      throw const FormatException(
        'questions.json doit être une liste ou un objet avec une clé "questions"',
      );
    }

    final parsed = <AlgebraQuestion>[];
    for (final entry in entries) {
      if (entry is! Map<String, dynamic>) continue;
      try {
        parsed.add(AlgebraQuestion.fromJson(entry));
      } on FormatException catch (e) {
        debugPrint('QuestionLoader: entrée ignorée -> ${e.message}');
      }
    }

    _cache = parsed;
    return parsed;
  }

  /// Loads questions filtered by selected categories, difficulty and,
  /// optionally, question types. When [types] is null/empty, all types match.
  Future<List<AlgebraQuestion>> load({
    required List<AlgebraCategory> categories,
    required int difficulty,
    List<AlgebraQuestionType>? types,
  }) async {
    final all = await loadAll();
    return all
        .where((q) =>
            categories.contains(q.category) &&
            q.difficulty == difficulty &&
            (types == null || types.isEmpty || types.contains(q.type)))
        .toList();
  }

  /// Returns the set of (category, difficulty) combinations that actually
  /// have questions. Useful for enabling/disabling UI options.
  Future<Set<String>> availableCombos() async {
    final all = await loadAll();
    return all.map((q) => '${q.category.key}|${q.difficulty}').toSet();
  }
}
