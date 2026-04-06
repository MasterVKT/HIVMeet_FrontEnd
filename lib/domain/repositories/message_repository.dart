// lib/domain/repositories/message_repository.dart

import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/message.dart';

abstract class MessageRepository {
  // Conversations
  Future<Either<Failure, List<Conversation>>> getConversations({
    int limit = 20,
    String? lastConversationId,
  });
  
  Future<Either<Failure, Conversation>> getConversation(String conversationId);
  
  Stream<List<Conversation>> watchConversations();
  
  // Messages
  Future<Either<Failure, ConversationMessagesPage>> getMessages({
    required String conversationId,
    int limit = 50,
    String? beforeMessageId,
  });
  
  Stream<List<Message>> watchMessages(String conversationId);
  
  Future<Either<Failure, Message>> sendMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
    File? mediaFile,
    String? clientMessageId,
    String? mediaText,
  });
  
  Future<Either<Failure, void>> markAsRead({
    required String conversationId,
    required String messageId,
  });
  
  Future<Either<Failure, void>> deleteMessage({
    required String conversationId,
    required String messageId,
  });
  
  // Typing indicators
  Future<Either<Failure, void>> setTypingStatus({
    required String conversationId,
    required bool isTyping,
  });

  Future<Either<Failure, ParticipantPresence>> getPresence({
    required String conversationId,
  });

  Future<Either<Failure, MediaUploadTarget>> generateMediaUploadUrl({
    required String fileName,
    required String contentType,
  });
  
  Stream<Map<String, bool>> watchTypingStatus(String conversationId);
}