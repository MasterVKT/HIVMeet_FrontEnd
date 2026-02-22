// lib/core/events/app_events.dart

import 'dart:async';

/// Service de gestion des événements globaux de l'application
/// Permet la communication entre BLoCs sans créer de dépendances circulaires
class AppEvents {
  static final AppEvents _instance = AppEvents._internal();
  factory AppEvents() => _instance;
  AppEvents._internal();

  final _interactionRevokedController = StreamController<String>.broadcast();

  /// Stream émis quand une interaction (like ou pass) est annulée
  /// Contient l'ID du profil qui doit réapparaître dans la découverte
  Stream<String> get onInteractionRevoked =>
      _interactionRevokedController.stream;

  /// Émettre un événement d'annulation d'interaction
  void notifyInteractionRevoked(String profileId) {
    print('📢 AppEvents: Interaction révoquée pour profil $profileId');
    _interactionRevokedController.add(profileId);
  }

  /// Nettoyer les ressources
  void dispose() {
    _interactionRevokedController.close();
  }
}
