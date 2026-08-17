// lib/presentation/blocs/chat/chat_bloc.dart

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
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
import 'package:hivmeet/domain/usecases/profile/block_user.dart';
import 'package:hivmeet/domain/usecases/profile/report_user.dart';
import 'package:hivmeet/core/realtime/realtime_event.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
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
/// - Temps réel via WebSocket (message.created, message.read, typing.indicator, presence.update)
@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetMessages _getMessages;
  final send_text.SendTextMessage _sendTextMessage;
  final SendMediaMessage _sendMediaMessage;
  final MarkMessageAsRead _markMessageAsRead;
  final SetTypingStatusUseCase _setTypingStatus;
  final DeleteMessage _deleteMessage;
  final BlockUser _blockUser;
  final ReportUser _reportUser;
  final AuthenticationService _authService;
  final ChatWebSocketService _wsService;
  final RealtimeEventBus _realtimeBus;

  // État interne
  String? _conversationId;
  List<Message> _allMessages = [];
  bool _hasMore = true;
  bool _showPremiumPrompt = false;
  StreamSubscription<WsEvent>? _wsSub;
  final Set<String> _pendingReadCursors = <String>{};

  /// Trie les messages par date croissante (plus ancien en premier).
  ///
  /// Le backend retourne les messages par ordre décroissant ; on normalise
  /// localement pour que l'UI affiche la conversation dans le sens chronologique
  /// (scroll vers le bas = messages récents).
  List<Message> _sortByCreatedAt(List<Message> messages) {
    return List<Message>.from(messages)
      ..sort((a, b) {
        final dateCompare = a.createdAt.compareTo(b.createdAt);
        if (dateCompare != 0) return dateCompare;
        // Ordre stable déterministe en cas de dates identiques.
        return a.id.compareTo(b.id);
      });
  }

  ChatBloc({
    required GetMessages getMessages,
    required send_text.SendTextMessage sendTextMessage,
    required SendMediaMessage sendMediaMessage,
    required MarkMessageAsRead markMessageAsRead,
    required SetTypingStatusUseCase setTypingStatus,
    required DeleteMessage deleteMessage,
    required BlockUser blockUser,
    required ReportUser reportUser,
    required AuthenticationService authService,
    required ChatWebSocketService wsService,
    required RealtimeEventBus realtimeBus,
  })  : _getMessages = getMessages,
        _sendTextMessage = sendTextMessage,
        _sendMediaMessage = sendMediaMessage,
        _markMessageAsRead = markMessageAsRead,
        _setTypingStatus = setTypingStatus,
        _deleteMessage = deleteMessage,
        _blockUser = blockUser,
        _reportUser = reportUser,
        _authService = authService,
        _wsService = wsService,
        _realtimeBus = realtimeBus,
        super(ChatInitial()) {
    on<LoadConversation>(_onLoadConversation);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendTextMessageEvent>(_onSendTextMessage);
    on<SendMediaMessageEvent>(_onSendMediaMessage);
    on<MarkAsReadEvent>(_onMarkAsRead);
    on<MarkUnreadMessagesAsRead>(_onMarkUnreadMessagesAsRead);
    on<SetTypingStatus>(_onSetTypingStatus);
    on<DeleteMessageEvent>(_onDeleteMessage);
    on<BlockUserEvent>(_onBlockUser);
    on<ReportUserEvent>(_onReportUser);
    on<ClearChatActionFeedback>(_onClearChatActionFeedback);
    on<ConnectToWebSocket>(_onConnectWebSocket);
    on<DisconnectFromWebSocket>(_onDisconnectWebSocket);
    on<ResyncMessages>(_onResyncMessages);
    on<_WebSocketMessageReceived>(_onWsMessageReceived);
    on<_WebSocketMessageRead>(_onWsMessageRead);
    on<_WebSocketMessageDelivered>(_onWsMessageDelivered);
    on<_WebSocketTypingIndicator>(_onWsTypingIndicator);
    on<_WebSocketPresenceUpdate>(_onWsPresenceUpdate);
  }

  Future<void> _onLoadConversation(
    LoadConversation event,
    Emitter<ChatState> emit,
  ) async {
    _conversationId = event.conversationId;
    _pendingReadCursors.clear();
    emit(ChatLoading());

    final params = GetMessagesParams.initial(event.conversationId);
    final result = await _getMessages(params);

    result.fold(
      (failure) => emit(ChatError(message: failure.message)),
      (page) {
        _allMessages = _sortByCreatedAt(page.messages);
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
    if (oldestMessage == null) {
      emit(currentState.copyWith(isLoadingMore: false));
      return;
    }

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
        _allMessages = _sortByCreatedAt([...page.messages, ..._allMessages]);
        _hasMore = page.hasMore;

        emit(currentState.copyWith(
          messages: _allMessages,
          hasMore: _hasMore,
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

    final currentUserId = _authService.currentUser?.id ?? 'unknown';
    final clientMessageId = _buildClientMessageId();
    final optimisticMessage = Message(
      id: 'temp_$clientMessageId',
      clientMessageId: clientMessageId,
      conversationId: _conversationId!,
      senderId: currentUserId,
      isMine: true,
      content: event.content,
      type: MessageType.text,
      createdAt: DateTime.now(),
      isSending: true,
      isRead: false,
      status: MessageStatus.sending,
      reactions: const {},
    );

    // Optimistic update
    _allMessages = _sortByCreatedAt([..._allMessages, optimisticMessage]);
    emit(currentState.copyWith(messages: _allMessages));

    // Envoi réel
    final params = send_text.SendTextMessageParams(
      conversationId: _conversationId!,
      content: event.content,
      clientMessageId: clientMessageId,
    );

    final result = await _sendTextMessage(params);

    result.fold(
      (failure) {
        // Rollback: marquer le message optimiste comme failed
        final failedMessage = optimisticMessage.copyWith(
          status: MessageStatus.failed,
          isSending: false,
        );
        _allMessages = _sortByCreatedAt(_allMessages.map((m) {
          return m.id == optimisticMessage.id ? failedMessage : m;
        }).toList());
        emit(currentState.copyWith(messages: _allMessages));
      },
      (sentMessage) {
        _replaceOptimisticMessage(
          optimisticMessage: optimisticMessage,
          sentMessage: sentMessage.copyWith(isMine: true, isSending: false),
        );
        _allMessages = _sortByCreatedAt(_allMessages);
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

    final currentUserId = _authService.currentUser?.id ?? 'unknown';
    final clientMessageId = _buildClientMessageId();
    final optimisticMessage = Message(
      id: 'temp_$clientMessageId',
      clientMessageId: clientMessageId,
      conversationId: _conversationId!,
      senderId: currentUserId,
      isMine: true,
      content: '',
      type: event.type,
      createdAt: DateTime.now(),
      isSending: true,
      isRead: false,
      status: MessageStatus.sending,
      reactions: const {},
    );

    // Optimistic update
    _allMessages = _sortByCreatedAt([..._allMessages, optimisticMessage]);
    emit(currentState.copyWith(messages: _allMessages));

    // Envoi réel
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
          isSending: false,
        );
        _allMessages = _sortByCreatedAt(_allMessages.map((m) {
          return m.id == optimisticMessage.id ? failedMessage : m;
        }).toList());
        emit(currentState.copyWith(messages: _allMessages));
      },
      (sentMessage) {
        _replaceOptimisticMessage(
          optimisticMessage: optimisticMessage,
          sentMessage: sentMessage.copyWith(isMine: true, isSending: false),
        );
        _allMessages = _sortByCreatedAt(_allMessages);
        emit(currentState.copyWith(messages: _allMessages));
      },
    );
  }

  void _replaceOptimisticMessage({
    required Message optimisticMessage,
    required Message sentMessage,
  }) {
    var replaced = false;
    _allMessages = _allMessages.map((message) {
      final sameClientId = optimisticMessage.clientMessageId != null &&
          message.clientMessageId == optimisticMessage.clientMessageId;
      if (message.id == optimisticMessage.id || sameClientId) {
        replaced = true;
        return sentMessage;
      }
      return message;
    }).toList();

    if (!replaced &&
        !_allMessages.any((message) => message.id == sentMessage.id)) {
      _allMessages = [..._allMessages, sentMessage];
    }
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

  /// Marque le dernier message non-lu de l'interlocuteur comme lu.
  ///
  /// À appeler quand l'utilisateur ouvre la conversation ou atteint le bas de
  /// la liste. Évite les appels inutiles si le dernier message est déjà lu.
  Future<void> _onMarkUnreadMessagesAsRead(
    MarkUnreadMessagesAsRead event,
    Emitter<ChatState> emit,
  ) async {
    if (_conversationId == null) return;

    final currentState = state;
    if (currentState is! ChatLoaded) return;

    final lastMessageFromOther = _allMessages.lastWhereOrNull(
      (m) => !m.isMine && !m.isRead,
    );
    if (lastMessageFromOther == null) return;

    final params = MarkMessageAsReadParams(
      conversationId: _conversationId!,
      messageId: lastMessageFromOther.id,
    );

    if (!_pendingReadCursors.add(lastMessageFromOther.id)) return;

    final result = await _markMessageAsRead(params);
    result.fold(
      (_) => _pendingReadCursors.remove(lastMessageFromOther.id),
      (_) {
        final cursorIndex = _allMessages.indexWhere(
          (message) => message.id == lastMessageFromOther.id,
        );
        if (cursorIndex >= 0) {
          _allMessages = List<Message>.generate(
            _allMessages.length,
            (index) => index <= cursorIndex &&
                    !_allMessages[index].isMine &&
                    !_allMessages[index].isRead
                ? _allMessages[index].copyWith(isRead: true)
                : _allMessages[index],
          );
          final latestState = state;
          if (latestState is ChatLoaded) {
            emit(latestState.copyWith(messages: _allMessages));
          }
        }
        _pendingReadCursors.remove(lastMessageFromOther.id);
        _realtimeBus.publish(RealtimeEvent(
          type: RealtimeEventType.conversationRead,
          source: RealtimeSource.local,
          conversationId: _conversationId,
        ));
      },
    );
  }

  /// Appelle l'API REST de typing ET notifie le serveur via WebSocket si connecté.
  ///
  /// Ne modifie PAS `isTyping` de l'état local ici: ce champ reflète l'état
  /// de frappe de l'INTERLOCUTEUR (mis à jour uniquement par
  /// `_onWsTypingIndicator`, alimenté par le WS entrant). Simuler son propre
  /// typing localement serait trompeur (l'utilisateur se verrait "en train
  /// d'écrire" lui-même) et n'apportait aucun bénéfice UX réel.
  Future<void> _onSetTypingStatus(
    SetTypingStatus event,
    Emitter<ChatState> emit,
  ) async {
    if (_conversationId == null) return;

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
        _allMessages = _sortByCreatedAt(_allMessages);
        emit(currentState.copyWith(messages: _allMessages));
      },
      (_) {
        // Confirmer: mettre à jour le cache interne
        _allMessages = _sortByCreatedAt(optimisticMessages);
      },
    );
  }

  // ─── WebSocket handlers ───────────────────────────────────────────────────

  Future<void> _onBlockUser(
    BlockUserEvent event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    final result = await _blockUser(BlockUserParams(userId: event.userId));
    result.fold(
      (failure) => emit(currentState.copyWith(actionError: failure.message)),
      (_) => emit(currentState.copyWith(completedAction: ChatUserAction.block)),
    );
  }

  Future<void> _onReportUser(
    ReportUserEvent event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    final result = await _reportUser(ReportUserParams(
      userId: event.userId,
      reason: event.reason,
      description: event.description,
    ));
    result.fold(
      (failure) => emit(currentState.copyWith(actionError: failure.message)),
      (_) =>
          emit(currentState.copyWith(completedAction: ChatUserAction.report)),
    );
  }

  void _onClearChatActionFeedback(
    ClearChatActionFeedback event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    emit(currentState.copyWith(
      completedAction: null,
      actionError: null,
    ));
  }

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
      onNeedFreshToken: _authService.getAccessToken,
    );

    await _wsSub?.cancel();
    _wsSub = _wsService.events.listen((wsEvent) {
      switch (wsEvent.type) {
        case WsEventType.reconnected:
          add(const ResyncMessages());
        case WsEventType.messageCreated:
          add(_WebSocketMessageReceived(wsEvent.data));
        case WsEventType.messageRead:
          final rawReaderId = wsEvent.data['reader_id'];
          final readerId = rawReaderId is String ? rawReaderId : '';
          final rawIds = wsEvent.data['message_ids'];
          final messageIds = rawIds is List
              ? rawIds
                  .where((value) => value != null)
                  .map((value) => value.toString())
                  .where((id) => id.isNotEmpty)
                  .toSet()
              : <String>{};
          final rawReadAt = wsEvent.data['read_at'];
          final readAtRaw = rawReadAt is String ? rawReadAt : null;

          if (readerId.isEmpty || messageIds.isEmpty) break;

          add(_WebSocketMessageRead(
            readerId: readerId,
            messageIds: messageIds,
            readAt: readAtRaw == null ? null : DateTime.tryParse(readAtRaw),
          ));
        case WsEventType.messageDelivered:
          final rawIds = wsEvent.data['message_ids'];
          final messageIds = rawIds is List
              ? rawIds
                  .where((value) => value != null)
                  .map((value) => value.toString())
                  .where((id) => id.isNotEmpty)
                  .toSet()
              : <String>{};
          final rawDeliveredAt = wsEvent.data['delivered_at'];
          final deliveredAtRaw =
              rawDeliveredAt is String ? rawDeliveredAt : null;

          if (messageIds.isEmpty) break;

          add(_WebSocketMessageDelivered(
            messageIds: messageIds,
            deliveredAt: deliveredAtRaw == null
                ? null
                : DateTime.tryParse(deliveredAtRaw),
          ));
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
          final timestamp = wsEvent.data['timestamp'] as String?;
          add(_WebSocketPresenceUpdate(
            userId: userId,
            isOnline: status == 'online',
            lastActive: timestamp == null ? null : DateTime.tryParse(timestamp),
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

  /// Resynchronise les messages après une reconnexion WebSocket automatique.
  ///
  /// Le serveur ne rejoue pas les événements manqués pendant une coupure :
  /// on refait un appel REST sur la page la plus récente et on fusionne
  /// dans l'historique local déjà chargé (dédup par id/clientMessageId, via
  /// [_mergeIncomingMessages]) pour rattraper d'éventuels messages ratés.
  Future<void> _onResyncMessages(
    ResyncMessages event,
    Emitter<ChatState> emit,
  ) async {
    if (_conversationId == null) return;
    if (state is! ChatLoaded) return;

    final result =
        await _getMessages(GetMessagesParams.initial(_conversationId!));
    result.fold(
      (_) {
        // Échec silencieux : l'état affiché reste inchangé, le prochain
        // événement WS ou la prochaine ouverture du chat retentera.
      },
      (page) {
        final latestState = state;
        if (latestState is! ChatLoaded) return;
        _allMessages = _mergeIncomingMessages(page.messages);
        emit(latestState.copyWith(messages: _allMessages));
      },
    );
  }

  /// Fusionne des messages entrants (WebSocket ou resync REST) dans
  /// `_allMessages`, en évitant les doublons par `id` ou `clientMessageId`,
  /// puis retrie chronologiquement.
  List<Message> _mergeIncomingMessages(List<Message> incoming) {
    var messages = _allMessages;
    for (final newMessage in incoming) {
      final existingIndex = messages.indexWhere((message) {
        final sameMessageId =
            newMessage.id.isNotEmpty && message.id == newMessage.id;
        final sameClientId = newMessage.clientMessageId != null &&
            newMessage.clientMessageId!.isNotEmpty &&
            message.clientMessageId == newMessage.clientMessageId;
        return sameMessageId || sameClientId;
      });
      if (existingIndex >= 0) {
        messages = [
          ...messages.take(existingIndex),
          newMessage,
          ...messages.skip(existingIndex + 1),
        ];
      } else {
        messages = [...messages, newMessage];
      }
    }
    return _sortByCreatedAt(messages);
  }

  /// Intègre un message entrant via WebSocket dans la liste locale.
  void _onWsMessageReceived(
    _WebSocketMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    final messageId = event.data['message_id'] as String? ?? '';
    final clientMessageId = event.data['client_message_id'] as String?;
    final currentUserId = _authService.currentUser?.id ?? '';
    final senderId = event.data['sender_id'] as String? ?? '';
    final messageType =
        _stringToMessageType(event.data['message_type'] as String? ?? 'text');
    final sentAtRaw = event.data['sent_at'] as String?;
    final sentAt = sentAtRaw != null
        ? DateTime.tryParse(sentAtRaw) ?? DateTime.now()
        : DateTime.now();

    final newMessage = Message(
      id: messageId,
      clientMessageId: clientMessageId,
      conversationId:
          event.data['conversation_id'] as String? ?? _conversationId ?? '',
      senderId: senderId,
      content: event.data['content'] as String? ?? '',
      type: messageType,
      createdAt: sentAt,
      sentAt: sentAt,
      isRead: false,
      isMine: senderId == currentUserId,
      mediaUrl: event.data['media_url'] as String?,
      mediaType: event.data['media_type'] as String?,
      mediaThumbnailUrl: event.data['media_thumbnail_url'] as String?,
      status: MessageStatus.sent,
      reactions: const {},
    );

    _allMessages = _mergeIncomingMessages([newMessage]);
    emit(currentState.copyWith(messages: _allMessages));
  }

  /// Met à jour les seuls messages envoyés par l'utilisateur courant lorsque
  /// l'autre participant confirme les avoir lus.
  void _onWsMessageRead(
    _WebSocketMessageRead event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    final currentUserId = _authService.currentUser?.id ?? '';
    if (event.readerId.isEmpty || event.readerId == currentUserId) return;

    var changed = false;
    final updatedMessages = _allMessages.map((message) {
      final shouldMarkRead =
          message.isMine && event.messageIds.contains(message.id);
      if (!shouldMarkRead) return message;

      final updatedMessage = message.copyWith(
        status: MessageStatus.read,
        isRead: true,
        readAt: event.readAt ?? message.readAt,
        readAtByRecipient: event.readAt ?? message.readAtByRecipient,
      );
      if (updatedMessage != message) changed = true;
      return updatedMessage;
    }).toList();

    if (!changed) return;
    _allMessages = updatedMessages;
    emit(currentState.copyWith(messages: _allMessages));
  }

  /// Met à jour les seuls messages envoyés par l'utilisateur courant lorsque
  /// le serveur confirme leur livraison à l'appareil du destinataire.
  ///
  /// Garde de monotonie : un message déjà marqué [MessageStatus.read] ne doit
  /// jamais régresser vers [MessageStatus.delivered] — l'accusé de lecture
  /// est un état strictement plus avancé que l'accusé de livraison, et un
  /// paquet réseau réordonné pourrait faire arriver le `delivered` après le
  /// `read`.
  void _onWsMessageDelivered(
    _WebSocketMessageDelivered event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    var changed = false;
    final updatedMessages = _allMessages.map((message) {
      final shouldMarkDelivered =
          message.isMine && event.messageIds.contains(message.id);
      if (!shouldMarkDelivered) return message;
      // Un message déjà lu ne doit jamais régresser vers « livré ».
      if (message.status == MessageStatus.read) return message;

      final updatedMessage = message.copyWith(
        status: MessageStatus.delivered,
        isDelivered: true,
        deliveredAt: event.deliveredAt ?? message.deliveredAt,
      );
      if (updatedMessage != message) changed = true;
      return updatedMessage;
    }).toList();

    if (!changed) return;
    _allMessages = updatedMessages;
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
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    final currentUserId = _authService.currentUser?.id ?? '';
    if (event.userId == currentUserId) return;

    emit(currentState.copyWith(
      otherIsOnline: event.isOnline,
      otherLastActive: event.lastActive,
    ));
  }

  /// Anti-collision : suffixe aléatoire en plus du micro-timestamp. Deux
  /// envois dans la même microseconde produiraient sinon le même
  /// client_message_id, et le backend traiterait le second comme un
  /// doublon du premier (dédup par client_message_id côté serveur), le
  /// droppant silencieusement.
  String _buildClientMessageId() {
    final randomSuffix = Random().nextInt(1 << 31);
    return 'client_${_conversationId!}_${DateTime.now().microsecondsSinceEpoch}_$randomSuffix';
  }

  MessageType _stringToMessageType(String type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'audio':
        return MessageType.audio;
      case 'voice':
        return MessageType.voice;
      case 'call_log':
        return MessageType.callLog;
      case 'system':
        return MessageType.system;
      case 'text':
      default:
        return MessageType.text;
    }
  }

  @override
  Future<void> close() async {
    await _wsSub?.cancel();
    _wsService.dispose();
    return super.close();
  }
}
