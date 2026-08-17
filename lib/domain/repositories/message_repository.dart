// lib/domain/repositories/message_repository.dart

import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/message.dart';

abstract class MessageRepository {
  // Conversations
  //
  // Pagination page-based: le backend (`ConversationListView`) est un vrai
  // DRF `PageNumberPagination` (PAGE_SIZE=20, lit `?page=`) — il n'y a pas de
  // curseur par ID côté serveur pour cette ressource.
  Future<Either<Failure, ConversationListPage>> getConversations({
    int limit = 20,
    int page = 1,
    ConversationFilter filter = ConversationFilter.all,
  });

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

  Future<Either<Failure, MarkAsReadResult>> markAsRead({
    required String conversationId,
    required String messageId,
  });

  Future<Either<Failure, void>> deleteMessage({
    required String conversationId,
    required String messageId,
  });

  /// Compteur global exact de messages non lus sur toutes les conversations
  /// actives non masquées (endpoint dédié, non limité par la pagination).
  Future<Either<Failure, int>> getUnreadCount();

  Future<Either<Failure, void>> deleteConversation(String conversationId);

  // Typing indicators
  Future<Either<Failure, void>> setTypingStatus({
    required String conversationId,
    required bool isTyping,
  });

  Future<Either<Failure, ParticipantPresence>> getPresence({
    required String conversationId,
  });

  Stream<Map<String, bool>> watchTypingStatus(String conversationId);
}
