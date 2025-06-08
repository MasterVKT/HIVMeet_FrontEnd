// lib/presentation/blocs/conversations/conversations_event.dart

import 'package:equatable/equatable.dart';

abstract class ConversationsEvent extends Equatable {
  const ConversationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversations extends ConversationsEvent {
  final bool refresh;

  const LoadConversations({this.refresh = false});

  @override
  List<Object> get props => [refresh];
}

class LoadMoreConversations extends ConversationsEvent {}

class DeleteConversation extends ConversationsEvent {
  final String conversationId;

  const DeleteConversation({required this.conversationId});

  @override
  List<Object> get props => [conversationId];
}

class ArchiveConversation extends ConversationsEvent {
  final String conversationId;

  const ArchiveConversation({required this.conversationId});

  @override
  List<Object> get props => [conversationId];
}