// lib/domain/usecases/message/mark_as_read.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';

/// Use Case pour marquer les messages d'une conversation comme lus
///
/// Features:
/// - Marque tous les messages non lus de la conversation
/// - Met à jour le compteur unreadCount localement
/// - Notifie le serveur pour synchronisation
///
/// Usage:
/// ```dart
/// final result = await markAsRead(
///   MarkAsReadParams(conversationId: 'conv_123')
/// );
/// ```
@injectable
class MarkAsRead implements UseCase<void, MarkAsReadParams> {
  final MessageRepository repository;

  MarkAsRead(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkAsReadParams params) async {
    return await repository.markAsRead(params.conversationId);
  }
}

/// Paramètres pour marquer comme lu
class MarkAsReadParams extends Equatable {
  final String conversationId;

  const MarkAsReadParams({required this.conversationId});

  @override
  List<Object> get props => [conversationId];
}
