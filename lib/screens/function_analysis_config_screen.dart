import 'package:flutter/material.dart';
import '../models/function_analysis.dart';
import '../models/game_config.dart';
import '../services/function_analysis_loader.dart';
import 'function_analysis_game_screen.dart';

/// Configuration screen for the Function-analysis mode.
class FunctionAnalysisConfigScreen extends StatefulWidget {
  const FunctionAnalysisConfigScreen({super.key});

  @override
  State<FunctionAnalysisConfigScreen> createState() =>
      _FunctionAnalysisConfigScreenState();
}

class _FunctionAnalysisConfigScreenState
    extends State<FunctionAnalysisConfigScreen> {
  final FunctionAnalysisLoader _loader = FunctionAnalysisLoader();

  int _difficulty = 1;
  GameMode _gameMode = GameMode.fixedQuestions;
  int _duration = 180;
  int _questionCount = 5;

  final List<int> _questionOptions = [3, 5, 10];
  final List<int> _durationOptions = [120, 180, 300, 600];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyse de fonction'),
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
          'Analysez la fonction : remplissez le tableau de variation (intervalles, '
          'signe de f′ et f″, allure) et indiquez les extrema. Un clavier '
          'mathématique permet de saisir les intervalles, et vous pouvez afficher '
          'la courbe à tout moment.',
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
    const labels = {1: 'Paraboles', 2: 'Cubiques', 3: 'Avancé'};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [1, 2, 3].map((level) {
            return ChoiceChip(
              label: Text('Niveau $level\n${labels[level]}',
                  textAlign: TextAlign.center),
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
              title: const Text('Nombre de fonctions'),
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
                    final label = '${seconds ~/ 60} min';
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
    final available = await _loader.load(difficulty: _difficulty);
    if (!mounted) return;
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune fonction pour ce niveau pour le moment.'),
        ),
      );
      return;
    }

    final config = FunctionAnalysisConfig(
      difficulty: _difficulty,
      mode: _gameMode,
      duration: _gameMode == GameMode.timed ? _duration : null,
      questionCount:
          _gameMode == GameMode.fixedQuestions ? _questionCount : null,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FunctionAnalysisGameScreen(config: config),
      ),
    );
  }
}
