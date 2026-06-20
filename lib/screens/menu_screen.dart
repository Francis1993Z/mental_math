import 'package:flutter/material.dart';
import 'algebra_config_screen.dart';
import 'config_screen.dart';
import 'debug_screen.dart';
import 'limites_config_screen.dart';

/// Home menu that lets the player choose between the two game modes:
/// the existing arithmetic "Calcul Mental" and the new "Algèbre & Trigo".
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                'Choisissez un mode',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              _ModeCard(
                icon: Icons.calculate,
                title: 'Calcul Mental',
                subtitle: 'Addition, soustraction, multiplication, division',
                color: Colors.blue,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ConfigScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _ModeCard(
                icon: Icons.functions,
                title: 'Algèbre & Trigo',
                subtitle: 'Reconnaissance de formules et identités',
                color: Colors.deepPurple,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AlgebraConfigScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _ModeCard(
                icon: Icons.trending_down,
                title: 'Limites',
                subtitle: 'Formes indéterminées, techniques et résultats',
                color: Colors.teal,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LimitesConfigScreen()),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
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
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, size: 30, color: color),
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
