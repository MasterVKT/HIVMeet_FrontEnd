import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/notifications/read_receipt_notification_copy.dart';
import 'package:hivmeet/core/realtime/realtime_event.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/data/datasources/remote/notification_api.dart';
import 'package:hivmeet/data/services/notifications_local_store.dart';
import 'package:hivmeet/domain/entities/app_notification.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';

import 'notifications_event.dart';
import 'notifications_state.dart';

/// Source unique de vérité des notifications in-app et de leur compteur.
///
/// Les notifications FCM sont persistées par [NotificationService] avant
/// d'être publiées dans le bus. Celles reçues uniquement via WebSocket sont
/// persistées ici, ce qui donne le même résultat pour les deux canaux.
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsLocalStore _store;
  final MatchRepository _matchRepository;
  final MessageRepository _messageRepository;
  final RealtimeEventBus _realtimeBus;
  final NotificationApi _notificationApi;
  late final StreamSubscription<RealtimeEvent> _realtimeSubscription;
  Future<void> _operationQueue = Future.value();

  NotificationsBloc({
    required NotificationsLocalStore store,
    required MatchRepository matchRepository,
    required MessageRepository messageRepository,
    required RealtimeEventBus realtimeBus,
    required NotificationApi notificationApi,
  })  : _store = store,
        _matchRepository = matchRepository,
        _messageRepository = messageRepository,
        _realtimeBus = realtimeBus,
        _notificationApi = notificationApi,
        super(const NotificationsInitial()) {
    on<LoadNotifications>(_onLoad);
    on<RefreshNotifications>(_onRefresh);
    on<RealtimeNotificationReceived>(_onRealtimeNotification);
    on<ConversationNotificationsRead>(_onConversationRead);
    on<MarkNotificationRead>(_onMarkRead);
    on<MarkAllNotificationsRead>(_onMarkAllRead);
    on<ClearNotifications>(_onClear);
    on<DeleteNotification>(_onDelete);
    on<DeleteAllNotifications>(_onDeleteAll);

    _realtimeSubscription = _realtimeBus.events.listen((event) {
      if (event.type == RealtimeEventType.appResumed) {
        add(const RefreshNotifications());
      } else if (event.type == RealtimeEventType.conversationRead &&
          event.conversationId != null &&
          event.conversationId!.isNotEmpty) {
        add(ConversationNotificationsRead(event.conversationId!));
      } else if (_isNotificationEvent(event)) {
        add(RealtimeNotificationReceived(event));
      }
    });
  }

  Future<void> _onLoad(
    LoadNotifications event,
    Emitter<NotificationsState> emit,
  ) =>
      _enqueue(
        () => _reload(emit, showLoading: state is! NotificationsLoaded),
      );

  Future<void> _onRefresh(
    RefreshNotifications event,
    Emitter<NotificationsState> emit,
  ) =>
      _enqueue(() => _reload(emit));

  Future<void> _onRealtimeNotification(
    RealtimeNotificationReceived event,
    Emitter<NotificationsState> emit,
  ) =>
      _enqueue(() async {
        // FCM a déjà écrit son objet enrichi (titre/corps du push) dans le store.
        // Le WebSocket n'a pas cette étape : on la complète ici.
        if (event.realtimeEvent.source == RealtimeSource.websocket) {
          await _store.add(_notificationFromRealtime(event.realtimeEvent));
        }
        await _reload(emit);
      });

  Future<void> _onConversationRead(
    ConversationNotificationsRead event,
    Emitter<NotificationsState> emit,
  ) =>
      _enqueue(() async {
        final currentState = state;
        final notifications = currentState is NotificationsLoaded
            ? currentState.notifications
            : await _store.load();
        await _store.upsertAll(
          notifications
              .where(
                (notification) =>
                    !notification.isRead &&
                    notification.type == AppNotificationType.newMessage &&
                    notification.data['conversation_id'] ==
                        event.conversationId,
              )
              .map((notification) => notification.copyWith(isRead: true)),
        );
        await _reload(emit);
      });

  Future<void> _onMarkRead(
    MarkNotificationRead event,
    Emitter<NotificationsState> emit,
  ) =>
      _enqueue(() async {
        final currentState = state;
        if (currentState is NotificationsLoaded) {
          final notification = _findNotification(
            currentState.notifications,
            event.notificationId,
          );
          if (notification != null) {
            // Une notification dérivée n'était pas forcément déjà persistée :
            // l'upsert rend son état lu durable, même après un rafraîchissement.
            await _store.add(notification.copyWith(isRead: true));
          }
        } else {
          await _store.markRead(event.notificationId);
        }
        // Sync backend — best effort, ne pas bloquer l'UI
        try {
          await _notificationApi.markAsRead(event.notificationId);
        } catch (_) {}
        await _reload(emit);
      });

  Future<void> _onMarkAllRead(
    MarkAllNotificationsRead event,
    Emitter<NotificationsState> emit,
  ) =>
      _enqueue(() async {
        final currentState = state;
        if (currentState is NotificationsLoaded) {
          await _store.upsertAll(
            currentState.notifications
                .where((notification) => !notification.isRead)
                .map((notification) => notification.copyWith(isRead: true)),
          );
        } else {
          await _store.markAllRead();
        }
        // Sync backend — best effort
        try {
          await _notificationApi.markAllAsRead();
        } catch (_) {}
        await _reload(emit);
      });

  Future<void> _onClear(
    ClearNotifications event,
    Emitter<NotificationsState> emit,
  ) =>
      _enqueue(() async {
        await _store.clear();
        emit(const NotificationsInitial());
      });

  Future<void> _onDelete(
    DeleteNotification event,
    Emitter<NotificationsState> emit,
  ) =>
      _enqueue(() async {
        // Supprime localement
        await _store.delete(event.notificationId);
        // Supprime sur le backend — best effort
        try {
          await _notificationApi.deleteNotification(event.notificationId);
        } catch (_) {}
        await _reload(emit);
      });

  Future<void> _onDeleteAll(
    DeleteAllNotifications event,
    Emitter<NotificationsState> emit,
  ) =>
      _enqueue(() async {
        // Supprime localement
        await _store.clear();
        // Supprime sur le backend — best effort
        try {
          await _notificationApi.deleteAllNotifications();
        } catch (_) {}
        emit(const NotificationsInitial());
      });

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _operationQueue.then((_) => operation());
    _operationQueue = result.then<void>(
      (_) {},
      onError: (_, __) {},
    );
    return result;
  }

  Future<void> _reload(
    Emitter<NotificationsState> emit, {
    bool showLoading = false,
  }) async {
    if (showLoading) emit(const NotificationsLoading());

    try {
      final stored = await _store.load();

      // Récupère les notifications du backend (REST) et fusionne avec le local.
      // Permet de récupérer l'historique des notifications manquées pendant
      // que l'app était fermée. Best-effort : ne bloque pas si le backend
      // est injoignable.
      List<AppNotification> backendNotifications = const [];
      try {
        backendNotifications = await _notificationApi.getNotifications();
      } catch (_) {
        // Backend injoignable — on continue avec les données locales
      }

      // Fusionne : backend + local (préserve le statut isRead local)
      final mergedWithBackend = <AppNotification>[];
      final backendIds = <String>{};
      for (final bn in backendNotifications) {
        backendIds.add(bn.id);
        final localMatch = stored.where((s) => s.id == bn.id).firstOrNull;
        if (localMatch != null && localMatch.isRead && !bn.isRead) {
          mergedWithBackend.add(localMatch);
        } else {
          mergedWithBackend.add(bn);
        }
      }
      // Ajoute les notifications locales non présentes sur le backend
      for (final s in stored) {
        if (!backendIds.contains(s.id)) {
          mergedWithBackend.add(s);
        }
      }
      // Persiste les notifications du backend dans le local store
      if (backendNotifications.isNotEmpty) {
        await _store.upsertAll(backendNotifications);
      }

      if (!showLoading) {
        final currentState = state;
        final currentNotifications = currentState is NotificationsLoaded
            ? currentState.notifications
            : const <AppNotification>[];
        final mergedIds =
            mergedWithBackend.map((notification) => notification.id).toSet();
        emit(_loadedState([
          ...mergedWithBackend,
          ...currentNotifications.where(
            (notification) => !mergedIds.contains(notification.id),
          ),
        ]));
      }

      // This endpoint is the source of truth for the tab badge. The local
      // cache may contain only the first REST page or stale records.
      int? exactUnreadCount;
      try {
        exactUnreadCount = await _notificationApi.getUnreadCount();
      } catch (_) {
        // Keep the deduplicated local count while offline.
      }

      final derived = await _loadDerived();
      final storedIds =
          mergedWithBackend.map((notification) => notification.id).toSet();
      final merged = [
        ...mergedWithBackend,
        ...derived
            .where((notification) => !storedIds.contains(notification.id)),
      ];
      emit(_loadedState(merged, unreadCount: exactUnreadCount));
    } catch (_) {
      // Ne pas exposer les détails d'infrastructure ; conserver le dernier
      // état lisible lorsqu'un rafraîchissement secondaire échoue.
      if (state is! NotificationsLoaded) {
        emit(NotificationsError(
          LocalizationService.translate('notifications.load_error'),
        ));
      }
    }
  }

  NotificationsLoaded _loadedState(
    Iterable<AppNotification> notifications, {
    int? unreadCount,
  }) {
    // During the rollout, old `message_<id>` records and new UUID-backed
    // records can coexist.  Keep exactly one notification per message, using
    // the canonical backend UUID when it is available.
    final byBusinessKey = <String, AppNotification>{};
    for (final notification in notifications) {
      final key = _businessKey(notification);
      final existing = byBusinessKey[key];
      if (existing == null || _isCanonical(notification, existing)) {
        byBusinessKey[key] = notification;
      }
    }
    final sorted = byBusinessKey.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final unread = unreadCount ??
        sorted.where((notification) => !notification.isRead).length;
    return NotificationsLoaded(notifications: sorted, unreadCount: unread);
  }

  String _businessKey(AppNotification notification) {
    if (notification.type == AppNotificationType.newMessage) {
      final messageId = notification.data['message_id']?.toString();
      if (messageId != null && messageId.isNotEmpty) {
        return 'message:$messageId';
      }
    }
    return 'id:${notification.id}';
  }

  bool _isCanonical(AppNotification candidate, AppNotification existing) {
    final candidateLegacy = candidate.id.startsWith('message_');
    final existingLegacy = existing.id.startsWith('message_');
    if (candidateLegacy != existingLegacy) return !candidateLegacy;
    return candidate.createdAt.isAfter(existing.createdAt);
  }

  Future<List<AppNotification>> _loadDerived() async {
    final result = <AppNotification>[];

    // Filet de réconciliation au lancement : il couvre les éléments reçus
    // lorsque l'application n'était pas active, sans remplacer les entrées
    // persistées par FCM/WebSocket.
    try {
      final matchResult = await _matchRepository.getMatches();
      matchResult.fold(
        (_) {},
        (matches) {
          final activeRoute = _realtimeBus.activeRoute;
          final activeConversationId = _realtimeBus.activeConversationId;
          for (final match in matches.where((match) => match.isNew)) {
            // Suppression intelligente : ne pas créer de notification dérivée
            // si l'utilisateur est sur la page matches ou dans cette conversation
            if (activeRoute == '/matches') {
              continue;
            }
            if (activeConversationId != null &&
                activeConversationId == match.id) {
              continue;
            }
            result.add(AppNotification(
              id: 'match_${match.id}',
              type: AppNotificationType.newMatch,
              title: LocalizationService.translate(
                'notifications.new_match_title',
              ),
              body: LocalizationService.translate(
                'notifications.new_match_with',
                params: {'name': match.profile.displayName},
              ),
              data: {'match_id': match.id, 'type': 'new_match'},
              createdAt: match.matchedAt,
            ));
          }
        },
      );
    } catch (_) {
      // La disponibilité du flux de messages ne doit pas dépendre des matches.
    }

    try {
      final conversationsResult = await _messageRepository.getConversations();
      conversationsResult.fold(
        (_) {},
        (page) {
          final activeConversationId = _realtimeBus.activeConversationId;
          final activeRoute = _realtimeBus.activeRoute;
          for (final conversation
              in page.conversations.where((item) => item.unreadCount > 0)) {
            // Suppression intelligente : ne pas créer de notification dérivée
            // si l'utilisateur est dans cette conversation ou sur la page
            // conversations
            if (activeConversationId != null &&
                activeConversationId == conversation.id) {
              continue;
            }
            if (activeRoute == '/conversations') {
              continue;
            }
            final messageId = conversation.lastMessage?.id;
            result.add(AppNotification(
              id: messageId != null && messageId.isNotEmpty
                  ? 'message_$messageId'
                  : 'conversation_${conversation.id}',
              type: AppNotificationType.newMessage,
              title: LocalizationService.translate(
                'notifications.unread_message_title',
              ),
              body: conversation.otherUserName != null
                  ? LocalizationService.translate(
                      'notifications.message_from',
                      params: {'name': conversation.otherUserName},
                    )
                  : LocalizationService.translate(
                      'notifications.new_message_title',
                    ),
              data: {
                'conversation_id': conversation.id,
                if (messageId != null && messageId.isNotEmpty)
                  'message_id': messageId,
                if (conversation.otherUserId != null)
                  'from_user_id': conversation.otherUserId,
                'type': 'new_message',
              },
              createdAt: conversation.updatedAt,
            ));
          }
        },
      );
    } catch (_) {
      // Le cache local reste utilisable hors ligne.
    }

    return result;
  }

  bool _isNotificationEvent(RealtimeEvent event) {
    switch (event.type) {
      case RealtimeEventType.newMessage:
      case RealtimeEventType.newMatch:
      case RealtimeEventType.likeReceived:
      case RealtimeEventType.superLikeReceived:
      case RealtimeEventType.subscriptionExpiring:
      case RealtimeEventType.reportResolved:
      case RealtimeEventType.messageReadAlert:
        return true;
      case RealtimeEventType.matchRemoved:
      case RealtimeEventType.messageRead:
      case RealtimeEventType.messageDelivered:
      case RealtimeEventType.conversationRead:
      case RealtimeEventType.conversationHidden:
      case RealtimeEventType.conversationRestored:
      case RealtimeEventType.appResumed:
      case RealtimeEventType.subscriptionChanged:
        return false;
    }
  }

  AppNotification _notificationFromRealtime(RealtimeEvent event) {
    final data = <String, dynamic>{};
    if (event.conversationId != null) {
      data['conversation_id'] = event.conversationId;
    }
    final messageId = event.messageId?.trim();
    if (messageId != null && messageId.isNotEmpty) {
      data['message_id'] = messageId;
    }
    final fromUserId = event.fromUserId?.trim();
    if (fromUserId != null && fromUserId.isNotEmpty) {
      data['from_user_id'] = fromUserId;
    }
    final notificationId = event.notificationId?.trim();
    if (notificationId != null && notificationId.isNotEmpty) {
      data['notification_id'] = notificationId;
    }
    if (event.matchId != null) data['match_id'] = event.matchId;

    switch (event.type) {
      case RealtimeEventType.newMessage:
        data['type'] = 'new_message';
        if (event.senderName != null && event.senderName!.isNotEmpty) {
          data['sender_name'] = event.senderName!;
        }
        return AppNotification(
          id: _stableId(event,
              prefix: 'message', fallback: event.conversationId),
          type: AppNotificationType.newMessage,
          title: event.senderName?.trim().isNotEmpty == true
              ? event.senderName!.trim()
              : LocalizationService.translate(
                  'notifications.new_message_title'),
          body: event.preview?.trim().isNotEmpty == true
              ? event.preview!.trim()
              : LocalizationService.translate(
                  'notifications.new_message_received',
                ),
          data: data,
          createdAt: DateTime.now(),
        );
      case RealtimeEventType.newMatch:
        data['type'] = 'new_match';
        return AppNotification(
          id: _stableId(event, prefix: 'match', fallback: event.matchId),
          type: AppNotificationType.newMatch,
          title: LocalizationService.translate(
            'notifications.new_match_title',
          ),
          body: LocalizationService.translate(
            'notifications.new_match_received',
          ),
          data: data,
          createdAt: DateTime.now(),
        );
      case RealtimeEventType.likeReceived:
        data['type'] = 'like';
        return AppNotification(
          id: _stableId(event, prefix: 'like', fallback: event.fromUserId),
          type: AppNotificationType.like,
          title: LocalizationService.translate('notifications.new_like_title'),
          body: LocalizationService.translate('notifications.like_received'),
          data: data,
          createdAt: DateTime.now(),
        );
      case RealtimeEventType.superLikeReceived:
        data['type'] = 'super_like';
        return AppNotification(
          id: _stableId(event,
              prefix: 'super_like', fallback: event.fromUserId),
          type: AppNotificationType.superLike,
          title: LocalizationService.translate(
            'notifications.new_super_like_title',
          ),
          body: LocalizationService.translate(
            'notifications.super_like_received',
          ),
          data: data,
          createdAt: DateTime.now(),
        );
      case RealtimeEventType.messageReadAlert:
        data['type'] = 'message_read';
        data.remove('from_user_id');
        data.remove('message_id');
        if (fromUserId != null && fromUserId.isNotEmpty) {
          data['reader_id'] = fromUserId;
        }
        if (event.readerName != null && event.readerName!.isNotEmpty) {
          data['reader_name'] = event.readerName!;
        }
        if (messageId != null && messageId.isNotEmpty) {
          data['representative_message_id'] = messageId;
        }
        if (event.messageCount != null) {
          data['message_count'] = event.messageCount!;
        }
        if (event.readAt != null && event.readAt!.isNotEmpty) {
          data['read_at'] = event.readAt!;
        }
        return AppNotification(
          id: _stableId(
            event,
            prefix: 'message_read',
            fallback: event.conversationId,
          ),
          type: AppNotificationType.messageRead,
          title: ReadReceiptNotificationCopy.title(),
          body: ReadReceiptNotificationCopy.body(data),
          data: data,
          createdAt: DateTime.now(),
        );
      case RealtimeEventType.subscriptionExpiring:
        data['type'] = 'subscription_expiring';
        if (event.notificationId != null) {
          data['notification_id'] = event.notificationId!;
        }
        if (event.daysRemaining != null) {
          data['days_remaining'] = event.daysRemaining.toString();
        }
        if (event.expiryDate != null) {
          data['expiry_date'] = event.expiryDate!;
        }
        final days = event.daysRemaining;
        final body = days != null && days == 1
            ? LocalizationService.translate(
                'notifications.subscription_expiring_today')
            : LocalizationService.translate(
                'notifications.subscription_expiring_body',
                params: {'days': days?.toString() ?? ''},
              );
        return AppNotification(
          id: event.notificationId != null && event.notificationId!.isNotEmpty
              ? event.notificationId!
              : 'sub_expiry_${DateTime.now().microsecondsSinceEpoch}',
          type: AppNotificationType.subscriptionExpiring,
          title: LocalizationService.translate(
            'notifications.subscription_expiring_title',
          ),
          body: body,
          data: data,
          createdAt: DateTime.now(),
        );
      case RealtimeEventType.reportResolved:
        data['type'] = 'report_resolved';
        if (event.notificationId != null) {
          data['notification_id'] = event.notificationId!;
        }
        if (event.reportId != null) {
          data['report_id'] = event.reportId!;
        }
        if (event.reportStatus != null) {
          data['status'] = event.reportStatus!;
        }
        if (event.resolutionSummary != null) {
          data['resolution_summary'] = event.resolutionSummary!;
        }
        final isResolved = event.reportStatus == 'resolved';
        final statusLabel = LocalizationService.translate(
          isResolved
              ? 'notifications.report_status_resolved'
              : 'notifications.report_status_dismissed',
        );
        final summary = event.resolutionSummary ?? '';
        final body =
            summary.isNotEmpty ? '$statusLabel. $summary' : statusLabel;
        return AppNotification(
          id: event.notificationId != null && event.notificationId!.isNotEmpty
              ? event.notificationId!
              : 'report_${DateTime.now().microsecondsSinceEpoch}',
          type: AppNotificationType.reportResolved,
          title: LocalizationService.translate(
            'notifications.report_resolved_title',
          ),
          body: body,
          data: data,
          createdAt: DateTime.now(),
        );
      case RealtimeEventType.matchRemoved:
      case RealtimeEventType.messageRead:
      case RealtimeEventType.messageDelivered:
      case RealtimeEventType.conversationRead:
      case RealtimeEventType.conversationHidden:
      case RealtimeEventType.conversationRestored:
      case RealtimeEventType.appResumed:
      case RealtimeEventType.subscriptionChanged:
        throw StateError('Unexpected non-notification realtime event');
    }
  }

  AppNotification? _findNotification(
    Iterable<AppNotification> notifications,
    String notificationId,
  ) {
    for (final notification in notifications) {
      if (notification.id == notificationId) return notification;
    }
    return null;
  }

  String _stableId(
    RealtimeEvent event, {
    required String prefix,
    String? fallback,
  }) {
    // New persisted notifications carry their backend UUID on every channel.
    // Prefer it over the transitional `message_<message_id>` key so REST,
    // FCM and WebSocket all point to the same record. Legacy payloads without
    // that UUID still retain the message-id fallback below.
    final notificationId = event.notificationId;
    if (notificationId != null && notificationId.isNotEmpty) {
      return notificationId;
    }
    final messageId = event.messageId;
    if (prefix == 'message' && messageId != null && messageId.isNotEmpty) {
      return 'message_$messageId';
    }
    if (fallback != null && fallback.isNotEmpty) {
      return '${prefix}_$fallback';
    }
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }

  @override
  Future<void> close() async {
    await _realtimeSubscription.cancel();
    await super.close();
  }
}
