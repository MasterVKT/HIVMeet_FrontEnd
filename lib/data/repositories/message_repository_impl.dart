import 'dart:io';
import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/config/app_config.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';
import 'package:hivmeet/data/datasources/remote/messaging_api.dart';

/// Taille max d'un fichier média, alignée sur la limite serveur réelle
/// (`SendMediaMessageView`/`SendMediaMessageSerializer` : 10MB).
const int _kMaxMediaFileSizeBytes = 10 * 1024 * 1024;

@LazySingleton(as: MessageRepository)
class MessageRepositoryImpl implements MessageRepository {
  final MessagingApi _messagingApi;

  const MessageRepositoryImpl(this._messagingApi);

  /// Convertit une URL relative en URL absolue en utilisant apiBaseUrl
  String? _buildAbsoluteUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    return '${AppConfig.apiBaseUrl}/$url';
  }

  @override
  Future<Either<Failure, ConversationListPage>> getConversations({
    int limit = 20,
    int page = 1,
    ConversationFilter filter = ConversationFilter.all,
  }) async {
    try {
      final response = await _messagingApi.getConversations(
        page: page,
        pageSize: limit,
        filter: filter,
      );

      final payload = response.data ?? const <String, dynamic>{};
      final list = (payload['results'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>();

      final conversations = list.map(_mapJsonToConversation).toList();
      // hasMore dérivé du champ DRF `next` (pagination réelle côté backend),
      // plus fiable qu'une heuristique sur la taille de la page.
      final hasMore = payload['next'] != null;

      return Right(
        ConversationListPage(conversations: conversations, hasMore: hasMore),
      );
    } on DioException catch (e) {
      return Left(_mapDioFailure(
        e,
        validationMessageKey: 'conversations.invalid_filter',
      ));
    } catch (e) {
      return Left(_unexpectedFailure('getConversations', e));
    }
  }

  @override
  Stream<List<Conversation>> watchConversations() {
    throw UnimplementedError(
        'Real-time conversations stream not implemented yet');
  }

  @override
  Future<Either<Failure, ConversationMessagesPage>> getMessages({
    required String conversationId,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    try {
      final response = await _messagingApi.getConversationMessages(
        conversationId: conversationId,
        page: 1,
        pageSize: limit,
        beforeMessageId: beforeMessageId,
      );

      final payload = response.data ?? const <String, dynamic>{};
      final list = (payload['results'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>();

      final messages = list.map(_mapJsonToMessage).toList();
      final hasMore = payload['has_more'] as bool? ??
          ((payload['next'] as String?) != null);
      final showPremiumPrompt =
          payload['show_premium_prompt'] as bool? ?? false;

      return Right(
        ConversationMessagesPage(
          messages: messages,
          hasMore: hasMore,
          showPremiumPrompt: showPremiumPrompt,
        ),
      );
    } on DioException catch (e) {
      return Left(_mapDioFailure(e));
    } catch (e) {
      return Left(_unexpectedFailure('getMessages', e));
    }
  }

  @override
  Stream<List<Message>> watchMessages(String conversationId) {
    throw UnimplementedError('Real-time messages stream not implemented yet');
  }

  @override
  Future<Either<Failure, Message>> sendMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
    File? mediaFile,
    String? clientMessageId,
    String? mediaText,
  }) async {
    final effectiveClientMessageId =
        clientMessageId ?? _buildClientMessageId(conversationId);

    try {
      final Response<Map<String, dynamic>> response;

      if (mediaFile != null) {
        // Flux média : multipart direct vers /messages/media/ (Option A).
        // Le backend construit media_url lui-même sur ce path (contrairement
        // au flux "URL signée" qui laissait media_url vide côté serveur).
        final fileLength = await mediaFile.length();
        if (fileLength > _kMaxMediaFileSizeBytes) {
          return Left(ValidationFailure(
            message: LocalizationService.translate('chat.file_too_large'),
            code: 'file-too-large',
          ));
        }

        response = await _messagingApi.sendMediaMessage(
          conversationId: conversationId,
          mediaFilePath: mediaFile.path,
          mediaType: _messageTypeToMediaType(type),
          clientMessageId: effectiveClientMessageId,
          text: mediaText,
        );
      } else {
        response = await _messagingApi.sendTextMessage(
          conversationId: conversationId,
          content: content,
          clientMessageId: effectiveClientMessageId,
        );
      }

      return Right(
          _mapJsonToMessage(response.data ?? const <String, dynamic>{}));
    } on DioException catch (e) {
      return Left(_mapDioFailure(e));
    } catch (e) {
      return Left(_unexpectedFailure('sendMessage', e));
    }
  }

  @override
  Future<Either<Failure, MarkAsReadResult>> markAsRead({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      final response = await _messagingApi.markMessageAsRead(
        conversationId: conversationId,
        lastReadMessageId: messageId,
      );
      final payload = response.data ?? const <String, dynamic>{};
      final rawMarked = payload['messages_marked'] ?? 0;
      final rawUnread = payload['unread_count_for_me'] ?? 0;
      return Right(MarkAsReadResult(
        messagesMarked: rawMarked is int
            ? rawMarked
            : int.tryParse(rawMarked.toString()) ?? 0,
        unreadCountForMe: rawUnread is int
            ? rawUnread
            : int.tryParse(rawUnread.toString()) ?? 0,
        readAt: _parseDateTime(payload['read_at']),
      ));
    } on DioException catch (e) {
      return Left(_mapDioFailure(e));
    } catch (e) {
      return Left(_unexpectedFailure('markAsRead', e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      await _messagingApi.deleteMessage(
        conversationId: conversationId,
        messageId: messageId,
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioFailure(e));
    } catch (e) {
      return Left(_unexpectedFailure('deleteMessage', e));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      final response = await _messagingApi.getUnreadCount();
      final count = response.data?['unread_count'] as int? ?? 0;
      return Right(count);
    } on DioException catch (e) {
      return Left(_mapDioFailure(e));
    } catch (e) {
      return Left(_unexpectedFailure('getUnreadCount', e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteConversation(
      String conversationId) async {
    try {
      await _messagingApi.deleteConversation(conversationId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioFailure(e));
    } catch (e) {
      return Left(_unexpectedFailure('deleteConversation', e));
    }
  }

  @override
  Future<Either<Failure, void>> setTypingStatus({
    required String conversationId,
    required bool isTyping,
  }) async {
    try {
      await _messagingApi.setTypingStatus(
        conversationId: conversationId,
        isTyping: isTyping,
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioFailure(e));
    } catch (e) {
      return Left(_unexpectedFailure('setTypingStatus', e));
    }
  }

  @override
  Future<Either<Failure, ParticipantPresence>> getPresence({
    required String conversationId,
  }) async {
    try {
      final response =
          await _messagingApi.getPresence(conversationId: conversationId);
      final payload = response.data ?? const <String, dynamic>{};
      final participant = (payload['participant'] as Map<String, dynamic>? ??
          const <String, dynamic>{});

      return Right(
        ParticipantPresence(
          userId: (participant['user_id'] ?? '') as String,
          isOnline: participant['is_online'] as bool? ?? false,
          lastActive: _parseDateTime(participant['last_active']),
          isTyping: participant['is_typing'] as bool? ?? false,
        ),
      );
    } on DioException catch (e) {
      return Left(_mapDioFailure(e));
    } catch (e) {
      return Left(_unexpectedFailure('getPresence', e));
    }
  }

  @override
  Stream<Map<String, bool>> watchTypingStatus(String conversationId) {
    throw UnimplementedError(
        'Real-time typing status stream not implemented yet');
  }

  Conversation _mapJsonToConversation(Map<String, dynamic> json) {
    final conversationId =
        (json['conversation_id'] ?? json['id'] ?? '') as String;
    final otherUser = json['other_user'] as Map<String, dynamic>?;
    final otherUserId = (otherUser?['user_id'] ?? '') as String;
    final participantIds = json['participant_ids'] is List
        ? (json['participant_ids'] as List<dynamic>)
            .whereType<String>()
            .toList()
        : otherUserId.isEmpty
            ? const <String>[]
            : <String>[otherUserId];

    final rawUnread = json['unread_count_for_me'] ?? json['unread_count'] ?? 0;
    final unreadCount =
        rawUnread is int ? rawUnread : int.tryParse(rawUnread.toString()) ?? 0;

    final updatedAt = _parseDateTime(
          json['last_activity_at'] ??
              json['last_message_at'] ??
              json['created_at'] ??
              json['updated_at'],
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);

    return Conversation(
      id: conversationId,
      participantIds: participantIds,
      otherUserId: otherUserId.isEmpty ? null : otherUserId,
      otherUserName: otherUser?['display_name'] as String?,
      otherUserPhotoUrl:
          _buildAbsoluteUrl(otherUser?['main_photo_url'] as String?),
      isOnline: otherUser?['is_online'] as bool? ?? false,
      lastActive: _parseDateTime(otherUser?['last_active']),
      lastMessage: json['last_message'] is Map<String, dynamic>
          ? _mapJsonToMessage(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: unreadCount,
      updatedAt: updatedAt,
      lastActivityAt: _parseDateTime(json['last_activity_at']),
    );
  }

  Message _mapJsonToMessage(Map<String, dynamic> json) {
    final messageId = (json['message_id'] ?? json['id'] ?? '') as String;
    final conversationId = (json['conversation_id'] ?? '') as String;
    final senderId = (json['sender_id'] ?? '') as String;
    final content =
        (json['content'] ?? json['content_preview'] ?? '') as String;

    final createdAt = _parseDateTime(json['created_at'] ?? json['sent_at']) ??
        DateTime.fromMillisecondsSinceEpoch(0);

    return Message(
      id: messageId,
      clientMessageId: json['client_message_id'] as String?,
      conversationId: conversationId,
      senderId: senderId,
      isMine: json['is_mine'] as bool? ?? false,
      content: content,
      type: _stringToMessageType(
          (json['message_type'] ?? json['type'] ?? 'text') as String),
      createdAt: createdAt,
      sentAt: _parseDateTime(json['sent_at']),
      deliveredAt: _parseDateTime(json['delivered_at']),
      readAt: _parseDateTime(json['read_at']),
      readAtByRecipient: _parseDateTime(json['read_at_by_recipient']),
      isRead: (json['status'] == 'read') ||
          ((json['read_at'] ?? json['read_at_by_recipient']) != null),
      isDelivered:
          (json['status'] == 'delivered') || (json['delivered_at'] != null),
      isSending: json['is_sending'] as bool? ?? false,
      mediaUrl: _buildAbsoluteUrl(json['media_url'] as String?),
      mediaType: json['media_type'] as String?,
      mediaThumbnailUrl:
          _buildAbsoluteUrl(json['media_thumbnail_url'] as String?),
      // Cast défensif : pas d'endpoint reactions exposé actuellement côté
      // backend (champ toujours vide en pratique), mais si une valeur
      // non-string arrivait un jour (int/null), on ne veut pas crasher toute
      // la conversation pour un simple champ décoratif.
      reactions: (json['reactions'] as Map<String, dynamic>? ??
              const <String, dynamic>{})
          .map((key, value) => MapEntry(key, value?.toString() ?? '')),
      status: _stringToMessageStatus((json['status'] ?? 'sent') as String),
    );
  }

  Failure _mapDioFailure(
    DioException error, {
    String validationMessageKey = 'conversations.request_failed',
  }) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final errorCode = data is Map<String, dynamic> ? data['error'] : null;

    if (statusCode == 401) {
      return AuthFailure(
        message: LocalizationService.translate('conversations.session_expired'),
        code: 'unauthorized',
      );
    }
    if (statusCode == 400) {
      return ValidationFailure(
        message: LocalizationService.translate(validationMessageKey),
        code: 'bad-request',
      );
    }
    // 402 (Payment Required) et 403 avec `error: "premium_required"` (voir
    // `subscriptions.utils.premium_required_response`) sont de vrais gates
    // premium. Un 403 générique (ex: "vous n'avez pas la permission de
    // supprimer ce message") n'est PAS un problème premium — le confondre
    // affichait un message trompeur "passez premium" pour de simples
    // interdictions d'accès.
    if (statusCode == 402 ||
        (statusCode == 403 && errorCode == 'premium_required')) {
      return PremiumFailure(
        message: LocalizationService.translate('conversations.request_failed'),
        code: 'premium-required',
      );
    }
    if (statusCode == 403) {
      return PermissionFailure(
        message:
            LocalizationService.translate('conversations.action_forbidden'),
        code: 'forbidden',
      );
    }
    if (statusCode == 404) {
      return ServerFailure(
        message: LocalizationService.translate('conversations.unavailable'),
        code: 'not-found',
      );
    }
    if (statusCode == 429) {
      return ServerFailure(
        message: LocalizationService.translate('conversations.rate_limited'),
        code: 'rate-limited',
      );
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return NetworkFailure(
        message: LocalizationService.translate('conversations.network_error'),
        code: 'network',
      );
    }

    return ServerFailure(
      message: LocalizationService.translate('conversations.request_failed'),
      code: statusCode?.toString(),
    );
  }

  /// Construit une [Failure] générique pour les erreurs inattendues
  /// (non-[DioException]), sans exposer le détail brut de l'exception à
  /// l'UI (fuite potentielle d'information technique/PII). Le détail complet
  /// est loggé en debug uniquement.
  Failure _unexpectedFailure(String operation, Object error) {
    if (kDebugMode) {
      debugPrint('[MessageRepositoryImpl] $operation failed: $error');
    }
    return ServerFailure(
      message: LocalizationService.translate('common.error'),
      code: 'unknown',
    );
  }

  MessageType _stringToMessageType(String type) {
    switch (type) {
      case 'text':
        return MessageType.text;
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
      default:
        return MessageType.text;
    }
  }

  MessageStatus _stringToMessageStatus(String status) {
    switch (status) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  String _messageTypeToMediaType(MessageType type) {
    switch (type) {
      case MessageType.image:
        return 'image';
      case MessageType.video:
        return 'video';
      case MessageType.audio:
      case MessageType.voice:
        return 'audio';
      default:
        return 'image';
    }
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    final raw = value.toString();
    if (raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  String _buildClientMessageId(String conversationId) {
    // Suffixe aléatoire en plus du micro-timestamp: deux envois dans la même
    // microseconde (rare mais déjà observé sous forte charge de tests) ne
    // doivent pas produire le même client_message_id, sinon le backend
    // traite le second envoi comme un doublon du premier (dédup par
    // client_message_id dans MessageService.send_message) et le message est
    // silencieusement droppé côté utilisateur.
    final randomSuffix = Random().nextInt(1 << 31);
    return 'client_${conversationId}_${DateTime.now().microsecondsSinceEpoch}_$randomSuffix';
  }
}
