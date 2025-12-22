import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WeightService {
  static const String _weightsKey = 'pair_weights';
  static const double defaultWeight = 1.0;
  static const double minWeight = 0.1;
  static const double maxWeight = 10.0;
  static const double correctDecrease = 0.15;
  static const double incorrectIncrease = 0.5;
  static const double slowResponseIncrease = 0.1;
  static const String _avgTimeKey = 'avg_response_time';

  SharedPreferences? _prefs;
  Map<String, double> _weights = {};
  double _avgResponseTimeMs = 3000;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadWeights();
  }

  Future<void> _loadWeights() async {
    final String? jsonStr = _prefs?.getString(_weightsKey);
    if (jsonStr != null) {
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      _weights = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }
    _avgResponseTimeMs = _prefs?.getDouble(_avgTimeKey) ?? 3000;
  }

  Future<void> _saveWeights() async {
    await _prefs?.setString(_weightsKey, jsonEncode(_weights));
  }

  String _makeKey(int a, int b, String operator) {
    return '$a|$operator|$b';
  }

  double getWeight(int a, int b, String operator) {
    final key = _makeKey(a, b, operator);
    return _weights[key] ?? defaultWeight;
  }

  Future<void> recordAnswer({
    required int a,
    required int b,
    required String operator,
    required bool correct,
    int? responseTimeMs,
  }) async {
    final key = _makeKey(a, b, operator);
    double currentWeight = _weights[key] ?? defaultWeight;

    if (correct) {
      currentWeight -= correctDecrease;

      if (responseTimeMs != null && responseTimeMs > _avgResponseTimeMs) {
        currentWeight += slowResponseIncrease;
      }

      _updateAverageTime(responseTimeMs);
    } else {
      currentWeight += incorrectIncrease;
    }

    currentWeight = currentWeight.clamp(minWeight, maxWeight);
    _weights[key] = currentWeight;

    await _saveWeights();
  }

  void _updateAverageTime(int? responseTimeMs) {
    if (responseTimeMs == null) return;
    _avgResponseTimeMs = (_avgResponseTimeMs * 0.9) + (responseTimeMs * 0.1);
    _prefs?.setDouble(_avgTimeKey, _avgResponseTimeMs);
  }

  Map<String, double> getAllWeights() => Map.unmodifiable(_weights);

  Future<void> resetWeights() async {
    _weights.clear();
    await _prefs?.remove(_weightsKey);
  }

  double getTotalWeight(List<(int, int, String)> pairs) {
    double total = 0;
    for (final pair in pairs) {
      total += getWeight(pair.$1, pair.$2, pair.$3);
    }
    return total;
  }

  (int, int, String)? selectWeightedPair(List<(int, int, String)> pairs) {
    if (pairs.isEmpty) return null;

    final totalWeight = getTotalWeight(pairs);
    double random =
        (DateTime.now().microsecondsSinceEpoch % 1000000) /
        1000000 *
        totalWeight;

    for (final pair in pairs) {
      random -= getWeight(pair.$1, pair.$2, pair.$3);
      if (random <= 0) {
        return pair;
      }
    }

    return pairs.last;
  }
}
