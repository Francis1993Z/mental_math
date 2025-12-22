import 'dart:math';
import '../models/question.dart';

class QuestionGenerator {
  final int minValue;
  final int maxValue;
  final List<String> operators;
  final Random _random = Random();

  QuestionGenerator({
    required this.minValue,
    required this.maxValue,
    required this.operators,
  });

  Question generate() {
    final operator = operators[_random.nextInt(operators.length)];
    int a = _randomInRange();
    int b = _randomInRange();

    // For division, ensure clean division (no remainder)
    if (operator == '÷') {
      // Build list of valid (a, b) pairs where a/b has no remainder
      // and both a and b are in range, b != 0
      final validPairs = <(int, int)>[];
      for (
        int divisor = (minValue == 0 ? 1 : minValue);
        divisor <= maxValue;
        divisor++
      ) {
        for (int quotient = minValue; quotient <= maxValue; quotient++) {
          final dividend = divisor * quotient;
          if (dividend >= minValue && dividend <= maxValue) {
            validPairs.add((dividend, divisor));
          }
        }
      }

      if (validPairs.isNotEmpty) {
        final pair = validPairs[_random.nextInt(validPairs.length)];
        a = pair.$1;
        b = pair.$2;
      } else {
        // Fallback: simple case
        b = 1;
        a = _randomInRange();
      }
    }

    // For subtraction, optionally ensure non-negative result
    if (operator == '−' && a < b) {
      final temp = a;
      a = b;
      b = temp;
    }

    final answer = _calculate(a, b, operator);

    return Question(a: a, b: b, operator: operator, correctAnswer: answer);
  }

  int _randomInRange() {
    if (maxValue < minValue) return minValue;
    return minValue + _random.nextInt(maxValue - minValue + 1);
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
