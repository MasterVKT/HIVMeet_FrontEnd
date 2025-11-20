// lib/domain/usecases/chat/mark_message_as_read.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';

/// Use case pour marquer un message comme lu
///
/// Cette opération:
/// - Marque un ou plusieurs messages comme lus
/// - Met à jour le compteur de non-lus dans la conversation
/// - Notifie l'expéditeur que le message a été lu
///
/// Note: Cette opération est généralement appelée automatiquement
/// quand l'utilisateur voit le message, pas manuellement.
///
/// Erreurs possibles:
/// - [ServerFailure]: Erreur lors de la mise à jour
/// - [NetworkFailure]: Pas de connexion réseau
@injectable
class MarkMessageAsRead {
  final MessageRepository repository;

  MarkMessageAsRead(this.repository);

  Future<Either<Failure, void>> call(MarkMessageAsReadParams params) async {
    return await repository.markAsRead(
      conversationId: params.conversationId,
      messageId: params.messageId,
    );
  }
}

class MarkMessageAsReadParams extends Equatable {
  final String conversationId;
  final String messageId;

  const MarkMessageAsReadParams({
    required this.conversationId,
    required this.messageId,
  });

  @override
  List<Object> get props => [conversationId, messageId];
}
