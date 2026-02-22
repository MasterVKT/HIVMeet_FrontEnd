// lib/data/repositories/interaction_history_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/network/api_client.dart';
import 'package:hivmeet/domain/entities/interaction_history.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/repositories/interaction_history_repository.dart';

/// Implémentation réelle du repository d'historique d'interactions
/// Communique avec l'API backend Django
class InteractionHistoryRepositoryImpl implements InteractionHistoryRepository {
  final ApiClient _apiClient;
  static const String _baseUrl = 'discovery/interactions';

  InteractionHistoryRepositoryImpl(this._apiClient);

  @override
  Future<Either<Failure, List<InteractionHistory>>> getMyLikes({
    int page = 1,
    int pageSize = 20,
    bool includeMatched = false,
  }) async {
    try {
      // Le backend utilise matched_only (logique inverse de includeMatched)
      final matchedOnly = !includeMatched;

      final response = await _apiClient.get(
        '$_baseUrl/my-likes',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          'matched_only': matchedOnly,
        },
      );

      if (response.statusCode == 200) {
        final results = response.data['results'] as List;
        final interactions =
            results.map((json) => _mapJsonToInteractionHistory(json)).toList();
        return Right(interactions);
      }

      return Left(ServerFailure(
        message: 'Erreur lors du chargement des likes: ${response.statusCode}',
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Erreur inattendue: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, List<InteractionHistory>>> getMyPasses({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '$_baseUrl/my-passes',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      if (response.statusCode == 200) {
        final results = response.data['results'] as List;
        final interactions =
            results.map((json) => _mapJsonToInteractionHistory(json)).toList();
        return Right(interactions);
      }

      return Left(ServerFailure(
        message: 'Erreur lors du chargement des passes: ${response.statusCode}',
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Erreur inattendue: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> revokeInteraction(String interactionId) async {
    try {
      final response = await _apiClient.post(
        '$_baseUrl/$interactionId/revoke',
      );

      if (response.statusCode == 200) {
        return const Right(null);
      }

      return Left(ServerFailure(
        message: 'Erreur lors de la révocation: ${response.statusCode}',
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Erreur inattendue: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, InteractionStats>> getStats() async {
    try {
      final response = await _apiClient.get('$_baseUrl/stats');

      if (response.statusCode == 200) {
        final stats = _mapJsonToStats(response.data);
        return Right(stats);
      }

      return Left(ServerFailure(
        message: 'Erreur lors du chargement des stats: ${response.statusCode}',
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Erreur inattendue: $e',
      ));
    }
  }

  /// Mapper la réponse JSON de l'API vers InteractionHistory
  InteractionHistory _mapJsonToInteractionHistory(Map<String, dynamic> json) {
    try {
      final profileData = json['profile'] as Map<String, dynamic>?;

      if (profileData == null) {
        throw Exception('Profile data is null');
      }

      // Mapper le profil utilisateur selon la structure backend
      final profile = DiscoveryProfile(
        id: profileData['user_id'] as String? ?? '',
        displayName: profileData['username'] as String? ??
            profileData['display_name'] as String? ??
            'Utilisateur',
        age: profileData['age'] as int? ?? 18,
        mainPhotoUrl: profileData['profile_photo'] as String? ?? '',
        otherPhotosUrls: const [], // Backend ne retourne pas les autres photos dans la liste
        bio: profileData['bio'] as String? ?? '',
        city: profileData['city'] as String? ?? '',
        country: 'France', // Backend ne retourne pas le pays dans la liste
        distance: null, // Backend ne retourne pas la distance dans la liste
        interests: const [], // Backend ne retourne pas les intérêts dans la liste
        relationshipType: '', // Backend ne retourne pas ce champ dans la liste
        isVerified: false, // Backend ne retourne pas ce champ dans la liste
        isPremium: false, // Backend ne retourne pas ce champ dans la liste
        lastActive:
            DateTime.now(), // Backend ne retourne pas ce champ dans la liste
        compatibilityScore: 0, // Backend ne retourne pas ce champ dans la liste
      );

      // Mapper le type d'interaction
      final interactionTypeStr = json['interaction_type'] as String?;
      if (interactionTypeStr == null) {
        throw Exception('interaction_type is null');
      }

      final InteractionType type;
      switch (interactionTypeStr) {
        case 'super_like':
          type = InteractionType.superLike;
          break;
        case 'dislike':
          type = InteractionType.dislike;
          break;
        case 'like':
        default:
          type = InteractionType.like;
          break;
      }

      // Déterminer si on peut révoquer
      // Backend: ne peut pas révoquer si déjà révoqué
      final isRevoked = json['is_revoked'] as bool? ?? false;
      final canRevoke = !isRevoked;

      return InteractionHistory(
        id: json['id'] as String? ?? '',
        profile: profile,
        type: type,
        timestamp: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        isMatched: json['is_match'] as bool? ?? false,
        matchId:
            null, // Backend ne retourne pas le match_id dans cette structure
        canRevoke: canRevoke,
      );
    } catch (e, stackTrace) {
      print('❌ ERROR Mapping interaction: $e');
      print('Stack trace: $stackTrace');
      print('JSON: $json');
      rethrow;
    }
  }

  /// Mapper les stats de l'API
  InteractionStats _mapJsonToStats(Map<String, dynamic> json) {
    final totalLikes = json['total_likes'] as int? ?? 0;
    final totalSuperLikes = json['total_super_likes'] as int? ?? 0;
    final totalMatches = json['total_matches'] as int? ?? 0;

    // Calculer le ratio like → match
    final allLikes = totalLikes + totalSuperLikes;
    final likeToMatchRatio = allLikes > 0 ? totalMatches / allLikes : 0.0;

    return InteractionStats(
      totalLikes: totalLikes,
      totalSuperLikes: totalSuperLikes,
      totalDislikes: json['total_dislikes'] as int? ?? 0,
      totalMatches: totalMatches,
      likeToMatchRatio: likeToMatchRatio,
      totalInteractionsToday: json['total_interactions_today'] as int? ?? 0,
      dailyLimit: json['daily_limit'] as int? ?? 50, // Défaut si non fourni
      remainingToday:
          json['remaining_today'] as int? ?? 50, // Défaut si non fourni
    );
  }
}
