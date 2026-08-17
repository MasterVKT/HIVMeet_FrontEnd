// lib/core/realtime/realtime_event_bus.dart

import 'dart:async';

import 'realtime_event.dart';

/// Hub applicatif unique pour les événements temps réel, quelle que soit
/// leur origine (WebSocket notifications, push FCM, signaux locaux).
///
/// Pourquoi un bus plutôt qu'un branchement direct WS → BLoC :
/// - Le backend a deux chemins de livraison indépendants pour un même
///   "nouveau message" (WebSocket `/ws/notifications/` et push FCM) : sans
///   point de convergence unique, chaque BLoC consommateur devrait
///   dédupliquer lui-même les deux sources.
/// - Plusieurs BLoCs/Cubits indépendants (ConversationsBloc, UnreadCubit)
///   doivent réagir aux mêmes événements sans dépendance directe entre eux.
class RealtimeEventBus {
  RealtimeEventBus({Duration? dedupeWindow})
      : _dedupeWindow = dedupeWindow ?? const Duration(seconds: 2);

  final Duration _dedupeWindow;
  final _controller = StreamController<RealtimeEvent>.broadcast();
  final Map<String, DateTime> _recentKeys = {};
  String? _activeConversationId;

  /// Flux broadcast des événements temps réel publiés.
  Stream<RealtimeEvent> get events => _controller.stream;

  /// Conversation actuellement ouverte à l'écran (ChatPage), ou `null`.
  ///
  /// Les consommateurs (ex. ConversationsBloc) l'utilisent pour éviter un
  /// patch optimiste redondant sur une conversation déjà visible et déjà
  /// mise à jour par son propre WebSocket de conversation.
  String? get activeConversationId => _activeConversationId;

  void setActiveConversation(String? conversationId) {
    _activeConversationId = conversationId;
  }

  /// Publie un événement, en supprimant les doublons proches dans le temps.
  ///
  /// La déduplication ne s'applique qu'aux événements porteurs d'un
  /// `conversationId` (newMessage, messageRead) : ce sont les seuls types
  /// susceptibles d'arriver deux fois pour le même fait via deux canaux
  /// (WebSocket et FCM). Les autres types sont toujours transmis.
  void publish(RealtimeEvent event) {
    if (_controller.isClosed) return;

    final dedupeKey = _dedupeKeyFor(event);
    if (dedupeKey != null) {
      final now = DateTime.now();
      _purgeExpired(now);
      final lastSeen = _recentKeys[dedupeKey];
      if (lastSeen != null && now.difference(lastSeen) < _dedupeWindow) {
        return;
      }
      _recentKeys[dedupeKey] = now;
    }

    _controller.add(event);
  }

  String? _dedupeKeyFor(RealtimeEvent event) {
    switch (event.type) {
      case RealtimeEventType.newMessage:
        final conversationId = event.conversationId;
        if (conversationId == null || conversationId.isEmpty) return null;
        // Clé par message si l'id est connu (les deux sources — WS et FCM —
        // le portent désormais) ; fallback sur l'ancien comportement sinon
        // pour ne pas régresser une source qui l'omettrait. Cela évite que
        // deux messages distincts de la même conversation arrivés à moins
        // de 2s d'intervalle ne se suppriment mutuellement.
        final messageId = event.messageId;
        return messageId != null && messageId.isNotEmpty
            ? '${event.type.name}:$conversationId:$messageId'
            : '${event.type.name}:$conversationId';
      case RealtimeEventType.messageRead:
        final conversationId = event.conversationId;
        if (conversationId == null || conversationId.isEmpty) return null;
        return '${event.type.name}:$conversationId';
      case RealtimeEventType.messageDelivered:
        // Un seul canal d'arrivée (/ws/notifications/) — pas de dédup.
        return null;
      case RealtimeEventType.newMatch:
        final matchId = event.matchId;
        return matchId == null || matchId.isEmpty
            ? null
            : '${event.type.name}:$matchId';
      case RealtimeEventType.likeReceived:
      case RealtimeEventType.superLikeReceived:
        final fromUserId = event.fromUserId;
        return fromUserId == null || fromUserId.isEmpty
            ? null
            : '${event.type.name}:$fromUserId';
      case RealtimeEventType.conversationRead:
      case RealtimeEventType.appResumed:
        return null;
    }
  }

  void _purgeExpired(DateTime now) {
    _recentKeys
        .removeWhere((_, seenAt) => now.difference(seenAt) >= _dedupeWindow);
  }

  void dispose() {
    _recentKeys.clear();
    _controller.close();
  }
}
