part of 'chat_bloc.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

enum ChatUserAction { block, report }

const Object _chatStateUnset = Object();

class ChatLoaded extends ChatState {
  final List<Message> messages;
  final bool hasMore;
  final bool isTyping;
  final bool isLoadingMore;
  final bool showPremiumPrompt;
  final bool? otherIsOnline;
  final DateTime? otherLastActive;
  final ChatUserAction? completedAction;
  final String? actionError;

  const ChatLoaded({
    required this.messages,
    required this.hasMore,
    required this.isTyping,
    required this.isLoadingMore,
    this.showPremiumPrompt = false,
    this.otherIsOnline,
    this.otherLastActive,
    this.completedAction,
    this.actionError,
  });

  ChatLoaded copyWith({
    List<Message>? messages,
    bool? hasMore,
    bool? isTyping,
    bool? isLoadingMore,
    bool? showPremiumPrompt,
    Object? otherIsOnline = _chatStateUnset,
    Object? otherLastActive = _chatStateUnset,
    Object? completedAction = _chatStateUnset,
    Object? actionError = _chatStateUnset,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      isTyping: isTyping ?? this.isTyping,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      showPremiumPrompt: showPremiumPrompt ?? this.showPremiumPrompt,
      otherIsOnline: identical(otherIsOnline, _chatStateUnset)
          ? this.otherIsOnline
          : otherIsOnline as bool?,
      otherLastActive: identical(otherLastActive, _chatStateUnset)
          ? this.otherLastActive
          : otherLastActive as DateTime?,
      completedAction: identical(completedAction, _chatStateUnset)
          ? this.completedAction
          : completedAction as ChatUserAction?,
      actionError: identical(actionError, _chatStateUnset)
          ? this.actionError
          : actionError as String?,
    );
  }

  @override
  List<Object?> get props => [
        messages,
        hasMore,
        isTyping,
        isLoadingMore,
        showPremiumPrompt,
        otherIsOnline,
        otherLastActive,
        completedAction,
        actionError,
      ];
}

class ChatError extends ChatState {
  final String message;
  const ChatError({required this.message});

  @override
  List<Object> get props => [message];
}
