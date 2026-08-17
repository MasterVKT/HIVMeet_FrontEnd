import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
      child: const _NotificationsContent(),
    );
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
        _nonEmptyString(notification.data, 'other_user_id');

    if (otherUserId == null) return null;

    return Conversation(
      id: conversationId,
      participantIds: [otherUserId],
      otherUserId: otherUserId,
      updatedAt: notification.createdAt,
    );
  }

  void _onTap(BuildContext context, AppNotification notification) {
    context
        .read<NotificationsBloc>()
        .add(MarkNotificationRead(notification.id));

    final data = notification.data;
    switch (notification.type) {
      case AppNotificationType.newMatch:
        context.push('/matches');
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
      case AppNotificationType.like:
      case AppNotificationType.superLike:
        context.push('/discovery');
        break;
      case AppNotificationType.system:
        break;
    }
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
              if (state is NotificationsLoaded && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () => context
                      .read<NotificationsBloc>()
                      .add(const MarkAllNotificationsRead()),
                  child: Text(
                    LocalizationService.translate(
                      'notifications.mark_all_read',
                    ),
                  ),
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
                  return NotificationCard(
                    notification: notification,
                    onTap: () => _onTap(context, notification),
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
}
