import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Test de navigation pour vérifier que toutes les routes fonctionnent
class NavigationTest extends StatelessWidget {
  const NavigationTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Navigation'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Test de Navigation HIVMeet',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            'Cliquez sur les boutons pour tester la navigation :',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),

          // Routes principales
          _buildSectionTitle('Routes Principales'),
          _buildNavigationButton(context, 'Discovery', '/discovery'),
          _buildNavigationButton(context, 'Matches', '/matches'),
          _buildNavigationButton(context, 'Conversations', '/conversations'),
          _buildNavigationButton(context, 'Profile', '/profile'),

          const SizedBox(height: 20),

          // Routes de fonctionnalités
          _buildSectionTitle('Fonctionnalités'),
          _buildNavigationButton(context, 'Settings', '/settings'),
          _buildNavigationButton(context, 'Premium', '/premium'),
          _buildNavigationButton(context, 'Resources', '/resources'),
          _buildNavigationButton(context, 'Feed', '/feed'),

          const SizedBox(height: 20),

          // Routes légales
          _buildSectionTitle('Pages Légales'),
          _buildNavigationButton(context, 'About', '/about'),
          _buildNavigationButton(context, 'Privacy', '/privacy'),
          _buildNavigationButton(context, 'Terms', '/terms'),

          const SizedBox(height: 20),

          // Test d'erreur
          _buildSectionTitle('Test d\'Erreur'),
          _buildNavigationButton(
              context, 'Route Inexistante', '/route-inexistante'),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.purple,
        ),
      ),
    );
  }

  Widget _buildNavigationButton(
      BuildContext context, String label, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: () {
          try {
            context.go(route);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur de navigation: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        child: Text('Aller à $label'),
      ),
    );
  }
}

/// Widget pour tester la navigation depuis n'importe quelle page
class NavigationTestWidget extends StatelessWidget {
  const NavigationTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Test de Navigation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildQuickButton(context, 'Discovery', '/discovery'),
            _buildQuickButton(context, 'Matches', '/matches'),
            _buildQuickButton(context, 'Profile', '/profile'),
            _buildQuickButton(context, 'Settings', '/settings'),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickButton(BuildContext context, String label, String route) {
    return ElevatedButton(
      onPressed: () => context.go(route),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label),
    );
  }
}
