import 'package:hivmeet/domain/entities/app_notification.dart';

/// Keeps read-receipt alerts visible until the member explicitly acts on them.
class NotificationReadPolicy {
  const NotificationReadPolicy._();

  /// Opening a chat acknowledges only an incoming-message notification.
  /// A match or read-receipt alert can also open a chat, but must retain its
  /// unread state until the member marks it read through the normal controls.
  static bool shouldMarkReadOnTap(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.newMessage:
      case AppNotificationType.like:
      case AppNotificationType.superLike:
      case AppNotificationType.subscriptionExpiring:
      case AppNotificationType.reportResolved:
      case AppNotificationType.system:
        return true;
      case AppNotificationType.newMatch:
      case AppNotificationType.messageRead:
        return false;
    }
  }
}
