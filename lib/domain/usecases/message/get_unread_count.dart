// lib/domain/usecases/message/get_unread_count.dart

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';

/// Use Case pour récupérer le compteur global exact de messages non lus.
///
/// Utilise l'endpoint dédié `GET /conversations/unread-count/` qui agrège
/// côté serveur toutes les conversations actives non masquées, sans
/// limitation de pagination (contrairement à [GetConversations] qui ne
/// couvre que la première page de 20 conversations).
@injectable
class GetUnreadCount implements UseCase<int, NoParams> {
  final MessageRepository repository;

  GetUnreadCount(this.repository);

  @override
  Future<Either<Failure, int>> call(NoParams params) async {
    return await repository.getUnreadCount();
  }
}
