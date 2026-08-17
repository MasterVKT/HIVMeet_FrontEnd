import 'package:equatable/equatable.dart';
import 'package:hivmeet/core/realtime/realtime_event.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationsEvent {
  const LoadNotifications();
}

class RefreshNotifications extends NotificationsEvent {
  const RefreshNotifications();
}

class RealtimeNotificationReceived extends NotificationsEvent {
  final RealtimeEvent realtimeEvent;

  const RealtimeNotificationReceived(this.realtimeEvent);

  @override
  List<Object?> get props => [realtimeEvent];
}

class ConversationNotificationsRead extends NotificationsEvent {
  final String conversationId;

  const ConversationNotificationsRead(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class MarkNotificationRead extends NotificationsEvent {
  final String notificationId;
  const MarkNotificationRead(this.notificationId);
  @override
  List<Object?> get props => [notificationId];
}

class MarkAllNotificationsRead extends NotificationsEvent {
  const MarkAllNotificationsRead();
}

class ClearNotifications extends NotificationsEvent {
  const ClearNotifications();
}
