// lib/domain/usecases/message/mark_as_read.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';

/// Use Case pour marquer un message comme lu
///
/// Features:
/// - Marque un message spécifique comme lu
/// - Met à jour le compteur unreadCount localement
/// - Notifie le serveur pour synchronisation
///
/// Usage:
/// ```dart
/// final result = await markAsRead(
///   MarkAsReadParams(conversationId: 'conv_123', messageId: 'msg_456')
/// );
/// ```
@injectable
class MarkAsRead implements UseCase<MarkAsReadResult, MarkAsReadParams> {
  final MessageRepository repository;

  MarkAsRead(this.repository);

  @override
  Future<Either<Failure, MarkAsReadResult>> call(
      MarkAsReadParams params) async {
    return await repository.markAsRead(
      conversationId: params.conversationId,
      messageId: params.messageId,
    );
  }
}

/// Paramètres pour marquer comme lu
class MarkAsReadParams extends Equatable {
  final String conversationId;
  final String messageId;

  const MarkAsReadParams({
    required this.conversationId,
    required this.messageId,
  });

  @override
  List<Object> get props => [conversationId, messageId];
}
