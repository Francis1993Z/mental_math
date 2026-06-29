import 'game_config.dart';

/// Sign of a derivative on an interval (used for f' and f'').
enum Sign { positive, negative }

extension SignX on Sign {
  String get symbol => this == Sign.positive ? '+' : '-';

  static Sign? fromString(String? s) {
    if (s == null) return null;
    final t = s.trim();
    if (t == '+') return Sign.positive;
    if (t == '-' || t == '\u2212') return Sign.negative; // '-' or '−'
    return null;
  }
}

/// Classification of a critical / particular point.
enum ExtremumType { max, min, inflection }

extension ExtremumTypeX on ExtremumType {
  String get label {
    switch (this) {
      case ExtremumType.max:
        return 'Maximum';
      case ExtremumType.min:
        return 'Minimum';
      case ExtremumType.inflection:
        return 'Inflexion';
    }
  }

  /// Short LaTeX-friendly symbol for the table.
  String get shortLabel {
    switch (this) {
      case ExtremumType.max:
        return 'Max';
      case ExtremumType.min:
        return 'Min';
      case ExtremumType.inflection:
        return 'Infl.';
    }
  }

  String get key {
    switch (this) {
      case ExtremumType.max:
        return 'max';
      case ExtremumType.min:
        return 'min';
      case ExtremumType.inflection:
        return 'inflexion';
    }
  }

  static ExtremumType? fromKey(String? k) {
    switch (k) {
      case 'max':
        return ExtremumType.max;
      case 'min':
        return ExtremumType.min;
      case 'inflexion':
      case 'inflection':
        return ExtremumType.inflection;
    }
    return null;
  }
}

/// Normalises a math string for lenient comparison: removes whitespace and
/// common LaTeX spacing/grouping commands, and unifies the unicode minus.
String normalizeMath(String input) {
  var s = input;
  // Unify unicode minus and operators.
  s = s.replaceAll('\u2212', '-'); // −
  s = s.replaceAll('\u221E', '\\infty'); // ∞
  // Remove LaTeX spacing and grouping helpers.
  for (final cmd in ['\\left', '\\right', '\\,', '\\;', '\\:', '\\!', '\\ ']) {
    s = s.replaceAll(cmd, '');
  }
  // Remove all remaining whitespace.
  s = s.replaceAll(RegExp(r'\s+'), '');
  return s;
}

/// One expected row of the analysis table.
class AnalysisInterval {
  /// Canonical LaTeX of the interval, e.g. "(-\\infty,-3)".
  final String intervalLatex;
  final Sign fPrime;
  final Sign fSecond;

  /// Optional behaviour note (e.g. "vient de -\\infty"). Shown in the
  /// correction but not required to be correct.
  final String? note;

  AnalysisInterval({
    required this.intervalLatex,
    required this.fPrime,
    required this.fSecond,
    this.note,
  });

  /// Allure (shape) LaTeX derived from the two signs: monotonicity arrow plus
  /// concavity symbol. f' > 0 -> increasing (↗), f'' > 0 -> concave up (∪).
  String get allureLatex => allureFor(fPrime, fSecond);

  static String allureFor(Sign fPrime, Sign fSecond) {
    final arrow = fPrime == Sign.positive ? '\\nearrow' : '\\searrow';
    final concavity = fSecond == Sign.positive ? '\\cup' : '\\cap';
    return '$arrow\\;$concavity';
  }

  factory AnalysisInterval.fromJson(Map<String, dynamic> json) {
    final interval = json['interval_latex'];
    if (interval is! String || interval.isEmpty) {
      throw const FormatException('interval_latex manquant');
    }
    final fp = SignX.fromString(json['f_prime']?.toString());
    final fs = SignX.fromString(json['f_second']?.toString());
    if (fp == null || fs == null) {
      throw FormatException('Signes invalides pour l\'intervalle "$interval"');
    }
    final note = json['note'];
    return AnalysisInterval(
      intervalLatex: interval,
      fPrime: fp,
      fSecond: fs,
      note: (note is String && note.isNotEmpty) ? note : null,
    );
  }
}

