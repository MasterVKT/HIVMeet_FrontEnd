// lib/presentation/blocs/conversations/conversations_state.dart

import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/message.dart';

abstract class ConversationsState extends Equatable {
  const ConversationsState();

  @override
  List<Object?> get props => [];
}

class ConversationsInitial extends ConversationsState {}

class ConversationsLoading extends ConversationsState {}

class ConversationsLoaded extends ConversationsState {
  final List<ConversationWithProfile> conversations;
  final bool hasMore;
  final bool isLoadingMore;
  final int totalUnreadCount;

  const ConversationsLoaded({
    required this.conversations,
    required this.hasMore,
    this.isLoadingMore = false,
    this.totalUnreadCount = 0,
  });

  ConversationsLoaded copyWith({
    List<ConversationWithProfile>? conversations,
    bool? hasMore,
    bool? isLoadingMore,
    int? totalUnreadCount,
  }) {
    return ConversationsLoaded(
      conversations: conversations ?? this.conversations,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
    );
  }

  @override
  List<Object?> get props => [conversations, hasMore, isLoadingMore, totalUnreadCount];
}

class ConversationsError extends ConversationsState {
  final String message;

  const ConversationsError({required this.message});

  @override
  List<Object> get props => [message];
}

// Model combining conversation with profile data
class ConversationWithProfile {
  final Conversation conversation;
  final String otherUserName;
  final String otherUserPhotoUrl;
  final bool isOtherUserOnline;

  const ConversationWithProfile({
    required this.conversation,
    required this.otherUserName,
    required this.otherUserPhotoUrl,
    required this.isOtherUserOnline,
  });
}