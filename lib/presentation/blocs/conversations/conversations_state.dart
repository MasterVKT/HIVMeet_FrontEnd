part of 'conversations_bloc.dart';

abstract class ConversationsState extends Equatable {
  const ConversationsState();

  @override
  List<Object?> get props => [];
}

class ConversationsInitial extends ConversationsState {}

class ConversationsLoading extends ConversationsState {
  final ConversationFilter activeFilter;

  const ConversationsLoading({this.activeFilter = ConversationFilter.all});

  @override
  List<Object?> get props => [activeFilter];
}

class ConversationsLoaded extends ConversationsState {
  final List<Conversation> conversations;
  final List<Conversation> allConversations;
  final bool hasMore;
  final bool isLoadingMore;
  final int totalUnreadCount;
  final String searchQuery;
  final ConversationFilter activeFilter;
  final String? actionError;

  const ConversationsLoaded({
    required this.conversations,
    required this.allConversations,
    required this.hasMore,
    required this.isLoadingMore,
    required this.totalUnreadCount,
    required this.searchQuery,
    this.activeFilter = ConversationFilter.all,
    this.actionError,
  });

  @override
  List<Object?> get props => [
        conversations,
        allConversations,
        hasMore,
        isLoadingMore,
        totalUnreadCount,
        searchQuery,
        activeFilter,
        actionError,
      ];

  ConversationsLoaded copyWith({
    List<Conversation>? conversations,
    List<Conversation>? allConversations,
    bool? hasMore,
    bool? isLoadingMore,
    int? totalUnreadCount,
    String? searchQuery,
    ConversationFilter? activeFilter,
    Object? actionError = _actionErrorUnchanged,
  }) {
    return ConversationsLoaded(
      conversations: conversations ?? this.conversations,
      allConversations: allConversations ?? this.allConversations,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: activeFilter ?? this.activeFilter,
      actionError: identical(actionError, _actionErrorUnchanged)
          ? this.actionError
          : actionError as String?,
    );
  }
}

const Object _actionErrorUnchanged = Object();

class ConversationsError extends ConversationsState {
  final String message;

  const ConversationsError({required this.message});

  @override
  List<Object> get props => [message];
}