/// One expected critical / particular point.
class Extremum {
  /// LaTeX of the x value, e.g. "-3".
  final String xLatex;
  final ExtremumType type;

  Extremum({required this.xLatex, required this.type});

  factory Extremum.fromJson(Map<String, dynamic> json) {
    final x = json['x_latex'];
    if (x is! String || x.isEmpty) {
      throw const FormatException('x_latex manquant');
    }
    final type = ExtremumTypeX.fromKey(json['type']?.toString());
    if (type == null) {
      throw FormatException('Type d\'extremum invalide pour x = "$x"');
    }
    return Extremum(xLatex: x, type: type);
  }
}

/// A full function-analysis question.
class FunctionAnalysisQuestion {
  final String id;
  final int difficulty;

  /// Display formula, e.g. "f(x) = x^2 - 4x + 3".
  final String functionLatex;

  /// Expression evaluable by math_expressions, e.g. "x^2 - 4*x + 3".
  final String expression;

  /// Plot window on the x axis.
  final double xMin;
  final double xMax;

  /// Optional explicit y window; when null it is computed from samples.
  final double? yMin;
  final double? yMax;

  final List<AnalysisInterval> intervals;
  final List<Extremum> extrema;

  FunctionAnalysisQuestion({
    required this.id,
    required this.difficulty,
    required this.functionLatex,
    required this.expression,
    required this.xMin,
    required this.xMax,
    this.yMin,
    this.yMax,
    required this.intervals,
    required this.extrema,
  });

  factory FunctionAnalysisQuestion.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Fonction sans "id" valide');
    }
    final functionLatex = json['function_latex'];
    if (functionLatex is! String || functionLatex.isEmpty) {
      throw FormatException('Fonction "$id" sans "function_latex"');
    }
    final expression = json['expression'];
    if (expression is! String || expression.isEmpty) {
      throw FormatException('Fonction "$id" sans "expression"');
    }
    final rawIntervals = json['intervals'];
    if (rawIntervals is! List || rawIntervals.isEmpty) {
      throw FormatException('Fonction "$id" sans "intervals"');
    }

    final intervals = <AnalysisInterval>[];
    for (final e in rawIntervals) {
      if (e is Map<String, dynamic>) {
        intervals.add(AnalysisInterval.fromJson(e));
      }
    }

    final extrema = <Extremum>[];
    final rawExtrema = json['extrema'];
    if (rawExtrema is List) {
      for (final e in rawExtrema) {
        if (e is Map<String, dynamic>) extrema.add(Extremum.fromJson(e));
      }
    }

    final difficultyRaw = json['difficulty'];
    final difficulty =
        difficultyRaw is int ? difficultyRaw : int.tryParse('$difficultyRaw') ?? 1;

    return FunctionAnalysisQuestion(
      id: id,
      difficulty: difficulty.clamp(1, 3),
      functionLatex: functionLatex,
      expression: expression,
      xMin: _toDouble(json['x_min'], -10),
      xMax: _toDouble(json['x_max'], 10),
      yMin: json['y_min'] == null ? null : _toDouble(json['y_min'], 0),
      yMax: json['y_max'] == null ? null : _toDouble(json['y_max'], 0),
      intervals: intervals,
      extrema: extrema,
    );
  }

  static double _toDouble(dynamic v, double fallback) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? fallback;
  }
}

/// Configuration for a Function-analysis session.
class FunctionAnalysisConfig {
  final int difficulty; // 1..3
  final GameMode mode;
  final int? duration; // seconds, for timed mode
  final int? questionCount; // for fixed-questions mode

  FunctionAnalysisConfig({
    required this.difficulty,
    required this.mode,
    this.duration,
    this.questionCount,
  });
}
