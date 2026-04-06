import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';
import 'package:hivmeet/data/datasources/remote/messaging_api.dart';

@LazySingleton(as: MessageRepository)
class MessageRepositoryImpl implements MessageRepository {
  final MessagingApi _messagingApi;

  const MessageRepositoryImpl(this._messagingApi);

  @override
  Future<Either<Failure, List<Conversation>>> getConversations({
    int limit = 20,
    String? lastConversationId,
  }) async {
    try {
      final response = await _messagingApi.getConversations(
        page: 1,
        pageSize: limit,
      );

      final payload = response.data ?? const <String, dynamic>{};
      final list = (payload['results'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>();

      final conversations = list.map(_mapJsonToConversation).toList();
      return Right(conversations);
    } on DioException catch (e) {
      return Left(_mapDioFailure(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Conversation>> getConversation(
      String conversationId) async {
    try {
      final response = await _messagingApi.getConversation(conversationId);
      final payload = response.data ?? const <String, dynamic>{};
      return Right(_mapJsonToConversation(payload));
    } on DioException catch (e) {
      return Left(_mapDioFailure(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
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
      return Left(ServerFailure(message: e.toString()));
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
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      await _messagingApi.markMessageAsRead(
        conversationId: conversationId,
        lastReadMessageId: messageId,
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioFailure(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
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
      return Left(ServerFailure(message: e.toString()));
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
      return Left(ServerFailure(message: e.toString()));
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
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MediaUploadTarget>> generateMediaUploadUrl({
    required String fileName,
    required String contentType,
  }) async {
    try {
      final response = await _messagingApi.generateMediaUploadUrl(
        fileName: fileName,
        contentType: contentType,
      );
      final payload = response.data ?? const <String, dynamic>{};

      return Right(
        MediaUploadTarget(
          uploadUrl: (payload['upload_url'] ?? '') as String,
          filePathOnStorage: (payload['file_path_on_storage'] ?? '') as String,
          contentType: (payload['content_type'] ?? contentType) as String,
          expiresInSeconds: payload['expires_in_seconds'] as int? ?? 0,
        ),
      );
    } on DioException catch (e) {
      return Left(_mapDioFailure(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
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
      participantIds:
          otherUserId.isEmpty ? const <String>[] : <String>[otherUserId],
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
    final content = (json['content'] ?? '') as String;

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
      mediaUrl: json['media_url'] as String?,
      mediaType: json['media_type'] as String?,
      mediaThumbnailUrl: json['media_thumbnail_url'] as String?,
      reactions: (json['reactions'] as Map<String, dynamic>? ??
              const <String, dynamic>{})
          .map((key, value) => MapEntry(key, value.toString())),
      status: _stringToMessageStatus((json['status'] ?? 'sent') as String),
    );
  }

  Failure _mapDioFailure(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final message = data is Map<String, dynamic>
        ? (data['message'] ??
                data['error'] ??
                error.message ??
                'Unknown API error')
            .toString()
        : (error.message ?? 'Unknown API error');

    if (statusCode == 401) {
      return AuthFailure(message: message, code: 'unauthorized');
    }
    if (statusCode == 403) {
      return PremiumFailure(message: message, code: 'forbidden');
    }
    if (statusCode == 404) {
      return ServerFailure(message: message, code: 'not-found');
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return NetworkFailure(message: message, code: 'network');
    }

    return ServerFailure(message: message, code: statusCode?.toString());
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
    return 'client_${conversationId}_${DateTime.now().microsecondsSinceEpoch}';
  }
}
