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
