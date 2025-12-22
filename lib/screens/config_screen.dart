import 'package:flutter/material.dart';
import '../models/game_config.dart';
import 'debug_screen.dart';
import 'game_screen.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();

  int _minValue = 1;
  int _maxValue = 10;
  final Map<String, bool> _operators = {
    '+': true,
    '−': false,
    '×': false,
    '÷': false,
  };
  GameMode _gameMode = GameMode.fixedQuestions;
  int _duration = 60;
  int _questionCount = 10;
  bool _showImmediateFeedback = true;

  final List<int> _questionOptions = [5, 10, 20, 50, 100];
  final List<int> _durationOptions = [30, 60, 120, 180, 300];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: _openDebugScreen,
          child: const Text('Calcul Mental'),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).padding.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Plage de nombres'),
              const SizedBox(height: 8),
              _buildNumberRangeSection(),
              const SizedBox(height: 24),
              _buildSectionTitle('Opérations'),
              const SizedBox(height: 8),
              _buildOperatorsSection(),
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

  Widget _buildNumberRangeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _minValue.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minimum',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Requis';
                  }
                  final num = int.tryParse(value);
                  if (num == null) {
                    return 'Nombre invalide';
                  }
                  return null;
                },
                onChanged: (value) {
                  final num = int.tryParse(value);
                  if (num != null) {
                    setState(() => _minValue = num);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            const Text('à', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: _maxValue.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Maximum',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Requis';
                  }
                  final num = int.tryParse(value);
                  if (num == null) {
                    return 'Nombre invalide';
                  }
                  if (num < _minValue) {
                    return 'Doit être ≥ min';
                  }
                  return null;
                },
                onChanged: (value) {
                  final num = int.tryParse(value);
                  if (num != null) {
                    setState(() => _maxValue = num);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 8,
          children: _operators.keys.map((op) {
            return FilterChip(
              label: Text(op, style: const TextStyle(fontSize: 20)),
              selected: _operators[op]!,
              onSelected: (selected) {
                setState(() {
                  _operators[op] = selected;
                });
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
              onChanged: (value) {
                setState(() => _gameMode = value!);
              },
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
                        if (selected) {
                          setState(() => _questionCount = count);
                        }
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
              onChanged: (value) {
                setState(() => _gameMode = value!);
              },
            ),
            if (_gameMode == GameMode.timed)
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Wrap(
                  spacing: 8,
                  children: _durationOptions.map((seconds) {
                    final label = seconds >= 60
                        ? '${seconds ~/ 60} min'
                        : '$seconds sec';
                    return ChoiceChip(
                      label: Text(label),
                      selected: _duration == seconds,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _duration = seconds);
                        }
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
      child: SwitchListTile(
        title: const Text('Afficher la réponse immédiatement'),
        subtitle: const Text(
          'Voir si la réponse est correcte après chaque question',
        ),
        value: _showImmediateFeedback,
        onChanged: (value) {
          setState(() => _showImmediateFeedback = value);
        },
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

  void _startGame() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedOperators = _operators.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedOperators.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins une opération')),
      );
      return;
    }

    final config = GameConfig(
      minValue: _minValue,
      maxValue: _maxValue,
      operators: selectedOperators,
      mode: _gameMode,
      duration: _gameMode == GameMode.timed ? _duration : null,
      questionCount: _gameMode == GameMode.fixedQuestions
          ? _questionCount
          : null,
      showImmediateFeedback: _showImmediateFeedback,
    );

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => GameScreen(config: config)));
  }

  void _openDebugScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const DebugScreen()));
  }
}
