// lib/presentation/widgets/navigation/app_scaffold.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/presentation/blocs/unread/unread_cubit.dart';
import 'package:provider/provider.dart';

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
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.explore),
          label: LocalizationService.translate('navigation.discovery'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.favorite),
          label: LocalizationService.translate('navigation.matches'),
        ),
        BottomNavigationBarItem(
          icon: _MessagesTabIcon(unreadCount: _watchUnreadCount(context)),
          label: LocalizationService.translate('navigation.messages'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: LocalizationService.translate('navigation.profile'),
        ),
      ],
    );
  }

  /// Lit le compteur global de non-lus, sans planter si `UnreadCubit` n'est
  /// pas fourni dans l'arbre (ex: pages testées isolément) — le badge est
  /// alors simplement absent plutôt que de faire échouer tout l'écran.
  int _watchUnreadCount(BuildContext context) {
    try {
      return context.watch<UnreadCubit>().state;
    } on ProviderNotFoundException {
      return 0;
    }
  }
}

/// Icône de l'onglet Messages avec pastille de compteur non-lus.
class _MessagesTabIcon extends StatelessWidget {
  final int unreadCount;

  const _MessagesTabIcon({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    if (unreadCount <= 0) {
      return const Icon(Icons.chat);
    }
    final label = unreadCount > 99 ? '99+' : '$unreadCount';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.chat),
        Positioned(
          right: -8,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
