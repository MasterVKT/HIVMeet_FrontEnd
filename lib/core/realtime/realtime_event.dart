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
  matchRemoved,
  likeReceived,
  superLikeReceived,
  subscriptionExpiring,
  reportResolved,
  messageRead,
  messageReadAlert,
  messageDelivered,

  /// Émis localement (jamais reçu du réseau) quand l'utilisateur courant
  /// marque une conversation comme lue, pour rafraîchir le badge sans
  /// attendre un aller-retour serveur.
  conversationRead,

  /// Émis localement lorsqu'une conversation est masquée ou que son
  /// masquage optimiste est annulé. Le badge Messages applique d'abord le
  /// delta fourni puis relit le total serveur.
  conversationHidden,

  /// Local restoration of a previously hidden conversation.
  conversationRestored,

  /// Émis localement au retour au premier plan de l'application, pour
  /// déclencher une réconciliation silencieuse (filet de sécurité si des
  /// événements ont été manqués pendant que l'app était en arrière-plan).
  appResumed,

  /// Émis localement après confirmation et rechargement serveur des droits.
  subscriptionChanged,
}

/// Origine d'un [RealtimeEvent] — utile pour le diagnostic et pour éviter
/// de dédupliquer des événements qui n'ont pas de `conversationId` commun.
enum RealtimeSource { websocket, fcm, local }

/// Événement temps réel normalisé, indépendant de la source qui l'a produit.
class RealtimeEvent {
  final RealtimeEventType type;
  final RealtimeSource source;

  /// Identifiant de conversation concerné, quand applicable
  /// (newMessage, messageRead, conversationRead, conversationHidden).
  final String? conversationId;

  /// Variation locale du nombre de messages non lus pour
  /// [RealtimeEventType.conversationHidden]. Une valeur négative retire les
  /// messages de la conversation masquée; une valeur positive restaure le
  /// badge si la requête de masquage échoue.
  final int? unreadCountDelta;

  /// Identifiant de l'utilisateur à l'origine de l'événement, quand connu.
  final String? fromUserId;

  /// Aperçu texte du message, quand applicable (newMessage).
  final String? preview;

  /// Sender name only when the server permits a private message preview.
  final String? senderName;

  /// Display name of the reader for a persisted Premium read alert.
  final String? readerName;

  /// Number of messages confirmed as read in that alert batch.
  final int? messageCount;

  /// Read timestamp supplied by the persisted alert, in ISO-8601 form.
  final String? readAt;

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

  /// Nombre de jours avant expiration (subscriptionExpiring).
  final int? daysRemaining;

  /// Date d'expiration au format ISO (subscriptionExpiring).
  final String? expiryDate;

  /// ID du signalement (reportResolved).
  final String? reportId;

  /// Statut de résolution du signalement: 'resolved' ou 'dismissed'.
  final String? reportStatus;

  /// Résumé de la décision prise pour le signalement.
  final String? resolutionSummary;

  const RealtimeEvent({
    required this.type,
    required this.source,
    this.conversationId,
    this.unreadCountDelta,
    this.fromUserId,
    this.preview,
    this.senderName,
    this.readerName,
    this.messageCount,
    this.readAt,
    this.matchId,
    this.messageId,
    this.notificationId,
    this.daysRemaining,
    this.expiryDate,
    this.reportId,
    this.reportStatus,
    this.resolutionSummary,
  });

  @override
  String toString() =>
      'RealtimeEvent(type: $type, source: $source, conversationId: $conversationId, unreadCountDelta: $unreadCountDelta, messageId: $messageId, daysRemaining: $daysRemaining)';
}
