part of 'conversations_bloc.dart';

abstract class ConversationsEvent extends Equatable {
  const ConversationsEvent();

  @override
  List<Object> get props => [];
}

class LoadConversations extends ConversationsEvent {}

class RefreshConversations extends ConversationsEvent {}
