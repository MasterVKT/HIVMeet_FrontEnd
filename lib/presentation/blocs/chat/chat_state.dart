part of 'chat_bloc.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<Message> messages;
  final bool hasMore; // Plus de messages à charger
  final bool isTyping; // L'autre participant est en train de taper
  final bool isLoadingMore; // Chargement de messages plus anciens en cours
  final bool showPremiumPrompt; // Limite gratuite atteinte (50 messages)

  const ChatLoaded({
    required this.messages,
    required this.hasMore,
    required this.isTyping,
    required this.isLoadingMore,
    this.showPremiumPrompt = false,
  });

  ChatLoaded copyWith({
    List<Message>? messages,
    bool? hasMore,
    bool? isTyping,
    bool? isLoadingMore,
    bool? showPremiumPrompt,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      isTyping: isTyping ?? this.isTyping,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      showPremiumPrompt: showPremiumPrompt ?? this.showPremiumPrompt,
    );
  }

  @override
  List<Object?> get props =>
      [messages, hasMore, isTyping, isLoadingMore, showPremiumPrompt];
}

class ChatError extends ChatState {
  final String message;
  const ChatError({required this.message});
  @override
  List<Object> get props => [message];
}
