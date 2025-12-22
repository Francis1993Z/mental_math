import 'dart:math';
import '../models/question.dart';
import 'weight_service.dart';

class QuestionGenerator {
  final int minValue;
  final int maxValue;
  final List<String> operators;
  final WeightService? weightService;
  final Random _random = Random();

  QuestionGenerator({
    required this.minValue,
    required this.maxValue,
    required this.operators,
    this.weightService,
  });

  Question generate() {
    final allPairs = _buildAllValidPairs();

    if (allPairs.isEmpty) {
      return Question(a: 1, b: 1, operator: '+', correctAnswer: 2);
    }

    final (int a, int b, String operator) = _selectPair(allPairs);
    final answer = _calculate(a, b, operator);

    return Question(a: a, b: b, operator: operator, correctAnswer: answer);
  }

  List<(int, int, String)> _buildAllValidPairs() {
    final pairs = <(int, int, String)>[];

    for (final operator in operators) {
      if (operator == '÷') {
        for (
          int divisor = (minValue == 0 ? 1 : minValue);
          divisor <= maxValue;
          divisor++
        ) {
          for (int quotient = minValue; quotient <= maxValue; quotient++) {
            final dividend = divisor * quotient;
            if (dividend >= minValue && dividend <= maxValue) {
              pairs.add((dividend, divisor, operator));
            }
          }
        }
      } else if (operator == '−') {
        for (int a = minValue; a <= maxValue; a++) {
          for (int b = minValue; b <= a; b++) {
            pairs.add((a, b, operator));
          }
        }
      } else {
        for (int a = minValue; a <= maxValue; a++) {
          for (int b = minValue; b <= maxValue; b++) {
            pairs.add((a, b, operator));
          }
        }
      }
    }

    return pairs;
  }

  (int, int, String) _selectPair(List<(int, int, String)> pairs) {
    if (weightService == null) {
      return pairs[_random.nextInt(pairs.length)];
    }

    double totalWeight = 0;
    for (final pair in pairs) {
      totalWeight += weightService!.getWeight(pair.$1, pair.$2, pair.$3);
    }

    double randomValue = _random.nextDouble() * totalWeight;

    for (final pair in pairs) {
      randomValue -= weightService!.getWeight(pair.$1, pair.$2, pair.$3);
      if (randomValue <= 0) {
        return pair;
      }
    }

    return pairs.last;
  }

  int _calculate(int a, int b, String operator) {
    switch (operator) {
      case '+':
        return a + b;
      case '−':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        return b != 0 ? a ~/ b : 0;
      default:
        return 0;
    }
  }
}
