// lib/domain/repositories/interaction_history_repository.dart

import 'package:dartz/dartz.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/interaction_history.dart';

/// Repository pour la gestion de l'historique des interactions
abstract class InteractionHistoryRepository {
  /// Récupère la liste des profils likés par l'utilisateur
  ///
  /// [page] - Numéro de page (1-indexed)
  /// [pageSize] - Nombre d'éléments par page
  /// [includeMatched] - Inclure les likes qui ont abouti à un match
  Future<Either<Failure, List<InteractionHistory>>> getMyLikes({
    int page = 1,
    int pageSize = 20,
    bool includeMatched = false,
  });

  /// Récupère la liste des profils passés/unlikés par l'utilisateur
  ///
  /// [page] - Numéro de page (1-indexed)
  /// [pageSize] - Nombre d'éléments par page
  Future<Either<Failure, List<InteractionHistory>>> getMyPasses({
    int page = 1,
    int pageSize = 20,
  });

  /// Révoque une interaction précédente
  ///
  /// Permet de "reconsidérer" un profil en annulant l'interaction
  /// Le profil réapparaîtra dans la découverte
  Future<Either<Failure, void>> revokeInteraction(String interactionId);

  /// Récupère les statistiques d'interactions de l'utilisateur
  Future<Either<Failure, InteractionStats>> getStats();
}
