// lib/presentation/widgets/navigation/app_scaffold.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Scaffold principal de l'application avec bottom navigation bar centralisée
///
/// Ce widget centralise le bottom navigation bar pour éviter la duplication
/// de code sur chaque page. Toutes les pages principales (Discovery, Matches,
/// Messages, Profil) doivent utiliser ce scaffold.
///
/// Features:
/// - Bottom navigation bar avec 4 onglets
/// - Gestion automatique de l'onglet actif via currentIndex
/// - Navigation via go_router
/// - AppBar personnalisable par page
///
/// Exemple:
/// ```dart
/// AppScaffold(
///   currentIndex: 1, // Matches tab
///   body: MatchesPageContent(),
///   appBar: AppBar(title: Text('Matches')),
/// )
/// ```
class AppScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const AppScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  void _onNavigationTap(BuildContext context, int index) {
    // Éviter de naviguer si déjà sur l'onglet
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        context.go('/discovery');
        break;
      case 1:
        context.go('/matches');
        break;
      case 2:
        context.go('/conversations');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) => _onNavigationTap(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: 'Découvrir',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Matches',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }
}
