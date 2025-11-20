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
  final Stream<List<Message>> stream;
  final bool isTyping;

  const ChatLoaded(
      {required this.messages, required this.stream, required this.isTyping});

  ChatLoaded copyWith(
      {List<Message>? messages,
      Stream<List<Message>>? stream,
      bool? isTyping}) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      stream: stream ?? this.stream,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  @override
  List<Object?> get props => [messages, stream, isTyping];
}

class ChatError extends ChatState {
  final String message;
  const ChatError({required this.message});
  @override
  List<Object> get props => [message];
}
