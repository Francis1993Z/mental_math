import 'package:flutter/material.dart';
import '../models/game_result.dart';
import '../models/question.dart';

class ResultScreen extends StatelessWidget {
  final GameResult result;

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildScoreCard(context),
            const SizedBox(height: 24),
            _buildStatsCard(context),
            if (result.incorrectQuestions.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildErrorsSection(context),
            ],
            const SizedBox(height: 32),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context) {
    final isGood = result.accuracy >= 70;
    final isExcellent = result.accuracy >= 90;

    return Card(
      color: isExcellent
          ? Colors.green.shade100
          : isGood
          ? Colors.orange.shade100
          : Colors.red.shade100,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              isExcellent
                  ? Icons.emoji_events
                  : isGood
                  ? Icons.thumb_up
                  : Icons.trending_up,
              size: 64,
              color: isExcellent
                  ? Colors.amber
                  : isGood
                  ? Colors.orange
                  : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              '${result.correctCount}/${result.totalCount}',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            Text(
              '${result.accuracy.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 24, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatRow(
              Icons.timer,
              'Temps total',
              _formatTime(result.totalTime),
            ),
            const Divider(),
            _buildStatRow(
              Icons.speed,
              'Temps moyen/question',
              '${result.averageTimePerQuestion.toStringAsFixed(1)} sec',
            ),
            const Divider(),
            _buildStatRow(
              Icons.check_circle,
              'Bonnes réponses',
              '${result.correctCount}',
            ),
            const Divider(),
            _buildStatRow(
              Icons.cancel,
              'Mauvaises réponses',
              '${result.totalCount - result.correctCount}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Erreurs à revoir',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: result.incorrectQuestions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final q = result.incorrectQuestions[index];
              return _buildErrorTile(q);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorTile(Question q) {
    return ListTile(
      leading: const Icon(Icons.close, color: Colors.red),
      title: Text(
        '${q.a} ${q.operator} ${q.b} = ${q.correctAnswer}',
        style: const TextStyle(fontSize: 18),
      ),
      subtitle: Text(
        'Votre réponse: ${q.userAnswer}',
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          icon: const Icon(Icons.home),
          label: const Text('Retour à l\'accueil'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes min ${secs.toString().padLeft(2, '0')} sec';
    }
    return '$secs sec';
  }
}
