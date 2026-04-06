// lib/presentation/blocs/chat/chat_bloc.dart

import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/usecases/chat/get_messages.dart';
import 'package:hivmeet/domain/usecases/chat/send_text_message.dart'
    as send_text;
import 'package:hivmeet/domain/usecases/chat/send_media_message.dart';
import 'package:hivmeet/domain/usecases/chat/mark_message_as_read.dart';
import 'package:hivmeet/domain/usecases/chat/set_typing_status.dart';
import 'package:hivmeet/domain/usecases/chat/delete_message.dart';
import 'package:hivmeet/core/services/authentication_service.dart';
import 'package:hivmeet/core/services/chat_websocket_service.dart';

part 'chat_event.dart';
part 'chat_state.dart';

/// BLoC pour gérer le chat (conversation)
///
/// Features:
/// - Chargement des messages avec pagination
/// - Envoi de messages texte et média
/// - Optimistic updates pour l'envoi
/// - Marquer messages comme lus automatiquement
/// - Indicateur de frappe (typing) — via API REST et WebSocket
/// - Suppression de message — via API REST
/// - Temps réel via WebSocket (message.created, typing.indicator, presence.update)
@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetMessages _getMessages;
  final send_text.SendTextMessage _sendTextMessage;
  final SendMediaMessage _sendMediaMessage;
  final MarkMessageAsRead _markMessageAsRead;
  final SetTypingStatusUseCase _setTypingStatus;
  final DeleteMessage _deleteMessage;
  final AuthenticationService _authService;
  final ChatWebSocketService _wsService;

  // État interne
  String? _conversationId;
  List<Message> _allMessages = [];
  bool _hasMore = true;
  bool _showPremiumPrompt = false;
  StreamSubscription<WsEvent>? _wsSub;

  ChatBloc({
    required GetMessages getMessages,
    required send_text.SendTextMessage sendTextMessage,
    required SendMediaMessage sendMediaMessage,
    required MarkMessageAsRead markMessageAsRead,
    required SetTypingStatusUseCase setTypingStatus,
    required DeleteMessage deleteMessage,
    required AuthenticationService authService,
    required ChatWebSocketService wsService,
  })  : _getMessages = getMessages,
        _sendTextMessage = sendTextMessage,
        _sendMediaMessage = sendMediaMessage,
        _markMessageAsRead = markMessageAsRead,
        _setTypingStatus = setTypingStatus,
        _deleteMessage = deleteMessage,
        _authService = authService,
        _wsService = wsService,
        super(ChatInitial()) {
    on<LoadConversation>(_onLoadConversation);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendTextMessageEvent>(_onSendTextMessage);
    on<SendMediaMessageEvent>(_onSendMediaMessage);
    on<MarkAsReadEvent>(_onMarkAsRead);
    on<SetTypingStatus>(_onSetTypingStatus);
    on<DeleteMessageEvent>(_onDeleteMessage);
    on<ConnectToWebSocket>(_onConnectWebSocket);
    on<DisconnectFromWebSocket>(_onDisconnectWebSocket);
    on<_WebSocketMessageReceived>(_onWsMessageReceived);
    on<_WebSocketTypingIndicator>(_onWsTypingIndicator);
    on<_WebSocketPresenceUpdate>(_onWsPresenceUpdate);
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
      (page) {
        _allMessages = page.messages;
        _hasMore = page.hasMore;
        _showPremiumPrompt = page.showPremiumPrompt;

        emit(ChatLoaded(
          messages: _allMessages,
          hasMore: _hasMore,
          isTyping: false,
          isLoadingMore: false,
          showPremiumPrompt: _showPremiumPrompt,
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
      (page) {
        _allMessages = [...page.messages, ..._allMessages];
        _hasMore = page.hasMore;

        emit(ChatLoaded(
          messages: _allMessages,
          hasMore: _hasMore,
          isTyping: currentState.isTyping,
          isLoadingMore: false,
          showPremiumPrompt: _showPremiumPrompt,
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
    final currentUserId = _authService.currentUser?.id ?? 'unknown';
    final optimisticMessage = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _conversationId!,
      senderId: currentUserId,
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
    final clientMessageId =
        'client_${_conversationId!}_${optimisticMessage.id}';
    final params = send_text.SendTextMessageParams(
      conversationId: _conversationId!,
      content: event.content,
      clientMessageId: clientMessageId,
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
        final finalMessages = updatedMessages.map((m) {
          return m.id == optimisticMessage.id ? sentMessage : m;
        }).toList();

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
    final currentUserId = _authService.currentUser?.id ?? 'unknown';
    final optimisticMessage = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _conversationId!,
      senderId: currentUserId,
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
    final clientMessageId =
        'client_${_conversationId!}_${optimisticMessage.id}';
    final params = SendMediaMessageParams(
      conversationId: _conversationId!,
      mediaFile: event.mediaFile,
      type: event.type,
      clientMessageId: clientMessageId,
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
        final finalMessages = updatedMessages.map((m) {
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

  /// Appelle l'API REST de typing ET notifie le serveur via WebSocket si connecté.
  Future<void> _onSetTypingStatus(
    SetTypingStatus event,
    Emitter<ChatState> emit,
  ) async {
    if (_conversationId == null) return;

    // Mise à jour locale immédiate de l'indicateur de saisie
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(currentState.copyWith(isTyping: currentState.isTyping));
    }

    // Appel API REST (POST /conversations/{id}/typing/)
    final params = SetTypingStatusParams(
      conversationId: _conversationId!,
      isTyping: event.isTyping,
    );
    await _setTypingStatus(params);

    // Indicateur via WebSocket si connexion ouverte
    if (_wsService.isConnected) {
      _wsService.sendTyping(event.isTyping);
    }
  }

  /// Supprime le message côté serveur (DELETE) puis retire localement.
  Future<void> _onDeleteMessage(
    DeleteMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded || _conversationId == null) return;

    // Retrait optimiste immédiat
    final optimisticMessages =
        _allMessages.where((m) => m.id != event.messageId).toList();
    emit(currentState.copyWith(messages: optimisticMessages));

    // Appel API de suppression
    final params = DeleteMessageParams(
      conversationId: _conversationId!,
      messageId: event.messageId,
    );
    final result = await _deleteMessage(params);

    result.fold(
      (failure) {
        // Rollback si l'appel échoue
        if (kDebugMode) {
          debugPrint('[ChatBloc] Delete failed: ${failure.message}');
        }
        emit(currentState.copyWith(messages: _allMessages));
      },
      (_) {
        // Confirmer: mettre à jour le cache interne
        _allMessages = optimisticMessages;
      },
    );
  }

  // ─── WebSocket handlers ───────────────────────────────────────────────────

  Future<void> _onConnectWebSocket(
    ConnectToWebSocket event,
    Emitter<ChatState> emit,
  ) async {
    if (_conversationId == null) return;

    final token = await _authService.getAccessToken();
    if (token == null) return;

    await _wsService.connect(
      conversationId: _conversationId!,
      token: token,
    );

    await _wsSub?.cancel();
    _wsSub = _wsService.events.listen((wsEvent) {
      switch (wsEvent.type) {
        case WsEventType.messageCreated:
          add(_WebSocketMessageReceived(wsEvent.data));
        case WsEventType.typingIndicator:
          final userId = wsEvent.data['user_id'] as String? ?? '';
          final status = wsEvent.data['status'] as String? ?? '';
          add(_WebSocketTypingIndicator(
            userId: userId,
            isTyping: status == 'typing',
          ));
        case WsEventType.presenceUpdate:
          final userId = wsEvent.data['user_id'] as String? ?? '';
          final status = wsEvent.data['status'] as String? ?? '';
          add(_WebSocketPresenceUpdate(
            userId: userId,
            isOnline: status == 'online',
          ));
        case WsEventType.error:
          if (kDebugMode) {
            debugPrint('[ChatBloc][WS] Error: ${wsEvent.data}');
          }
        default:
          break;
      }
    });
  }

  Future<void> _onDisconnectWebSocket(
    DisconnectFromWebSocket event,
    Emitter<ChatState> emit,
  ) async {
    await _wsSub?.cancel();
    _wsSub = null;
    _wsService.disconnect();
  }

  /// Intègre un message entrant via WebSocket dans la liste locale.
  void _onWsMessageReceived(
    _WebSocketMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    final messageId = event.data['message_id'] as String? ?? '';
    // Éviter les doublons (peut arriver si message envoyé par cet appareil)
    if (_allMessages.any((m) => m.id == messageId)) return;

    final currentUserId = _authService.currentUser?.id ?? '';
    final senderId = event.data['sender_id'] as String? ?? '';
    final content = event.data['content'] as String? ?? '';
    final sentAtRaw = event.data['sent_at'] as String?;
    final sentAt = sentAtRaw != null
        ? DateTime.tryParse(sentAtRaw) ?? DateTime.now()
        : DateTime.now();

    final newMessage = Message(
      id: messageId,
      conversationId:
          event.data['conversation_id'] as String? ?? _conversationId ?? '',
      senderId: senderId,
      content: content,
      type: MessageType.text,
      createdAt: sentAt,
      sentAt: sentAt,
      isRead: false,
      isMine: senderId == currentUserId,
      status: MessageStatus.sent,
      reactions: const {},
    );

    _allMessages = [..._allMessages, newMessage];
    emit(currentState.copyWith(messages: _allMessages));
  }

  /// Met à jour le flag isTyping dans l'état courant.
  void _onWsTypingIndicator(
    _WebSocketTypingIndicator event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    final currentUserId = _authService.currentUser?.id ?? '';
    // N'afficher l'indicateur que pour les messages de l'autre utilisateur
    if (event.userId == currentUserId) return;

    emit(currentState.copyWith(isTyping: event.isTyping));
  }

  void _onWsPresenceUpdate(
    _WebSocketPresenceUpdate event,
    Emitter<ChatState> emit,
  ) {
    // Présence gérée au niveau page/UI; le BLoC émet un état neutre pour notifier
    // le widget chat_page. Pas de changement d'état pour l'instant.
  }

  @override
  Future<void> close() async {
    await _wsSub?.cancel();
    _wsService.dispose();
    return super.close();
  }
}
