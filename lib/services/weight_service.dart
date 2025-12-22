import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WeightService {
  static const String _weightsKey = 'pair_weights';
  static const double defaultWeight = 1.0;
  static const double minWeight = 0.1;
  static const double maxWeight = 10.0;
  static const double correctDecrease = 0.15;
  static const double incorrectIncrease = 0.5;

  SharedPreferences? _prefs;
  Map<String, double> _weights = {};

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
  }) async {
    final key = _makeKey(a, b, operator);
    double currentWeight = _weights[key] ?? defaultWeight;

    if (correct) {
      currentWeight -= correctDecrease;
    } else {
      currentWeight += incorrectIncrease;
    }

    currentWeight = currentWeight.clamp(minWeight, maxWeight);
    _weights[key] = currentWeight;

    await _saveWeights();
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
