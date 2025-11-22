part of 'conversations_bloc.dart';

abstract class ConversationsState extends Equatable {
  const ConversationsState();

  @override
  List<Object?> get props => [];
}

class ConversationsInitial extends ConversationsState {}

class ConversationsLoading extends ConversationsState {}

class ConversationsLoaded extends ConversationsState {
  final List<Conversation> conversations; // Liste filtrée/recherchée
  final List<Conversation> allConversations; // Liste complète
  final bool hasMore; // Plus de conversations à charger
  final bool isLoadingMore; // Chargement en cours (pagination)
  final int totalUnreadCount; // Nombre total de messages non lus
  final String searchQuery; // Requête de recherche actuelle

  const ConversationsLoaded({
    required this.conversations,
    required this.allConversations,
    required this.hasMore,
    required this.isLoadingMore,
    required this.totalUnreadCount,
    required this.searchQuery,
  });

  @override
  List<Object?> get props => [
        conversations,
        allConversations,
        hasMore,
        isLoadingMore,
        totalUnreadCount,
        searchQuery,
      ];

  ConversationsLoaded copyWith({
    List<Conversation>? conversations,
    List<Conversation>? allConversations,
    bool? hasMore,
    bool? isLoadingMore,
    int? totalUnreadCount,
    String? searchQuery,
  }) {
    return ConversationsLoaded(
      conversations: conversations ?? this.conversations,
      allConversations: allConversations ?? this.allConversations,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ConversationsError extends ConversationsState {
  final String message;

  const ConversationsError({required this.message});

  @override
  List<Object> get props => [message];
}
