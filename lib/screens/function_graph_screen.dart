import 'package:flutter/material.dart';
import '../models/function_analysis.dart';
import '../widgets/function_plot.dart';
import '../widgets/math_text.dart';

/// Full-screen view of the function's graph. Pushed from the analysis screen
/// and dismissed (returning to the answer screen) via the AppBar back button
/// or the explicit "Retour aux réponses" button.
class FunctionGraphScreen extends StatelessWidget {
  final FunctionAnalysisQuestion question;

  const FunctionGraphScreen({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courbe de la fonction'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 50,
                    child: Center(
                      child: MathText(question.functionLatex, fontSize: 26),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: FunctionPlot(
                    expression: question.expression,
                    xMin: question.xMin,
                    xMax: question.xMax,
                    yMin: question.yMin,
                    yMax: question.yMax,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour aux réponses',
                      style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
