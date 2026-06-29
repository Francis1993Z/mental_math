import 'package:flutter/material.dart';

/// Simple end-of-session summary for the Function-analysis mode.
class FunctionAnalysisResultScreen extends StatelessWidget {
  final int correct;
  final int total;
  final int totalTimeSeconds;

  const FunctionAnalysisResultScreen({
    super.key,
    required this.correct,
    required this.total,
    required this.totalTimeSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (correct / total * 100).round();
    final minutes = totalTimeSeconds ~/ 60;
    final seconds = totalTimeSeconds % 60;
    final timeLabel =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final Color accent = pct >= 70
        ? Colors.green
        : pct >= 40
            ? Colors.orange
            : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                pct >= 70 ? Icons.emoji_events : Icons.insights,
                size: 88,
                color: accent,
              ),
              const SizedBox(height: 16),
              Text(
                '$correct / $total',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: accent),
              ),
              const SizedBox(height: 8),
              Text(
                'Fonctions correctement analysées ($pct%)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text('Temps total : $timeLabel',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.home),
                label: const Text('Retour à l\'accueil'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
