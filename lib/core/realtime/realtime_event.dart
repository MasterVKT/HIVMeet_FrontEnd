// lib/core/realtime/realtime_event.dart

/// Types d'événements temps réel diffusés sur [RealtimeEventBus].
///
/// Ce vocabulaire est intentionnellement aligné sur les `type` de payload
/// FCM utilisés par `NotificationService._typeFromData` et sur les `type`
/// émis par `UserNotificationConsumer` côté backend, afin qu'un seul mapping
/// serve les deux sources.
enum RealtimeEventType {
  newMessage,
  newMatch,
  likeReceived,
  superLikeReceived,
  messageRead,
  messageDelivered,

  /// Émis localement (jamais reçu du réseau) quand l'utilisateur courant
  /// marque une conversation comme lue, pour rafraîchir le badge sans
  /// attendre un aller-retour serveur.
  conversationRead,

  /// Émis localement au retour au premier plan de l'application, pour
  /// déclencher une réconciliation silencieuse (filet de sécurité si des
  /// événements ont été manqués pendant que l'app était en arrière-plan).
  appResumed,
}

/// Origine d'un [RealtimeEvent] — utile pour le diagnostic et pour éviter
/// de dédupliquer des événements qui n'ont pas de `conversationId` commun.
enum RealtimeSource { websocket, fcm, local }

/// Événement temps réel normalisé, indépendant de la source qui l'a produit.
class RealtimeEvent {
  final RealtimeEventType type;
  final RealtimeSource source;

  /// Identifiant de conversation concerné, quand applicable
  /// (newMessage, messageRead, conversationRead).
  final String? conversationId;

  /// Identifiant de l'utilisateur à l'origine de l'événement, quand connu.
  final String? fromUserId;

  /// Aperçu texte du message, quand applicable (newMessage).
  final String? preview;

  /// Identifiant de match, quand applicable (newMatch).
  final String? matchId;

  /// Identifiant du message, quand applicable (newMessage, messageDelivered).
  /// Utilisé pour resserrer la déduplication quand deux sources (WS + FCM)
  /// livrent le même message à quelques secondes d'intervalle.
  final String? messageId;

  /// Identifiant stable de la notification quand la source le fournit.
  /// Il permet de conserver une seule notification in-app lorsqu'un même
  /// événement est livré par FCM et par le WebSocket.
  final String? notificationId;

  const RealtimeEvent({
    required this.type,
    required this.source,
    this.conversationId,
    this.fromUserId,
    this.preview,
    this.matchId,
    this.messageId,
    this.notificationId,
  });

  @override
  String toString() =>
      'RealtimeEvent(type: $type, source: $source, conversationId: $conversationId, messageId: $messageId)';
}
