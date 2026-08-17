part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversation extends ChatEvent {
  final String conversationId;
  const LoadConversation({required this.conversationId});
  @override
  List<Object> get props => [conversationId];
}

class LoadMoreMessages extends ChatEvent {}

class SendTextMessageEvent extends ChatEvent {
  final String content;
  const SendTextMessageEvent({required this.content});
  @override
  List<Object> get props => [content];
}

class SendMediaMessageEvent extends ChatEvent {
  final File mediaFile;
  final MessageType type;
  const SendMediaMessageEvent({required this.mediaFile, required this.type});
  @override
  List<Object> get props => [mediaFile, type];
}

class MarkAsReadEvent extends ChatEvent {
  final String messageId;
  const MarkAsReadEvent({required this.messageId});
  @override
  List<Object> get props => [messageId];
}

/// Demande de marquer automatiquement tous les messages non lus de l'interlocuteur.
class MarkUnreadMessagesAsRead extends ChatEvent {
  const MarkUnreadMessagesAsRead();
}

class SetTypingStatus extends ChatEvent {
  final bool isTyping;
  const SetTypingStatus({required this.isTyping});
  @override
  List<Object> get props => [isTyping];
}

class DeleteMessageEvent extends ChatEvent {
  final String messageId;
  const DeleteMessageEvent({required this.messageId});
  @override
  List<Object> get props => [messageId];
}

class BlockUserEvent extends ChatEvent {
  final String userId;
  const BlockUserEvent({required this.userId});
  @override
  List<Object> get props => [userId];
}

class ReportUserEvent extends ChatEvent {
  final String userId;
  final String reason;
  final String? description;

  const ReportUserEvent({
    required this.userId,
    required this.reason,
    this.description,
  });

  @override
  List<Object?> get props => [userId, reason, description];
}

class ClearChatActionFeedback extends ChatEvent {
  const ClearChatActionFeedback();
}

/// Demande de connexion WebSocket pour la conversation active.
class ConnectToWebSocket extends ChatEvent {
  const ConnectToWebSocket();
}

/// Demande de déconnexion WebSocket (ex: navigation hors chat).
class DisconnectFromWebSocket extends ChatEvent {
  const DisconnectFromWebSocket();
}

/// Demande de resynchronisation des messages après une reconnexion
/// WebSocket automatique (des messages peuvent avoir été manqués pendant
/// la coupure, puisque le serveur ne les rejoue pas).
class ResyncMessages extends ChatEvent {
  const ResyncMessages();
}

/// Événement interne : message créé reçu via WebSocket.
class _WebSocketMessageReceived extends ChatEvent {
  final Map<String, dynamic> data;
  const _WebSocketMessageReceived(this.data);
  @override
  List<Object?> get props => [data];
}

/// Événement interne : accusé de lecture reçu via WebSocket.
class _WebSocketMessageRead extends ChatEvent {
  final String readerId;
  final Set<String> messageIds;
  final DateTime? readAt;

  const _WebSocketMessageRead({
    required this.readerId,
    required this.messageIds,
    required this.readAt,
  });

  @override
  List<Object?> get props => [readerId, messageIds, readAt];
}

/// Événement interne : accusé de livraison reçu via WebSocket.
class _WebSocketMessageDelivered extends ChatEvent {
  final Set<String> messageIds;
  final DateTime? deliveredAt;

  const _WebSocketMessageDelivered({
    required this.messageIds,
    required this.deliveredAt,
  });

  @override
  List<Object?> get props => [messageIds, deliveredAt];
}

/// Événement interne : indicateur de frappe reçu via WebSocket.
class _WebSocketTypingIndicator extends ChatEvent {
  final String userId;
  final bool isTyping;
  const _WebSocketTypingIndicator(
      {required this.userId, required this.isTyping});
  @override
  List<Object?> get props => [userId, isTyping];
}

/// Événement interne : mise à jour de présence reçue via WebSocket.
class _WebSocketPresenceUpdate extends ChatEvent {
  final String userId;
  final bool isOnline;
  final DateTime? lastActive;
  const _WebSocketPresenceUpdate(
      {required this.userId, required this.isOnline, this.lastActive});
  @override
  List<Object?> get props => [userId, isOnline, lastActive];
}
