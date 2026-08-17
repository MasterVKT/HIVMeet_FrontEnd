import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/realtime/realtime_event.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/core/services/localization_service.dart';
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
  late final StreamSubscription<RealtimeEvent> _realtimeSubscription;
  Future<void> _operationQueue = Future.value();

  NotificationsBloc({
    required NotificationsLocalStore store,
    required MatchRepository matchRepository,
    required MessageRepository messageRepository,
    required RealtimeEventBus realtimeBus,
  })  : _store = store,
        _matchRepository = matchRepository,
        _messageRepository = messageRepository,
        _realtimeBus = realtimeBus,
        super(const NotificationsInitial()) {
    on<LoadNotifications>(_onLoad);
    on<RefreshNotifications>(_onRefresh);
    on<RealtimeNotificationReceived>(_onRealtimeNotification);
    on<ConversationNotificationsRead>(_onConversationRead);
    on<MarkNotificationRead>(_onMarkRead);
    on<MarkAllNotificationsRead>(_onMarkAllRead);
    on<ClearNotifications>(_onClear);

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
      if (!showLoading) {
        final currentState = state;
        final currentNotifications = currentState is NotificationsLoaded
            ? currentState.notifications
            : const <AppNotification>[];
        final storedIds = stored.map((notification) => notification.id).toSet();
        emit(_loadedState([
          ...stored,
          ...currentNotifications.where(
            (notification) => !storedIds.contains(notification.id),
          ),
        ]));
      }

      final derived = await _loadDerived();
      final storedIds = stored.map((notification) => notification.id).toSet();
      final merged = [
        ...stored,
        ...derived
            .where((notification) => !storedIds.contains(notification.id)),
      ];
      emit(_loadedState(merged));
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

  NotificationsLoaded _loadedState(Iterable<AppNotification> notifications) {
    final sorted = notifications.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final unread = sorted.where((notification) => !notification.isRead).length;
    return NotificationsLoaded(notifications: sorted, unreadCount: unread);
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
          for (final match in matches.where((match) => match.isNew)) {
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
          for (final conversation
              in page.conversations.where((item) => item.unreadCount > 0)) {
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
        return true;
      case RealtimeEventType.messageRead:
      case RealtimeEventType.messageDelivered:
      case RealtimeEventType.conversationRead:
      case RealtimeEventType.appResumed:
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
    if (event.matchId != null) data['match_id'] = event.matchId;

    switch (event.type) {
      case RealtimeEventType.newMessage:
        data['type'] = 'new_message';
        return AppNotification(
          id: _stableId(event,
              prefix: 'message', fallback: event.conversationId),
          type: AppNotificationType.newMessage,
          title: LocalizationService.translate(
            'notifications.new_message_title',
          ),
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
      case RealtimeEventType.messageRead:
      case RealtimeEventType.messageDelivered:
      case RealtimeEventType.conversationRead:
      case RealtimeEventType.appResumed:
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
    final messageId = event.messageId;
    if (prefix == 'message' && messageId != null && messageId.isNotEmpty) {
      return 'message_$messageId';
    }
    final notificationId = event.notificationId;
    if (notificationId != null && notificationId.isNotEmpty) {
      return notificationId;
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
