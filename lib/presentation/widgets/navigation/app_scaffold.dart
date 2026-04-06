// lib/presentation/widgets/navigation/app_scaffold.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const bool _enableVerboseLogs = false;

void _debugLog(Object? message) {
  if (_enableVerboseLogs) {
    debugPrint(message?.toString());
  }
}

/// Scaffold principal de l'application avec bottom navigation bar centralisee
///
/// Ce widget centralise le bottom navigation bar pour eviter la duplication
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
    // Eviter de naviguer si deja sur l'onglet
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
    _debugLog(
        'DEBUG AppScaffold: build() appele - currentIndex: $currentIndex');
    return Scaffold(
      backgroundColor: Colors.white,
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
          label: 'Decouvrir',
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
