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

/// Demande de connexion WebSocket pour la conversation active.
class ConnectToWebSocket extends ChatEvent {
  const ConnectToWebSocket();
}

/// Demande de déconnexion WebSocket (ex: navigation hors chat).
class DisconnectFromWebSocket extends ChatEvent {
  const DisconnectFromWebSocket();
}

/// Événement interne : message créé reçu via WebSocket.
class _WebSocketMessageReceived extends ChatEvent {
  final Map<String, dynamic> data;
  const _WebSocketMessageReceived(this.data);
  @override
  List<Object?> get props => [data];
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
  const _WebSocketPresenceUpdate(
      {required this.userId, required this.isOnline});
  @override
  List<Object?> get props => [userId, isOnline];
}
