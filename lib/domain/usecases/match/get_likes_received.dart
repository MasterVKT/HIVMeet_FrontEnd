// lib/domain/usecases/match/get_likes_received.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';
import 'package:hivmeet/domain/entities/match.dart';

/// Use case pour récupérer la liste des profils qui ont liké l'utilisateur
///
/// FEATURE PREMIUM: Nécessite un abonnement actif
/// Permet de voir qui a liké avant de swiper
@injectable
class GetLikesReceived implements UseCase<List<DiscoveryProfile>, GetLikesReceivedParams> {
  final MatchRepository repository;

  GetLikesReceived(this.repository);

  @override
  Future<Either<Failure, List<DiscoveryProfile>>> call(GetLikesReceivedParams params) async {
    return await repository.getLikesReceived(
      limit: params.limit,
      lastProfileId: params.lastProfileId,
    );
  }
}

/// Paramètres pour la récupération des likes reçus
class GetLikesReceivedParams extends Equatable {
  /// Nombre de profils à récupérer (default: 20)
  final int limit;

  /// ID du dernier profil pour pagination (optionnel)
  final String? lastProfileId;

  const GetLikesReceivedParams({
    this.limit = 20,
    this.lastProfileId,
  });

  /// Helper pour créer les paramètres de la première page
  factory GetLikesReceivedParams.initial({int limit = 20}) {
    return GetLikesReceivedParams(limit: limit);
  }

  /// Helper pour créer les paramètres de la page suivante
  GetLikesReceivedParams nextPage(String lastProfileId) {
    return GetLikesReceivedParams(
      limit: limit,
      lastProfileId: lastProfileId,
    );
  }

  @override
  List<Object?> get props => [limit, lastProfileId];
}
