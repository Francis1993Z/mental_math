import 'package:flutter/material.dart';
import 'algebra_config_screen.dart';
import 'config_screen.dart';
import 'debug_screen.dart';
import 'ensembles_config_screen.dart';
import 'function_analysis_config_screen.dart';
import 'integrales_config_screen.dart';
import 'limites_config_screen.dart';

/// Home menu that lets the player choose between the available game modes.
///
/// The content is vertically centered when it fits, but becomes scrollable on
/// short screens so every mode card remains reachable.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () => _openDebug(context),
          child: const Text('Math Trainer'),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Choisissez un mode',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    _ModeCard(
                      icon: Icons.calculate,
                      title: 'Calcul Mental',
                      subtitle:
                          'Addition, soustraction, multiplication, division',
                      color: Colors.blue,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ConfigScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ModeCard(
                      icon: Icons.functions,
                      title: 'Algèbre & Trigo',
                      subtitle: 'Reconnaissance de formules et identités',
                      color: Colors.deepPurple,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AlgebraConfigScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ModeCard(
                      icon: Icons.trending_down,
                      title: 'Limites',
                      subtitle: 'Formes indéterminées, techniques et résultats',
                      color: Colors.teal,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LimitesConfigScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ModeCard(
                      icon: Icons.integration_instructions,
                      title: 'Intégrales',
                      subtitle: 'Primitives et techniques d\'intégration',
                      color: Colors.orange,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const IntegralesConfigScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ModeCard(
                      icon: Icons.area_chart,
                      title: 'Analyse de fonction',
                      subtitle:
                          'Tableau de variation, concavité, allure et extrema',
                      color: Colors.indigo,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FunctionAnalysisConfigScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ModeCard(
                      icon: Icons.numbers,
                      title: 'Ensembles de nombres',
                      subtitle: 'ℕ, ℤ, ℚ, irrationnels, ℝ, ℂ : classez le nombre',
                      color: Colors.pink,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EnsemblesConfigScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openDebug(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DebugScreen()),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, size: 26, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
