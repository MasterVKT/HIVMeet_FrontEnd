import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hivmeet/core/config/routes.dart';
import 'package:hivmeet/core/config/premium_navigation.dart';
import 'package:hivmeet/core/notifications/notification_read_policy.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/app_notification.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/notifications/notifications_bloc.dart';
import 'package:hivmeet/presentation/blocs/notifications/notifications_event.dart';
import 'package:hivmeet/presentation/blocs/notifications/notifications_state.dart';
import 'package:hivmeet/presentation/widgets/notifications/empty_notifications_view.dart';
import 'package:hivmeet/presentation/widgets/notifications/notification_card.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<NotificationsBloc>(),
      child: const _NotificationsRouteTracker(),
    );
  }
}

class _NotificationsRouteTracker extends StatefulWidget {
  const _NotificationsRouteTracker();

  @override
  State<_NotificationsRouteTracker> createState() =>
      _NotificationsRouteTrackerState();
}

class _NotificationsRouteTrackerState
    extends State<_NotificationsRouteTracker> {
  @override
  void initState() {
    super.initState();
    getIt<RealtimeEventBus>().setActiveRoute('/notifications');
  }

  @override
  void dispose() {
    getIt<RealtimeEventBus>().setActiveRoute(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const _NotificationsContent();
  }
}

class _NotificationsContent extends StatelessWidget {
  const _NotificationsContent();

  String? _nonEmptyString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String) return null;
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  /// Les notifications FCM/WebSocket fournissent normalement `from_user_id`.
  /// Le transmettre à la page de chat permet de résoudre immédiatement le
  /// profil de l'expéditeur, sans dépendre de la pagination des conversations.
  Conversation? _conversationFromNotification(
    AppNotification notification,
    String conversationId,
  ) {
    final otherUserId = _nonEmptyString(
          notification.data,
          'from_user_id',
        ) ??
        _nonEmptyString(notification.data, 'other_user_id') ??
        _nonEmptyString(notification.data, 'reader_id');

    if (otherUserId == null) return null;

    return Conversation(
      id: conversationId,
      participantIds: [otherUserId],
      otherUserId: otherUserId,
      updatedAt: notification.createdAt,
    );
  }

  void _onTap(BuildContext context, AppNotification notification) {
    if (NotificationReadPolicy.shouldMarkReadOnTap(notification.type)) {
      context
          .read<NotificationsBloc>()
          .add(MarkNotificationRead(notification.id));
    }

    final data = notification.data;

    // Pour les notifications de message : marquer immédiatement toutes les
    // notifications de cette conversation comme lues (meilleure UX — le
    // badge cloche se décrémente pour toutes les notifs de cette conv,
    // pas seulement celle tapée). ChatPage fera de même via
    // conversationRead, mais ce dispatch anticipe le résultat.
    if (notification.type == AppNotificationType.newMessage) {
      final conversationId = data['conversation_id'] as String?;
      if (conversationId != null && conversationId.isNotEmpty) {
        context
            .read<NotificationsBloc>()
            .add(ConversationNotificationsRead(conversationId));
      }
    }

    switch (notification.type) {
      case AppNotificationType.newMatch:
        final conversationId =
            data['conversation_id'] as String? ?? data['match_id'] as String?;
        if (conversationId != null && conversationId.isNotEmpty) {
          // Aller directement à la conversation du match
          final conversation =
              _conversationFromNotification(notification, conversationId);
          context.push('/chat/$conversationId', extra: conversation);
        } else {
          // Fallback : liste des matches
          context.push('/matches');
        }
        break;
      case AppNotificationType.newMessage:
        final conversationId = data['conversation_id'] as String?;
        if (conversationId != null && conversationId.isNotEmpty) {
          final conversation =
              _conversationFromNotification(notification, conversationId);
          context.push('/chat/$conversationId', extra: conversation);
        } else {
          context.push('/conversations');
        }
        break;
      case AppNotificationType.messageRead:
        final conversationId = data['conversation_id'] as String?;
        if (conversationId != null && conversationId.isNotEmpty) {
          final conversation =
              _conversationFromNotification(notification, conversationId);
          context.push('/chat/$conversationId', extra: conversation);
        } else {
          context.push('/conversations');
        }
        break;
      case AppNotificationType.like:
      case AppNotificationType.superLike:
        final fromUserId = data['from_user_id'] as String?;
        if (fromUserId != null && fromUserId.isNotEmpty) {
          // Premium : le backend fournit l'ID du liker → aller à son profil
          context.push('/profile/$fromUserId');
        } else {
          // Non-premium : from_user_id est vide → page d'upsell
          context.push('/likes-received');
        }
        break;
      case AppNotificationType.subscriptionExpiring:
        context.push(PremiumNavigation.location(
          returnTo: AppRoutes.profile,
        ));
        break;
      case AppNotificationType.reportResolved:
        _showReportResolutionDialog(context, notification);
        break;
      case AppNotificationType.system:
        break;
    }
  }

  /// Affiche la décision complète d'un signalement dans un dialog.
  void _showReportResolutionDialog(
    BuildContext context,
    AppNotification notification,
  ) {
    final data = notification.data;
    final status = data['status'] as String? ?? 'resolved';
    final resolutionSummary = data['resolution_summary'] as String? ?? '';
    final isResolved = status == 'resolved';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isResolved ? Icons.check_circle : Icons.cancel,
              color: isResolved ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                LocalizationService.translate(
                  'notifications.report_resolved_title',
                ),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocalizationService.translate(
                isResolved
                    ? 'notifications.report_status_resolved'
                    : 'notifications.report_status_dismissed',
              ),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isResolved ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 12),
            if (resolutionSummary.isNotEmpty)
              Text(
                resolutionSummary,
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              LocalizationService.translate('common.close'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          LocalizationService.translate('common.notifications'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsLoaded &&
                  state.notifications.isNotEmpty) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'mark_all_read') {
                      context
                          .read<NotificationsBloc>()
                          .add(const MarkAllNotificationsRead());
                    } else if (value == 'delete_all') {
                      _confirmDeleteAll(context);
                    }
                  },
                  itemBuilder: (context) => [
                    if (state.unreadCount > 0)
                      PopupMenuItem(
                        value: 'mark_all_read',
                        child: Text(
                          LocalizationService.translate(
                            'notifications.mark_all_read',
                          ),
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete_all',
                      child: Text(
                        LocalizationService.translate(
                          'notifications.delete_all',
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationsError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message,
                      style: TextStyle(color: theme.colorScheme.error)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context
                        .read<NotificationsBloc>()
                        .add(const RefreshNotifications()),
                    child: Text(LocalizationService.translate('common.retry')),
                  ),
                ],
              ),
            );
          }

          if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async => context
                    .read<NotificationsBloc>()
                    .add(const RefreshNotifications()),
                child: const SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: 400,
                    child: EmptyNotificationsView(),
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => context
                  .read<NotificationsBloc>()
                  .add(const RefreshNotifications()),
              child: ListView.separated(
                itemCount: state.notifications.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 68),
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return Dismissible(
                    key: ValueKey(notification.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await _confirmDelete(context, notification);
                    },
                    child: NotificationCard(
                      notification: notification,
                      onTap: () => _onTap(context, notification),
                    ),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Confirmation pour la suppression individuelle (swipe).
  Future<bool> _confirmDelete(
    BuildContext context,
    AppNotification notification,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          LocalizationService.translate('notifications.delete_title'),
        ),
        content: Text(
          LocalizationService.translate('notifications.delete_confirm'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              LocalizationService.translate('common.cancel'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              LocalizationService.translate('common.delete'),
            ),
          ),
        ],
      ),
    );
    if (result == true && context.mounted) {
      context
          .read<NotificationsBloc>()
          .add(DeleteNotification(notification.id));
      return true;
    }
    return false;
  }

  /// Confirmation pour la suppression de toutes les notifications.
  void _confirmDeleteAll(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          LocalizationService.translate('notifications.delete_all_title'),
        ),
        content: Text(
          LocalizationService.translate('notifications.delete_all_confirm'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              LocalizationService.translate('common.cancel'),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
              context
                  .read<NotificationsBloc>()
                  .add(const DeleteAllNotifications());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              LocalizationService.translate('common.delete'),
            ),
          ),
        ],
      ),
    );
  }
}
