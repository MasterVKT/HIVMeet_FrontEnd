// lib/data/repositories/interaction_history_repository_mock.dart

import 'package:dartz/dartz.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/interaction_history.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/repositories/interaction_history_repository.dart';

/// Implémentation mock du repository d'historique des interactions
///
/// Utilisée pour le développement et les tests avant l'implémentation backend
class InteractionHistoryRepositoryMock implements InteractionHistoryRepository {
  // Stockage en mémoire des interactions
  final List<InteractionHistory> _likes = [];
  final List<InteractionHistory> _passes = [];

  InteractionHistoryRepositoryMock() {
    _generateMockData();
  }

  @override
  Future<Either<Failure, List<InteractionHistory>>> getMyLikes({
    int page = 1,
    int pageSize = 20,
    bool includeMatched = false,
  }) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      var likes = List<InteractionHistory>.from(_likes);

      // Filtrer les matchés si nécessaire
      if (!includeMatched) {
        likes = likes.where((l) => !l.isMatched).toList();
      }

      // Pagination
      final startIndex = (page - 1) * pageSize;
      final endIndex = startIndex + pageSize;

      if (startIndex >= likes.length) {
        return const Right([]);
      }

      final paginatedLikes = likes.sublist(
        startIndex,
        endIndex > likes.length ? likes.length : endIndex,
      );

      return Right(paginatedLikes);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Erreur lors du chargement des likes: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, List<InteractionHistory>>> getMyPasses({
    int page = 1,
    int pageSize = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final startIndex = (page - 1) * pageSize;
      final endIndex = startIndex + pageSize;

      if (startIndex >= _passes.length) {
        return const Right([]);
      }

      final paginatedPasses = _passes.sublist(
        startIndex,
        endIndex > _passes.length ? _passes.length : endIndex,
      );

      return Right(paginatedPasses);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Erreur lors du chargement des profils passés: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> revokeInteraction(String interactionId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      // Chercher dans les likes
      final likeIndex = _likes.indexWhere((l) => l.id == interactionId);
      if (likeIndex != -1) {
        // Vérifier si c'est un match actif
        if (_likes[likeIndex].isMatched) {
          return Left(ServerFailure(
            message: 'Impossible de révoquer un like qui a abouti à un match',
          ));
        }
        _likes.removeAt(likeIndex);
        return const Right(null);
      }

      // Chercher dans les passes
      final passIndex = _passes.indexWhere((p) => p.id == interactionId);
      if (passIndex != -1) {
        _passes.removeAt(passIndex);
        return const Right(null);
      }

      return Left(ServerFailure(
        message: 'Interaction non trouvée',
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Erreur lors de la révocation: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, InteractionStats>> getStats() async {
    await Future.delayed(const Duration(milliseconds: 400));

    try {
      final totalLikes =
          _likes.where((l) => l.type == InteractionType.like).length;
      final totalSuperLikes =
          _likes.where((l) => l.type == InteractionType.superLike).length;
      final totalDislikes = _passes.length;
      final totalMatches = _likes.where((l) => l.isMatched).length;

      final totalAllLikes = totalLikes + totalSuperLikes;
      final likeToMatchRatio =
          totalAllLikes > 0 ? totalMatches / totalAllLikes : 0.0;

      final stats = InteractionStats(
        totalLikes: totalLikes,
        totalSuperLikes: totalSuperLikes,
        totalDislikes: totalDislikes,
        totalMatches: totalMatches,
        likeToMatchRatio: likeToMatchRatio,
        totalInteractionsToday: 15,
        dailyLimit: 100,
        remainingToday: 85,
      );

      return Right(stats);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Erreur lors du chargement des statistiques: $e',
      ));
    }
  }

  /// Génère des données mock pour le développement
  void _generateMockData() {
    final now = DateTime.now();

    // Générer des likes mock
    for (int i = 0; i < 15; i++) {
      _likes.add(InteractionHistory(
        id: 'like-$i',
        profile: _generateMockProfile('like-profile-$i', 'Sophie', 25 + i),
        type: i % 5 == 0 ? InteractionType.superLike : InteractionType.like,
        timestamp: now.subtract(Duration(days: i, hours: i * 2)),
        isMatched: i % 4 == 0, // 25% de matches
        matchId: i % 4 == 0 ? 'match-$i' : null,
        canRevoke: i % 4 != 0, // Peut révoquer si pas de match
      ));
    }

    // Générer des passes mock
    for (int i = 0; i < 25; i++) {
      _passes.add(InteractionHistory(
        id: 'pass-$i',
        profile: _generateMockProfile('pass-profile-$i', 'Marc', 28 + i),
        type: InteractionType.dislike,
        timestamp: now.subtract(Duration(days: i, hours: i)),
        canRevoke: true,
      ));
    }
  }

  DiscoveryProfile _generateMockProfile(String id, String baseName, int age) {
    final names = [
      'Sophie',
      'Julie',
      'Emma',
      'Léa',
      'Chloé',
      'Clara',
      'Alice',
      'Laura',
      'Sarah',
      'Marie'
    ];
    final cities = [
      'Paris',
      'Lyon',
      'Marseille',
      'Toulouse',
      'Nice',
      'Bordeaux',
      'Lille'
    ];

    return DiscoveryProfile(
      id: id,
      displayName: names[age % names.length],
      age: age,
      mainPhotoUrl: 'https://picsum.photos/400/600?random=$id',
      otherPhotosUrls: [
        'https://picsum.photos/400/600?random=${id}a',
        'https://picsum.photos/400/600?random=${id}b',
      ],
      bio: 'Bio de test pour $id',
      city: cities[age % cities.length],
      country: 'France',
      distance: (age % 30).toDouble() + 1.5,
      interests: ['Voyage', 'Sport', 'Cinéma'],
      relationshipType: 'casual',
      isVerified: age % 3 == 0,
      isPremium: age % 5 == 0,
      lastActive: DateTime.now().subtract(Duration(hours: age % 48)),
      compatibilityScore: 70.0 + (age % 20),
    );
  }
}
