// lib/presentation/blocs/chat/chat_bloc.dart

import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/usecases/chat/get_messages.dart';
import 'package:hivmeet/domain/usecases/chat/send_text_message.dart' as send_text;
import 'package:hivmeet/domain/usecases/chat/send_media_message.dart';
import 'package:hivmeet/domain/usecases/chat/mark_message_as_read.dart';

part 'chat_event.dart';
part 'chat_state.dart';

/// BLoC pour gérer le chat (conversation)
///
/// Features:
/// - Chargement des messages avec pagination
/// - Envoi de messages texte et média
/// - Optimistic updates pour l'envoi
/// - Marquer messages comme lus automatiquement
/// - Indicateur de frappe (typing)
/// - Load more avec pagination
///
/// Architecture: 100% Clean Architecture avec Use Cases
@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetMessages _getMessages;
  final send_text.SendTextMessage _sendTextMessage;
  final SendMediaMessage _sendMediaMessage;
  final MarkMessageAsRead _markMessageAsRead;

  // État interne pour pagination
  String? _conversationId;
  List<Message> _allMessages = [];
  bool _hasMore = true;

  ChatBloc({
    required GetMessages getMessages,
    required send_text.SendTextMessage sendTextMessage,
    required SendMediaMessage sendMediaMessage,
    required MarkMessageAsRead markMessageAsRead,
  })  : _getMessages = getMessages,
        _sendTextMessage = sendTextMessage,
        _sendMediaMessage = sendMediaMessage,
        _markMessageAsRead = markMessageAsRead,
        super(ChatInitial()) {
    on<LoadConversation>(_onLoadConversation);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendTextMessageEvent>(_onSendTextMessage);
    on<SendMediaMessageEvent>(_onSendMediaMessage);
    on<MarkAsReadEvent>(_onMarkAsRead);
    on<SetTypingStatus>(_onSetTypingStatus);
  }

  Future<void> _onLoadConversation(
    LoadConversation event,
    Emitter<ChatState> emit,
  ) async {
    _conversationId = event.conversationId;
    emit(ChatLoading());

    final params = GetMessagesParams.initial(event.conversationId);
    final result = await _getMessages(params);

    result.fold(
      (failure) => emit(ChatError(message: failure.message)),
      (messages) {
        _allMessages = messages;
        _hasMore = messages.length >= 50; // Si on a 50 messages, il y en a peut-être plus

        emit(ChatLoaded(
          messages: _allMessages,
          hasMore: _hasMore,
          isTyping: false,
          isLoadingMore: false,
        ));
      },
    );
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded || !_hasMore || _conversationId == null) {
      return;
    }

    if (currentState.isLoadingMore) return; // Éviter double load

    // Marquer comme loading more
    emit(currentState.copyWith(isLoadingMore: true));

    // Obtenir le message le plus ancien pour pagination
    final oldestMessage = _allMessages.isNotEmpty ? _allMessages.first : null;
    if (oldestMessage == null) return;

    final params = GetMessagesParams(
      conversationId: _conversationId!,
      beforeMessageId: oldestMessage.id,
    );

    final result = await _getMessages(params);

    result.fold(
      (failure) {
        emit(currentState.copyWith(isLoadingMore: false));
      },
      (newMessages) {
        _allMessages = [...newMessages, ..._allMessages];
        _hasMore = newMessages.length >= 50;

        emit(ChatLoaded(
          messages: _allMessages,
          hasMore: _hasMore,
          isTyping: currentState.isTyping,
          isLoadingMore: false,
        ));
      },
    );
  }

  Future<void> _onSendTextMessage(
    SendTextMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded || _conversationId == null) return;

    // Créer message optimiste
    final optimisticMessage = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _conversationId!,
      senderId: 'current_user', // TODO: Obtenir du AuthService
      content: event.content,
      type: MessageType.text,
      createdAt: DateTime.now(),
      isRead: false,
      status: MessageStatus.sending,
      reactions: const {},
    );

    // Optimistic update
    final updatedMessages = [..._allMessages, optimisticMessage];
    emit(currentState.copyWith(messages: updatedMessages));

    // Envoi réel
    final params = send_text.SendTextMessageParams(
      conversationId: _conversationId!,
      content: event.content,
    );

    final result = await _sendTextMessage(params);

    result.fold(
      (failure) {
        // Rollback: retirer le message optimiste et marquer comme failed
        final failedMessage = optimisticMessage.copyWith(
          status: MessageStatus.failed,
        );
        final messagesWithFailed = [
          ..._allMessages,
          failedMessage,
        ];
        emit(currentState.copyWith(messages: messagesWithFailed));
      },
      (sentMessage) {
        // Remplacer le message optimiste par le vrai message du serveur
        final finalMessages = _allMessages.map((m) {
          return m.id == optimisticMessage.id ? sentMessage : m;
        }).toList()
          ..add(sentMessage);

        _allMessages = finalMessages;
        emit(currentState.copyWith(messages: _allMessages));
      },
    );
  }

  Future<void> _onSendMediaMessage(
    SendMediaMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded || _conversationId == null) return;

    // Créer message optimiste
    final optimisticMessage = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _conversationId!,
      senderId: 'current_user', // TODO: Obtenir du AuthService
      content: '',
      type: event.type,
      createdAt: DateTime.now(),
      isRead: false,
      status: MessageStatus.sending,
      reactions: const {},
    );

    // Optimistic update
    final updatedMessages = [..._allMessages, optimisticMessage];
    emit(currentState.copyWith(messages: updatedMessages));

    // Envoi réel
    final params = SendMediaMessageParams(
      conversationId: _conversationId!,
      mediaFile: event.mediaFile,
      type: event.type,
    );

    final result = await _sendMediaMessage(params);

    result.fold(
      (failure) {
        // Rollback: marquer comme failed
        final failedMessage = optimisticMessage.copyWith(
          status: MessageStatus.failed,
        );
        final messagesWithFailed = _allMessages.map((m) {
          return m.id == optimisticMessage.id ? failedMessage : m;
        }).toList();
        emit(currentState.copyWith(messages: messagesWithFailed));
      },
      (sentMessage) {
        // Remplacer le message optimiste par le vrai message du serveur
        final finalMessages = _allMessages.map((m) {
          return m.id == optimisticMessage.id ? sentMessage : m;
        }).toList();

        _allMessages = finalMessages;
        emit(currentState.copyWith(messages: _allMessages));
      },
    );
  }

  Future<void> _onMarkAsRead(
    MarkAsReadEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (_conversationId == null) return;

    final params = MarkMessageAsReadParams(
      conversationId: _conversationId!,
      messageId: event.messageId,
    );

    await _markMessageAsRead(params);
    // Pas besoin d'émettre un nouvel état, le message sera marqué comme lu par le serveur
  }

  void _onSetTypingStatus(
    SetTypingStatus event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(currentState.copyWith(isTyping: event.isTyping));
    }
  }
}
