// lib/presentation/blocs/chat/chat_state.dart

import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/entities/profile.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final Conversation conversation;
  final List<Message> messages;
  final Profile otherUserProfile;
  final bool hasMore;
  final bool isLoadingMore;
  final Map<String, bool> typingStatus;
  final List<String> sendingMessageIds;

  const ChatLoaded({
    required this.conversation,
    required this.messages,
    required this.otherUserProfile,
    required this.hasMore,
    this.isLoadingMore = false,
    this.typingStatus = const {},
    this.sendingMessageIds = const [],
  });

  bool get isTyping => typingStatus.values.any((typing) => typing);

  ChatLoaded copyWith({
    Conversation? conversation,
    List<Message>? messages,
    Profile? otherUserProfile,
    bool? hasMore,
    bool? isLoadingMore,
    Map<String, bool>? typingStatus,
    List<String>? sendingMessageIds,
  }) {
    return ChatLoaded(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      otherUserProfile: otherUserProfile ?? this.otherUserProfile,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      typingStatus: typingStatus ?? this.typingStatus,
      sendingMessageIds: sendingMessageIds ?? this.sendingMessageIds,
    );
  }

  @override
  List<Object?> get props => [
        conversation,
        messages,
        otherUserProfile,
        hasMore,
        isLoadingMore,
        typingStatus,
        sendingMessageIds,
      ];
}

class ChatError extends ChatState {
  final String message;

  const ChatError({required this.message});

  @override
  List<Object> get props => [message];
}