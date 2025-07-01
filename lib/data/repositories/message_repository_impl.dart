// lib/data/repositories/message_repository_impl.dart

import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';
import 'package:hivmeet/data/datasources/remote/messaging_api.dart';
import 'package:hivmeet/data/models/message_model.dart';

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
      // Convertir lastConversationId en page pour l'API
      int page = 1;
      // TODO: Implémenter la pagination basée sur lastConversationId

      final response = await _messagingApi.getConversations(
        page: page,
        perPage: limit,
      );

      final conversations = (response.data!['data'] as List)
          .map((json) => _mapJsonToConversation(json))
          .toList();

      return Right(conversations);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Conversation>> getConversation(
      String conversationId) async {
    try {
      final response = await _messagingApi.getConversation(conversationId);
      final conversation = _mapJsonToConversation(response.data!);
      return Right(conversation);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<Conversation>> watchConversations() {
    // TODO: Implement real-time stream via WebSocket or Server-Sent Events
    throw UnimplementedError(
        'Real-time conversations stream not implemented yet');
  }

  @override
  Future<Either<Failure, List<Message>>> getMessages({
    required String conversationId,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    try {
      final response = await _messagingApi.getMessages(
        conversationId: conversationId,
        page: 1, // TODO: Implémenter pagination basée sur beforeMessageId
        limit: limit,
        beforeMessageId: beforeMessageId,
      );

      final messages = (response.data!['data'] as List)
          .map((json) => _mapJsonToMessage(json))
          .toList();

      return Right(messages);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<Message>> watchMessages(String conversationId) {
    // TODO: Implement real-time stream via WebSocket or Server-Sent Events
    throw UnimplementedError('Real-time messages stream not implemented yet');
  }

  @override
  Future<Either<Failure, Message>> sendMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
    File? mediaFile,
  }) async {
    try {
      // Si un fichier média est fourni, l'uploader d'abord
      String? mediaUrl;
      if (mediaFile != null) {
        // TODO: Implémenter l'upload de fichier média
        // mediaUrl = await _uploadMediaFile(mediaFile);
      }

      final response = await _messagingApi.sendMessage(
        conversationId: conversationId,
        content: content,
        messageType: _messageTypeToString(type),
        mediaUrl: mediaUrl,
      );

      final message = _mapJsonToMessage(response.data!);
      return Right(message);
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
      // Convertir messageId unique en liste pour l'API
      await _messagingApi.markAsRead(
        conversationId: conversationId,
        messageIds: [messageId],
      );
      return const Right(null);
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
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<Map<String, bool>> watchTypingStatus(String conversationId) {
    // TODO: Implement real-time stream via WebSocket or Server-Sent Events
    throw UnimplementedError(
        'Real-time typing status stream not implemented yet');
  }

  // Méthodes utilitaires
  String _messageTypeToString(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.video:
        return 'video';
      case MessageType.audio:
        return 'audio';
    }
  }

  Conversation _mapJsonToConversation(Map<String, dynamic> json) {
    // TODO: Implémenter le mapping JSON vers Conversation
    return Conversation(
      id: json['id'] as String,
      participants: (json['participants'] as List?)?.cast<String>() ?? [],
      lastMessage: json['last_message'] != null
          ? _mapJsonToMessage(json['last_message'])
          : null,
      unreadCounts: Map<String, int>.from(json['unread_counts'] ?? {}),
      createdAt: DateTime.parse(json['created_at'] as String),
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'] as String)
          : null,
    );
  }

  Message _mapJsonToMessage(Map<String, dynamic> json) {
    // TODO: Implémenter le mapping JSON vers Message
    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      type: _stringToMessageType(json['type'] as String),
      mediaUrl: json['media_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      reactions: Map<String, String>.from(json['reactions'] ?? {}),
      status: _stringToMessageStatus(json['status'] as String? ?? 'sent'),
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
}
