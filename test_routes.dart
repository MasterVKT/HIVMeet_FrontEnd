import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hivmeet/core/config/routes.dart';

/// Test simple pour vérifier que toutes les routes sont accessibles
void main() {
  runApp(const RouteTestApp());
}

class RouteTestApp extends StatelessWidget {
  const RouteTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Test Routes HIVMeet',
      routerConfig: AppRouter.router,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
    );
  }
}

class RouteTestPage extends StatelessWidget {
  const RouteTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test des Routes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Routes disponibles :',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildRouteButton(context, 'Discovery', '/discovery'),
          _buildRouteButton(context, 'Matches', '/matches'),
          _buildRouteButton(context, 'Conversations', '/conversations'),
          _buildRouteButton(context, 'Chat', '/chat'),
          _buildRouteButton(context, 'Feed', '/feed'),
          _buildRouteButton(context, 'Resources', '/resources'),
          _buildRouteButton(context, 'Settings', '/settings'),
          _buildRouteButton(context, 'Premium', '/premium'),
          _buildRouteButton(context, 'Verification', '/verification'),
          _buildRouteButton(context, 'About', '/about'),
          _buildRouteButton(context, 'Privacy', '/privacy'),
          _buildRouteButton(context, 'Terms', '/terms'),
        ],
      ),
    );
  }

  Widget _buildRouteButton(BuildContext context, String label, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: () => context.go(route),
        child: Text('Aller à $label'),
      ),
    );
  }
}
