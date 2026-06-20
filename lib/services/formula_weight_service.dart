import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/algebra_question.dart';

/// Spaced-repetition weighting for the Algebre & Trigo mode.
///
/// Mirrors [WeightService] (used by the arithmetic mode) but keys weights by
/// the question `id` instead of a numeric triple. Questions answered wrong (or
/// slowly) become more likely to reappear; mastered ones fade out.
class FormulaWeightService {
  static const String _weightsKey = 'formula_weights';
  static const String _avgTimeKey = 'formula_avg_response_time';
  static const double defaultWeight = 1.0;
  static const double minWeight = 0.1;
  static const double maxWeight = 10.0;
  static const double correctDecrease = 0.15;
  static const double incorrectIncrease = 0.5;
  static const double slowResponseIncrease = 0.1;

  SharedPreferences? _prefs;
  Map<String, double> _weights = {};
  double _avgResponseTimeMs = 4000;
  final Random _random = Random();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final jsonStr = _prefs?.getString(_weightsKey);
    if (jsonStr != null) {
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      _weights = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }
    _avgResponseTimeMs = _prefs?.getDouble(_avgTimeKey) ?? 4000;
  }

  Future<void> _save() async {
    await _prefs?.setString(_weightsKey, jsonEncode(_weights));
  }

  double getWeight(String id) => _weights[id] ?? defaultWeight;

  /// Picks the next question using weighted random selection.
  AlgebraQuestion? selectWeighted(List<AlgebraQuestion> questions) {
    if (questions.isEmpty) return null;

    double total = 0;
    for (final q in questions) {
      total += getWeight(q.id);
    }

    double r = _random.nextDouble() * total;
    for (final q in questions) {
      r -= getWeight(q.id);
      if (r <= 0) return q;
    }
    return questions.last;
  }

  Future<void> recordAnswer({
    required String id,
    required bool correct,
    int? responseTimeMs,
  }) async {
    double weight = _weights[id] ?? defaultWeight;

    if (correct) {
      weight -= correctDecrease;
      if (responseTimeMs != null && responseTimeMs > _avgResponseTimeMs) {
        weight += slowResponseIncrease;
      }
      _updateAverageTime(responseTimeMs);
    } else {
      weight += incorrectIncrease;
    }

    _weights[id] = weight.clamp(minWeight, maxWeight);
    await _save();
  }

  void _updateAverageTime(int? responseTimeMs) {
    if (responseTimeMs == null) return;
    _avgResponseTimeMs = (_avgResponseTimeMs * 0.9) + (responseTimeMs * 0.1);
    _prefs?.setDouble(_avgTimeKey, _avgResponseTimeMs);
  }

  Future<void> resetWeights() async {
    _weights.clear();
    await _prefs?.remove(_weightsKey);
  }
}
