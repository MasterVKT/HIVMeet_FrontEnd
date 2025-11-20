// lib/domain/usecases/message/get_conversations.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';

/// Use Case pour récupérer la liste des conversations
///
/// Features:
/// - Pagination cursor-based avec lastConversationId
/// - Tri par dernière activité (updatedAt desc)
/// - Inclut preview du dernier message
/// - Compteur de messages non lus
///
/// Usage:
/// ```dart
/// final result = await getConversations(
///   GetConversationsParams.initial(limit: 20)
/// );
/// ```
@injectable
class GetConversations implements UseCase<List<Conversation>, GetConversationsParams> {
  final MessageRepository repository;

  GetConversations(this.repository);

  @override
  Future<Either<Failure, List<Conversation>>> call(GetConversationsParams params) async {
    return await repository.getConversations(
      limit: params.limit,
      lastConversationId: params.lastConversationId,
    );
  }
}

/// Paramètres pour GetConversations avec helper pour pagination
class GetConversationsParams extends Equatable {
  final int limit;
  final String? lastConversationId;

  const GetConversationsParams({
    this.limit = 20,
    this.lastConversationId,
  });

  /// Crée les paramètres pour le chargement initial
  factory GetConversationsParams.initial({int limit = 20}) {
    return GetConversationsParams(limit: limit);
  }

  /// Crée les paramètres pour la page suivante
  GetConversationsParams nextPage(String lastConversationId) {
    return GetConversationsParams(
      limit: limit,
      lastConversationId: lastConversationId,
    );
  }

  @override
  List<Object?> get props => [limit, lastConversationId];
}
