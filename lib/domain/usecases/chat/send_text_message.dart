// lib/domain/usecases/chat/send_text_message.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';

/// Use case pour envoyer un message texte
///
/// Cette opération:
/// - Envoie un message texte dans une conversation
/// - Retourne le message créé avec son ID serveur
/// - Supporte l'optimistic update dans le BLoC
///
/// Erreurs possibles:
/// - [ServerFailure]: Erreur lors de l'envoi
/// - [NetworkFailure]: Pas de connexion réseau
@injectable
class SendTextMessage {
  final MessageRepository repository;

  SendTextMessage(this.repository);

  Future<Either<Failure, Message>> call(SendTextMessageParams params) async {
    // Validation côté client
    if (params.content.trim().isEmpty) {
      return Left(
        ServerFailure(message: 'Le message ne peut pas être vide'),
      );
    }

    return await repository.sendMessage(
      conversationId: params.conversationId,
      content: params.content,
      type: MessageType.text,
      clientMessageId: params.clientMessageId,
    );
  }
}

class SendTextMessageParams extends Equatable {
  final String conversationId;
  final String content;
  final String? clientMessageId;

  const SendTextMessageParams({
    required this.conversationId,
    required this.content,
    this.clientMessageId,
  });

  @override
  List<Object?> get props => [conversationId, content, clientMessageId];
}
