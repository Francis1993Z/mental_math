import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/function_analysis.dart';

/// Loads and parses the function-analysis questions from
/// assets/function_analysis.json.
///
/// New functions can be added by editing the JSON only. Malformed entries are
/// skipped (with a debug log) so a single bad entry never breaks the bank.
class FunctionAnalysisLoader {
  static const String _assetPath = 'assets/function_analysis.json';

  List<FunctionAnalysisQuestion>? _cache;

  Future<List<FunctionAnalysisQuestion>> loadAll() async {
    if (_cache != null) return _cache!;

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw);

    final List<dynamic> entries;
    if (decoded is Map<String, dynamic> && decoded['functions'] is List) {
      entries = decoded['functions'] as List<dynamic>;
    } else if (decoded is List) {
      entries = decoded;
    } else {
      throw const FormatException(
        'function_analysis.json doit être une liste ou un objet avec une clé "functions"',
      );
    }

    final parsed = <FunctionAnalysisQuestion>[];
    for (final entry in entries) {
      if (entry is! Map<String, dynamic>) continue;
      try {
        parsed.add(FunctionAnalysisQuestion.fromJson(entry));
      } on FormatException catch (e) {
        debugPrint('FunctionAnalysisLoader: entrée ignorée -> ${e.message}');
      }
    }

    _cache = parsed;
    return parsed;
  }

  /// Loads questions filtered by difficulty.
  Future<List<FunctionAnalysisQuestion>> load({required int difficulty}) async {
    final all = await loadAll();
    return all.where((q) => q.difficulty == difficulty).toList();
  }
}
