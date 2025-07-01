// lib/presentation/blocs/chat/chat_event.dart

import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/message.dart';

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

class SendTextMessage extends ChatEvent {
  final String content;

  const SendTextMessage({required this.content});

  @override
  List<Object> get props => [content];
}

class SendMediaMessage extends ChatEvent {
  final File mediaFile;
  final MessageType type;

  const SendMediaMessage({
    required this.mediaFile,
    required this.type,
  });

  @override
  List<Object> get props => [mediaFile, type];
}

class MarkMessageAsRead extends ChatEvent {
  final String messageId;

  const MarkMessageAsRead({required this.messageId});

  @override
  List<Object> get props => [messageId];
}

class DeleteMessage extends ChatEvent {
  final String messageId;

  const DeleteMessage({required this.messageId});

  @override
  List<Object> get props => [messageId];
}

class SetTypingStatus extends ChatEvent {
  final bool isTyping;

  const SetTypingStatus({required this.isTyping});

  @override
  List<Object> get props => [isTyping];
}
