// lib/domain/usecases/chat/get_messages.dart

import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';

/// Use case pour récupérer les messages d'une conversation
///
/// Cette opération:
/// - Récupère les messages avec pagination
/// - Supporte beforeMessageId pour cursor-based pagination
/// - Retourne les messages triés par date (plus récent en dernier)
///
/// Erreurs possibles:
/// - [ServerFailure]: Erreur lors de la récupération
/// - [NetworkFailure]: Pas de connexion réseau
@injectable
class GetMessages {
  final MessageRepository repository;

  GetMessages(this.repository);

  Future<Either<Failure, List<Message>>> call(GetMessagesParams params) async {
    return await repository.getMessages(
      conversationId: params.conversationId,
      limit: params.limit,
      beforeMessageId: params.beforeMessageId,
    );
  }
}

class GetMessagesParams extends Equatable {
  final String conversationId;
  final int limit;
  final String? beforeMessageId;

  const GetMessagesParams({
    required this.conversationId,
    this.limit = 50,
    this.beforeMessageId,
  });

  /// Helper pour créer params initiaux
  factory GetMessagesParams.initial(String conversationId, {int limit = 50}) {
    return GetMessagesParams(
      conversationId: conversationId,
      limit: limit,
    );
  }

  /// Helper pour la pagination
  GetMessagesParams nextPage(String lastMessageId) {
    return GetMessagesParams(
      conversationId: conversationId,
      limit: limit,
      beforeMessageId: lastMessageId,
    );
  }

  @override
  List<Object?> get props => [conversationId, limit, beforeMessageId];
}
