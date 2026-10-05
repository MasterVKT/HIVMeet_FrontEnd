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
  Future<Either<Failure, InteractionHistoryPage>> getMyLikes({
    int page = 1,
    int pageSize = 20,
    String query = '',
    InteractionMatchFilter matchFilter = InteractionMatchFilter.all,
  });

  /// Récupère la liste des profils passés/unlikés par l'utilisateur
  ///
  /// [page] - Numéro de page (1-indexed)
  /// [pageSize] - Nombre d'éléments par page
  Future<Either<Failure, InteractionHistoryPage>> getMyPasses({
    int page = 1,
    int pageSize = 20,
    String query = '',
    InteractionMatchFilter matchFilter = InteractionMatchFilter.all,
  });

  /// Révoque une interaction précédente
  ///
  /// Permet de "reconsidérer" un profil en annulant l'interaction
  /// Le profil réapparaîtra dans la découverte
  Future<Either<Failure, void>> revokeInteraction(String interactionId);

  /// Revokes rows as one transaction. `selectAll` applies the active server
  /// filter, including pages the device has not loaded.
  Future<Either<Failure, BulkRevokeResult>> revokeInteractions(
    BulkRevokeRequest request,
  );

  /// Récupère les statistiques d'interactions de l'utilisateur
  Future<Either<Failure, InteractionStats>> getStats();
}
