/// Categories available across the LaTeX-based game modes.
enum AlgebraCategory {
  trigo,
  algebra,
  log,
  exp,
  derivative,
  limites,
  integrales,
  ensembles,
}

/// Categories that belong to the "Algebre & Trigo" mode.
const List<AlgebraCategory> algebraTrigoCategories = [
  AlgebraCategory.trigo,
  AlgebraCategory.algebra,
  AlgebraCategory.log,
  AlgebraCategory.exp,
  AlgebraCategory.derivative,
];

/// Categories that belong to the "Limites" mode.
const List<AlgebraCategory> limitesCategories = [AlgebraCategory.limites];

/// Categories that belong to the "Intégrales" mode.
const List<AlgebraCategory> integralesCategories = [AlgebraCategory.integrales];

/// Categories that belong to the "Ensembles de nombres" mode.
const List<AlgebraCategory> ensemblesCategories = [AlgebraCategory.ensembles];

extension AlgebraCategoryX on AlgebraCategory {
  /// The key used in questions.json.
  String get key {
    switch (this) {
      case AlgebraCategory.trigo:
        return 'trigo';
      case AlgebraCategory.algebra:
        return 'algebra';
      case AlgebraCategory.log:
        return 'log';
      case AlgebraCategory.exp:
        return 'exp';
      case AlgebraCategory.derivative:
        return 'derivative';
      case AlgebraCategory.limites:
        return 'limites';
      case AlgebraCategory.integrales:
        return 'integrales';
      case AlgebraCategory.ensembles:
        return 'ensembles';
    }
  }

  /// Human readable label (French) for the UI.
  String get label {
    switch (this) {
      case AlgebraCategory.trigo:
        return 'Identités trigo';
      case AlgebraCategory.algebra:
        return 'Identités remarquables';
      case AlgebraCategory.log:
        return 'Logarithmes';
      case AlgebraCategory.exp:
        return 'Exponentielle / e';
      case AlgebraCategory.derivative:
        return 'Dérivées de base';
      case AlgebraCategory.limites:
        return 'Limites';
      case AlgebraCategory.integrales:
        return 'Intégrales';
      case AlgebraCategory.ensembles:
        return 'Ensembles de nombres';
    }
  }

  static AlgebraCategory? fromKey(String key) {
    for (final c in AlgebraCategory.values) {
      if (c.key == key) return c;
    }
    return null;
  }
}

/// Question type:
/// - [qcm]: generic multiple choice
/// - [complete]: complete the right-hand side of an identity
/// - [qcmResultat]: Limites mode, choose the value of the limit
/// - [qcmMethode]: Limites mode, identify the indeterminate form / technique
enum AlgebraQuestionType { qcm, complete, qcmResultat, qcmMethode }

AlgebraQuestionType _typeFromString(String? value) {
  switch (value) {
    case 'complete':
      return AlgebraQuestionType.complete;
    case 'qcm_resultat':
      return AlgebraQuestionType.qcmResultat;
    case 'qcm_methode':
      return AlgebraQuestionType.qcmMethode;
    default:
      return AlgebraQuestionType.qcm;
  }
}

/// A single formula-recognition question stored as LaTeX strings.
class AlgebraQuestion {
  final String id;
  final AlgebraCategory category;
  final int difficulty;
  final AlgebraQuestionType type;
  final String promptLatex;
  final String answerLatex;
  final List<String> choicesLatex;

  /// Optional enriched feedback (e.g. indeterminate form + technique).
  /// Shown after answering when present. Mainly used by the Limites mode.
  final String? hintLatex;

  // Runtime answer tracking (mirrors the numeric Question model).
  int? selectedIndex;
  bool? isCorrect;
  int? responseTimeMs;

  AlgebraQuestion({
    required this.id,
    required this.category,
    required this.difficulty,
    required this.type,
    required this.promptLatex,
    required this.answerLatex,
    required this.choicesLatex,
    this.hintLatex,
  });

  /// Index of the correct choice within [choicesLatex].
  int get correctIndex {
    final i = choicesLatex.indexOf(answerLatex);
    return i >= 0 ? i : 0;
  }

  void answer(int index, {int? timeMs}) {
    selectedIndex = index;
    isCorrect = index == correctIndex;
    responseTimeMs = timeMs;
  }

  /// Parses a single entry. Throws [FormatException] if required fields are
  /// missing or malformed so the loader can skip bad entries gracefully.
  factory AlgebraQuestion.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final categoryKey = json['category'];
    final promptLatex = json['prompt_latex'];
    final answerLatex = json['answer_latex'];
    final rawChoices = json['choices_latex'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Question manque un "id" valide');
    }
    final category = AlgebraCategoryX.fromKey(categoryKey is String ? categoryKey : '');
    if (category == null) {
      throw FormatException('Catégorie inconnue pour la question "$id"');
    }
    if (promptLatex is! String || promptLatex.isEmpty) {
      throw FormatException('Question "$id" manque "prompt_latex"');
    }
    if (answerLatex is! String || answerLatex.isEmpty) {
      throw FormatException('Question "$id" manque "answer_latex"');
    }
    if (rawChoices is! List || rawChoices.isEmpty) {
      throw FormatException('Question "$id" manque "choices_latex"');
    }

    final choices = rawChoices.map((e) => e.toString()).toList();
    if (!choices.contains(answerLatex)) {
      throw FormatException(
        'Question "$id": la bonne réponse n\'est pas dans "choices_latex"',
      );
    }

    final difficultyRaw = json['difficulty'];
    final difficulty = difficultyRaw is int
        ? difficultyRaw
        : int.tryParse('$difficultyRaw') ?? 1;

    final hintRaw = json['hint_latex'];
    final hint = (hintRaw is String && hintRaw.isNotEmpty) ? hintRaw : null;

    return AlgebraQuestion(
      id: id,
      category: category,
      difficulty: difficulty.clamp(1, 3),
      type: _typeFromString(json['type'] as String?),
      promptLatex: promptLatex,
      answerLatex: answerLatex,
      choicesLatex: choices,
      hintLatex: hint,
    );
  }
}
