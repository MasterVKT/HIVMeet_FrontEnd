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
  Future<Either<Failure, List<Message>>> getMessages({
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
  
  Stream<Map<String, bool>> watchTypingStatus(String conversationId);
}