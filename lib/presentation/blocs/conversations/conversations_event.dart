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

class ChangeConversationFilter extends ConversationsEvent {
  final ConversationFilter filter;

  const ChangeConversationFilter({required this.filter});

  @override
  List<Object> get props => [filter];
}

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

class DeleteConversation extends ConversationsEvent {
  final String conversationId;

  const DeleteConversation({required this.conversationId});

  @override
  List<Object> get props => [conversationId];
}

class ClearConversationActionError extends ConversationsEvent {}

/// Signal temps réel (WebSocket notifications ou push FCM) indiquant qu'un
/// nouveau message est arrivé pour une conversation. Déclenche un patch
/// optimiste immédiat puis planifie une réconciliation serveur débouncée —
/// voir `ConversationsBloc._onConversationRealtimeSignal`.
class ConversationRealtimeSignal extends ConversationsEvent {
  final String conversationId;
  final String? preview;
  final String? senderId;

  const ConversationRealtimeSignal({
    required this.conversationId,
    this.preview,
    this.senderId,
  });

  @override
  List<Object> get props => [conversationId, preview ?? '', senderId ?? ''];
}

/// Réconciliation silencieuse avec le serveur : recharge la première page
/// et fusionne dans le cache local SANS jamais émettre `ConversationsLoading`
/// (contrairement à `LoadConversations`), pour éviter tout flash d'écran de
/// chargement à chaque message temps réel reçu.
class ReconcileConversations extends ConversationsEvent {
  const ReconcileConversations();
}
