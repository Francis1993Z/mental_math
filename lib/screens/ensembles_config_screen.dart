import 'package:flutter/material.dart';
import '../models/algebra_config.dart';
import '../models/algebra_question.dart';
import '../models/game_config.dart';
import '../services/question_loader.dart';
import 'algebra_game_screen.dart';

/// Configuration screen for the "Ensembles de nombres" mode. Reuses
/// [AlgebraGameScreen] for gameplay; here we only choose difficulty, game mode
/// and options. The student is shown a number and must pick the SMALLEST set
/// it belongs to.
class EnsemblesConfigScreen extends StatefulWidget {
  const EnsemblesConfigScreen({super.key});

  @override
  State<EnsemblesConfigScreen> createState() => _EnsemblesConfigScreenState();
}

class _EnsemblesConfigScreenState extends State<EnsemblesConfigScreen> {
  final QuestionLoader _loader = QuestionLoader();

  int _difficulty = 1;
  GameMode _gameMode = GameMode.fixedQuestions;
  int _duration = 60;
  int _questionCount = 10;
  bool _showImmediateFeedback = true;
  bool _pauseOnError = false;

  final List<int> _questionOptions = [5, 10, 20, 50];
  final List<int> _durationOptions = [30, 60, 120, 180, 300];

  static const Map<int, String> _difficultyLabels = {
    1: '\u2115, \u2124, \u211a',
    2: '+ irrationnels',
    3: '+ complexes',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ensembles de nombres'),
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
            _buildIntro(),
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

  Widget _buildIntro() {
    return Card(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'On vous montre un nombre. Choisissez le plus petit ensemble qui le '
          'contient :\n'
          '\u2115 \u2282 \u2124 \u2282 \u211a \u2282 \u211d \u2282 \u2102.\n\n'
          'Astuce : les irrationnels (\u221a2, \u03c0, e, \u2026) sont des réels '
          'qui ne sont pas rationnels. « Réel » n\'est donc presque jamais la '
          'réponse la plus précise.',
          style: TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
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
              label: Text(
                'Niveau $level\n${_difficultyLabels[level]}',
                textAlign: TextAlign.center,
              ),
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
    final available = await _loader.load(
      categories: ensemblesCategories,
      difficulty: _difficulty,
    );
    if (!mounted) return;
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune question pour ce niveau pour le moment.'),
        ),
      );
      return;
    }

    final config = AlgebraConfig(
      categories: ensemblesCategories,
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
