// lib/presentation/blocs/chat/chat_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final MessageRepository _messageRepository;
  final ProfileRepository _profileRepository;
  
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _typingSubscription;
  
  String? _conversationId;
  List<Message> _messages = [];
  String? _lastMessageId;

  ChatBloc({
    required MessageRepository messageRepository,
    required ProfileRepository profileRepository,
  })  : _messageRepository = messageRepository,
        _profileRepository = profileRepository,
        super(ChatInitial()) {
    on<LoadConversation>(_onLoadConversation);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendTextMessage>(_onSendTextMessage);
    on<SendMediaMessage>(_onSendMediaMessage);
    on<MarkMessageAsRead>(_onMarkMessageAsRead);
    on<DeleteMessage>(_onDeleteMessage);
    on<SetTypingStatus>(_onSetTypingStatus);
  }

  Future<void> _onLoadConversation(
    LoadConversation event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    _conversationId = event.conversationId;
    
    final conversationResult = await _messageRepository.getConversation(event.conversationId);
    
    conversationResult.fold(
      (failure) => emit(ChatError(message: failure.message)),
      (conversation) async {
        final otherUserId = conversation.participants.firstWhere(
          (id) => id != 'currentUserId', // TODO: Get current user ID
        );
        
        final profileResult = await _profileRepository.getProfile(otherUserId);
        
        profileResult.fold(
          (failure) => emit(ChatError(message: failure.message)),
          (profile) async {
            final messagesResult = await _messageRepository.getMessages(
              conversationId: event.conversationId,
              limit: 50,
            );
            
            messagesResult.fold(
              (failure) => emit(ChatError(message: failure.message)),
              (messages) {
                _messages = messages;
                _lastMessageId = messages.isNotEmpty ? messages.last.id : null;
                
                emit(ChatLoaded(
                  conversation: conversation,
                  messages: _messages,
                  otherUserProfile: profile,
                  hasMore: messages.length >= 50,
                ));
                
                _subscribeToMessages();
                _subscribeToTyping();
              },
            );
          },
        );
      },
    );
  }

  Future<void> _onSendTextMessage(
    SendTextMessage event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final result = await _messageRepository.sendMessage(
        conversationId: _conversationId!,
        content: event.content,
      );
      
      result.fold(
        (failure) => emit(ChatError(message: failure.message)),
        (message) {
          // Message will be added via stream subscription
        },
      );
    }
  }

  Future<void> _onSendMediaMessage(
    SendMediaMessage event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final result = await _messageRepository.sendMessage(
        conversationId: _conversationId!,
        content: '',
        type: event.type,
        mediaFile: event.mediaFile,
      );
      
      result.fold(
        (failure) => emit(ChatError(message: failure.message)),
        (message) {
          // Message will be added via stream subscription
        },
      );
    }
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded && !currentState.isLoadingMore && currentState.hasMore) {
      emit(currentState.copyWith(isLoadingMore: true));
      
      final result = await _messageRepository.getMessages(
        conversationId: _conversationId!,
        limit: 50,
        beforeMessageId: _lastMessageId,
      );
      
      result.fold(
        (failure) => emit(ChatError(message: failure.message)),
        (newMessages) {
          _messages.addAll(newMessages);
          _lastMessageId = newMessages.isNotEmpty ? newMessages.last.id : _lastMessageId;
          
          emit(currentState.copyWith(
            messages: List.from(_messages),
            hasMore: newMessages.length >= 50,
            isLoadingMore: false,
          ));
        },
      );
    }
  }

  Future<void> _onMarkMessageAsRead(
    MarkMessageAsRead event,
    Emitter<ChatState> emit,
  ) async {
    await _messageRepository.markAsRead(
      conversationId: _conversationId!,
      messageId: event.messageId,
    );
  }

  Future<void> _onDeleteMessage(
    DeleteMessage event,
    Emitter<ChatState> emit,
  ) async {
    await _messageRepository.deleteMessage(
      conversationId: _conversationId!,
      messageId: event.messageId,
    );
  }

  Future<void> _onSetTypingStatus(
    SetTypingStatus event,
    Emitter<ChatState> emit,
  ) async {
    await _messageRepository.setTypingStatus(
      conversationId: _conversationId!,
      isTyping: event.isTyping,
    );
  }

  void _subscribeToMessages() {
    _messagesSubscription?.cancel();
    _messagesSubscription = _messageRepository
        .watchMessages(_conversationId!)
        .listen((messages) {
      final currentState = state;
      if (currentState is ChatLoaded) {
        _messages = messages;
        emit(currentState.copyWith(messages: messages));
      }
    });
  }

  void _subscribeToTyping() {
    _typingSubscription?.cancel();
    _typingSubscription = _messageRepository
        .watchTypingStatus(_conversationId!)
        .listen((typingStatus) {
      final currentState = state;
      if (currentState is ChatLoaded) {
        emit(currentState.copyWith(typingStatus: typingStatus));
      }
    });
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    return super.close();
  }
}