// lib/data/repositories/message_repository_impl.dart

import 'dart:io';
import 'package:dartz/dartz.dart';
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
      // Convertir lastConversationId en page pour l'API
      int page = 1;
      // TODO: Implémenter la pagination basée sur lastConversationId

      final response = await _messagingApi.getConversations(
        page: page,
        pageSize: limit,
      );

      final payload = response.data!;
      final list = (payload['results'] ?? payload['data'] ?? []) as List;
      final conversations = list
          .map((json) => _mapJsonToConversation(json as Map<String, dynamic>))
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
      final conversation =
          _mapJsonToConversation(response.data!);
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
      final response = await _messagingApi.getConversationMessages(
        conversationId: conversationId,
        page: 1,
        pageSize: limit,
        beforeMessageId: beforeMessageId,
      );

      final payload = response.data!;
      final list = (payload['results'] ?? payload['data'] ?? []) as List;
      final messages = list
          .map((json) => _mapJsonToMessage(json as Map<String, dynamic>))
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
      // Si un fichier média est fourni, on utilise l'endpoint dédié

      final response = mediaFile != null
          ? await _messagingApi.sendMediaMessage(
              conversationId: conversationId,
              mediaFilePath: mediaFile.path,
            )
          : await _messagingApi.sendTextMessage(
              conversationId: conversationId,
              content: content,
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
      await _messagingApi.markMessageAsRead(
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
      // Pas d'endpoint HTTP pour le statut de saisie (WebSocket prévu)
      // Implémentation no-op côté HTTP pour respecter l'interface
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

  Conversation _mapJsonToConversation(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      participantIds:
          (json['participant_ids'] as List?)?.cast<String>() ?? const [],
      lastMessage: json['last_message'] != null
          ? _mapJsonToMessage(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: (json['unread_count'] as int?) ?? 0,
      updatedAt: DateTime.parse(
          (json['updated_at'] as String?) ?? DateTime.now().toIso8601String()),
    );
  }

  Message _mapJsonToMessage(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      type: _stringToMessageType(
          (json['type'] ?? json['message_type'] ?? 'text') as String),
      mediaUrl: json['media_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt:
          DateTime.parse((json['created_at'] ?? json['sent_at']) as String),
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
      case 'voice':
        return MessageType.voice;
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
}
