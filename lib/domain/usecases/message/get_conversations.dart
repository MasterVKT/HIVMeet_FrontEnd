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
/// - Pagination page-based (le backend est un DRF PageNumberPagination réel,
///   il n'y a pas de curseur par ID côté serveur pour cette ressource)
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
class GetConversations
    implements UseCase<ConversationListPage, GetConversationsParams> {
  final MessageRepository repository;

  GetConversations(this.repository);

  @override
  Future<Either<Failure, ConversationListPage>> call(
      GetConversationsParams params) async {
    return await repository.getConversations(
      limit: params.limit,
      page: params.page,
      filter: params.filter,
    );
  }
}

/// Paramètres pour GetConversations avec helper pour pagination
class GetConversationsParams extends Equatable {
  final int limit;
  final int page;
  final ConversationFilter filter;

  const GetConversationsParams({
    this.limit = 20,
    this.page = 1,
    this.filter = ConversationFilter.all,
  });

  /// Crée les paramètres pour le chargement initial
  factory GetConversationsParams.initial({
    int limit = 20,
    ConversationFilter filter = ConversationFilter.all,
  }) {
    return GetConversationsParams(limit: limit, page: 1, filter: filter);
  }

  /// Crée les paramètres pour la page suivante
  GetConversationsParams nextPage(int page) {
    return GetConversationsParams(
      limit: limit,
      page: page,
      filter: filter,
    );
  }

  @override
  List<Object?> get props => [limit, page, filter];
}
