import 'package:flutter/material.dart';
import '../services/weight_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final WeightService _weightService = WeightService();
  bool _isLoaded = false;
  Map<String, double> _weights = {};
  double _avgResponseTime = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _weightService.init();
    setState(() {
      _weights = Map.from(_weightService.getAllWeights());
      _avgResponseTime = _weightService.getAverageResponseTime();
      _isLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Debug')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final sortedEntries = _weights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug - Poids'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _confirmReset,
            tooltip: 'Réinitialiser les poids',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCard(),
          Expanded(
            child: _weights.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun poids enregistré.\nJouez quelques parties!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: sortedEntries.length,
                    itemBuilder: (context, index) {
                      final entry = sortedEntries[index];
                      return _buildWeightTile(entry.key, entry.value);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final highWeights = _weights.values.where((w) => w > 1.5).length;
    final lowWeights = _weights.values.where((w) => w < 0.5).length;

    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Paires enregistrées: ${_weights.length}'),
            Text(
              'Temps moyen de réponse: ${(_avgResponseTime / 1000).toStringAsFixed(2)} sec',
            ),
            Text('Poids élevés (> 1.5): $highWeights'),
            Text('Poids faibles (< 0.5): $lowWeights'),
            const SizedBox(height: 8),
            const Text(
              'Légende: Rouge = difficile, Vert = maîtrisé',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightTile(String key, double weight) {
    final parts = key.split('|');
    final a = parts[0];
    final op = parts[1];
    final b = parts[2];

    Color tileColor;
    if (weight >= 2.0) {
      tileColor = Colors.red.shade100;
    } else if (weight >= 1.5) {
      tileColor = Colors.orange.shade100;
    } else if (weight <= 0.3) {
      tileColor = Colors.green.shade100;
    } else if (weight <= 0.7) {
      tileColor = Colors.lightGreen.shade50;
    } else {
      tileColor = Colors.white;
    }

    return Container(
      color: tileColor,
      child: ListTile(
        leading: Text(
          '$a $op $b',
          style: const TextStyle(fontSize: 18, fontFamily: 'monospace'),
        ),
        trailing: Text(
          weight.toStringAsFixed(2),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: weight > 1.5
                ? Colors.red
                : weight < 0.5
                ? Colors.green
                : Colors.black,
          ),
        ),
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser?'),
        content: const Text(
          'Cela supprimera tous les poids enregistrés. '
          'L\'apprentissage recommencera à zéro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await _weightService.resetWeights();
              if (context.mounted) {
                Navigator.pop(context);
              }
              _loadData();
            },
            child: const Text(
              'Réinitialiser',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
