import 'package:flutter/material.dart';
import '../models/algebra_config.dart';
import '../models/algebra_question.dart';
import '../models/game_config.dart';
import '../services/question_loader.dart';
import 'algebra_game_screen.dart';

/// Question-type filter for the Intégrales mode.
///
/// - [resultat] : compute the antiderivative (choose the correct result).
/// - [methode]  : identify the integration technique.
enum IntegralesTypeFilter { resultat, methode, both }

extension on IntegralesTypeFilter {
  String get label {
    switch (this) {
      case IntegralesTypeFilter.resultat:
        return 'Résultat';
      case IntegralesTypeFilter.methode:
        return 'Méthode';
      case IntegralesTypeFilter.both:
        return 'Les deux';
    }
  }

  /// Maps to the config type filter (null = all types).
  List<AlgebraQuestionType>? get types {
    switch (this) {
      case IntegralesTypeFilter.resultat:
        return [AlgebraQuestionType.qcmResultat];
      case IntegralesTypeFilter.methode:
        return [AlgebraQuestionType.qcmMethode];
      case IntegralesTypeFilter.both:
        return null;
    }
  }
}

/// Configuration screen for the Intégrales mode. Reuses [AlgebraGameScreen] for
/// gameplay; here we only choose difficulty, question type, mode and options.
class IntegralesConfigScreen extends StatefulWidget {
  const IntegralesConfigScreen({super.key});

  @override
  State<IntegralesConfigScreen> createState() => _IntegralesConfigScreenState();
}

class _IntegralesConfigScreenState extends State<IntegralesConfigScreen> {
  final QuestionLoader _loader = QuestionLoader();

  int _difficulty = 1;
  IntegralesTypeFilter _typeFilter = IntegralesTypeFilter.both;
  GameMode _gameMode = GameMode.fixedQuestions;
  int _duration = 60;
  int _questionCount = 10;
  bool _showImmediateFeedback = true;
  bool _pauseOnError = false;

  final List<int> _questionOptions = [5, 10, 20, 50];
  final List<int> _durationOptions = [30, 60, 120, 180, 300];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intégrales'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Type de question'),
            const SizedBox(height: 8),
            _buildTypeSection(),
            const SizedBox(height: 24),
            _buildSectionTitle('Niveau de difficulté'),
            const SizedBox(height: 8),
            _buildDifficultySection(),
            const SizedBox(height: 24),
            _buildSectionTitle('Mode de jeu'),
            const SizedBox(height: 8),
            _buildGameModeSection(),
            const SizedBox(height: 24),
            _buildSectionTitle('Options'),
            const SizedBox(height: 8),
            _buildOptionsSection(),
            const SizedBox(height: 32),
            _buildStartButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: IntegralesTypeFilter.values.map((t) {
                return ChoiceChip(
                  label: Text(t.label),
                  selected: _typeFilter == t,
                  onSelected: (selected) {
                    if (selected) setState(() => _typeFilter = t);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              _typeFilter == IntegralesTypeFilter.methode
                  ? 'Identifier la technique d\'intégration à utiliser.'
                  : _typeFilter == IntegralesTypeFilter.resultat
                      ? 'Choisir la primitive (le résultat de l\'intégrale).'
                      : 'Mélange de primitives et de techniques.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [1, 2, 3].map((level) {
            return ChoiceChip(
              label: Text('Niveau $level'),
              selected: _difficulty == level,
              onSelected: (selected) {
                if (selected) setState(() => _difficulty = level);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGameModeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            RadioListTile<GameMode>(
              title: const Text('Nombre de questions'),
              value: GameMode.fixedQuestions,
              groupValue: _gameMode,
              onChanged: (value) => setState(() => _gameMode = value!),
            ),
            if (_gameMode == GameMode.fixedQuestions)
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Wrap(
                  spacing: 8,
                  children: _questionOptions.map((count) {
                    return ChoiceChip(
                      label: Text('$count'),
                      selected: _questionCount == count,
                      onSelected: (selected) {
                        if (selected) setState(() => _questionCount = count);
                      },
                    );
                  }).toList(),
                ),
              ),
            const Divider(),
            RadioListTile<GameMode>(
              title: const Text('Contre-la-montre'),
              value: GameMode.timed,
              groupValue: _gameMode,
              onChanged: (value) => setState(() => _gameMode = value!),
            ),
            if (_gameMode == GameMode.timed)
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Wrap(
                  spacing: 8,
                  children: _durationOptions.map((seconds) {
                    final label =
                        seconds >= 60 ? '${seconds ~/ 60} min' : '$seconds sec';
                    return ChoiceChip(
                      label: Text(label),
                      selected: _duration == seconds,
                      onSelected: (selected) {
                        if (selected) setState(() => _duration = seconds);
                      },
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Afficher la réponse immédiatement'),
            subtitle: const Text(
              'Voir la bonne réponse et l\'astuce après chaque question',
            ),
            value: _showImmediateFeedback,
            onChanged: (value) => setState(() {
              _showImmediateFeedback = value;
              if (!value) _pauseOnError = false;
            }),
          ),
          if (_showImmediateFeedback) ...[
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Pause après une erreur'),
              subtitle: const Text(
                'Attendre « Continuer » pour lire la bonne réponse',
              ),
              value: _pauseOnError,
              onChanged: (value) => setState(() => _pauseOnError = value),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton(
      onPressed: _startGame,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      child: const Text('Commencer', style: TextStyle(fontSize: 20)),
    );
  }

  Future<void> _startGame() async {
    final types = _typeFilter.types;

    final available = await _loader.load(
      categories: integralesCategories,
      difficulty: _difficulty,
      types: types,
    );
    if (!mounted) return;
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aucune question pour ce niveau et ce type. Essayez une autre combinaison.',
          ),
        ),
      );
      return;
    }

    final config = AlgebraConfig(
      categories: integralesCategories,
      types: types,
      difficulty: _difficulty,
      mode: _gameMode,
      duration: _gameMode == GameMode.timed ? _duration : null,
      questionCount:
          _gameMode == GameMode.fixedQuestions ? _questionCount : null,
      showImmediateFeedback: _showImmediateFeedback,
      pauseOnError: _pauseOnError,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AlgebraGameScreen(config: config),
      ),
    );
  }
}
