part of 'conversations_bloc.dart';

abstract class ConversationsEvent extends Equatable {
  const ConversationsEvent();

  @override
  List<Object> get props => [];
}

/// Charger les conversations initiales
class LoadConversations extends ConversationsEvent {
  final bool refresh;

  const LoadConversations({this.refresh = false});

  @override
  List<Object> get props => [refresh];
}

/// Charger plus de conversations (pagination)
class LoadMoreConversations extends ConversationsEvent {}

/// Rafraîchir les conversations (pull-to-refresh)
class RefreshConversations extends ConversationsEvent {}

/// Marquer une conversation comme lue
class MarkConversationAsRead extends ConversationsEvent {
  final String conversationId;

  const MarkConversationAsRead({required this.conversationId});

  @override
  List<Object> get props => [conversationId];
}

/// Rechercher dans les conversations
class SearchConversations extends ConversationsEvent {
  final String query;

  const SearchConversations({required this.query});

  @override
  List<Object> get props => [query];
}
