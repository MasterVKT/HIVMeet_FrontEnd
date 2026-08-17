import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/domain/entities/app_notification.dart';

class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.isRead
            ? null
            : AppColors.primaryPurple.withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NotificationIcon(type: notification.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryPurple,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notification.createdAt, locale: 'fr'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  final AppNotificationType type;
  const _NotificationIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (type) {
      case AppNotificationType.newMatch:
        icon = Icons.favorite;
        color = Colors.pink;
        break;
      case AppNotificationType.newMessage:
        icon = Icons.chat_bubble;
        color = AppColors.primaryPurple;
        break;
      case AppNotificationType.like:
        icon = Icons.thumb_up;
        color = Colors.orange;
        break;
      case AppNotificationType.superLike:
        icon = Icons.star;
        color = Colors.amber;
        break;
      case AppNotificationType.system:
        icon = Icons.notifications;
        color = Colors.grey;
        break;
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
