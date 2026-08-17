// lib/data/repositories/interaction_history_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
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
      // matched_only=true → retourner SEULEMENT les likes avec match
      // matched_only=false → retourner TOUS les likes (défaut, comportement attendu)
      final matchedOnly = includeMatched;

      final response = await _apiClient.get(
        '$_baseUrl/my-likes',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          'matched_only': matchedOnly,
          'include_revoked': false,
          'order_by': 'recent',
        },
      );

      if (response.statusCode == 200) {
        final results = response.data['results'] as List;
        final List<InteractionHistory> interactions = [];
        for (final json in results) {
          try {
            final interaction = _mapJsonToInteractionHistory(json);
            interactions.add(interaction);
          } catch (e) {
            // Log l'erreur mais continue avec les autres profils
            debugPrint('⚠️ Erreur mapping profil, ignoré: $e');
            debugPrint('JSON problématique: $json');
          }
        }
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
          'include_revoked': false,
          'order_by': 'recent',
        },
      );

      if (response.statusCode == 200) {
        final results = response.data['results'] as List;
        final List<InteractionHistory> interactions = [];
        for (final json in results) {
          try {
            final interaction = _mapJsonToInteractionHistory(json);
            interactions.add(interaction);
          } catch (e) {
            // Log l'erreur mais continue avec les autres profils
            debugPrint('⚠️ Erreur mapping profil passes, ignoré: $e');
          }
        }
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
  /// Compatible avec la structure réelle du backend
  InteractionHistory _mapJsonToInteractionHistory(Map<String, dynamic> json) {
    try {
      // Debug: afficher le JSON reçu pour diagnostic
      debugPrint('🔍 Mapping JSON: $json');

      // Extraire les données du profil -多种格式 support
      Map<String, dynamic> profileData;

      if (json['profile'] is Map) {
        profileData = json['profile'] as Map<String, dynamic>;
      } else if (json['target_user'] is Map) {
        // Format alternatif possible
        profileData = json['target_user'] as Map<String, dynamic>;
      } else {
        // Fallback: utiliser les champs directement à la racine
        profileData = {
          'user_id': json['target_user_id'] ?? json['user_id'] ?? '',
          'username': json['username'] ?? '',
          'display_name': json['display_name'] ?? json['username'] ?? '',
          'age': json['age'] ?? 18,
          'profile_photo':
              json['profile_photo'] ?? json['main_photo_url'] ?? '',
          'bio': json['bio'] ?? '',
          'city': json['city'] ?? '',
          'gender': json['gender'] ?? '',
          'is_online': json['is_online'] ?? false,
        };
      }

      debugPrint('🔍 Profile data extracted: $profileData');

      // Extraire l'ID du profil (plusieurs formats possibles)
      String profileId = '';
      if (profileData['user_id'] != null) {
        profileId = profileData['user_id'].toString();
      } else if (profileData['id'] != null) {
        profileId = profileData['id'].toString();
      } else if (json['target_user_id'] != null) {
        profileId = json['target_user_id'].toString();
      }

      // Extraire le display name (plusieurs formats)
      String displayName = 'Utilisateur';
      if (profileData['display_name'] != null &&
          profileData['display_name'].toString().isNotEmpty) {
        displayName = profileData['display_name'].toString();
      } else if (profileData['username'] != null &&
          profileData['username'].toString().isNotEmpty) {
        displayName = profileData['username'].toString();
      }

      // Extraire la photo (plusieurs formats possibles, y compris array)
      String mainPhotoUrl = '';
      if (profileData['profile_photo'] != null) {
        mainPhotoUrl = profileData['profile_photo'].toString();
      } else if (profileData['main_photo_url'] != null) {
        mainPhotoUrl = profileData['main_photo_url'].toString();
      } else if (profileData['photo_url'] != null) {
        mainPhotoUrl = profileData['photo_url'].toString();
      } else if (profileData['photos'] != null &&
          profileData['photos'] is List) {
        // Format array - prendre la première photo
        final photosList = profileData['photos'] as List;
        if (photosList.isNotEmpty) {
          mainPhotoUrl = photosList.first.toString();
        }
      }

      // Mapper le profil utilisateur - avec tous les champs requis par DiscoveryProfile
      final profile = DiscoveryProfile(
        id: profileId,
        displayName: displayName,
        age: (profileData['age'] as num?)?.toInt() ?? 18,
        mainPhotoUrl: mainPhotoUrl,
        otherPhotosUrls: const [],
        bio: profileData['bio']?.toString() ?? '',
        city: profileData['city']?.toString() ?? '',
        country: profileData['country']?.toString() ?? 'FR',
        distance: null,
        interests: const [],
        relationshipTypesSought: const [],
        relationshipType: 'long_term',
        isVerified: profileData['is_verified'] == true,
        isPremium: profileData['is_premium'] == true,
        lastActive: profileData['is_online'] == true
            ? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(0),
        likedAt: null,
        compatibilityScore: 0,
      );

      // Mapper le type d'interaction
      final interactionTypeStr = json['interaction_type']?.toString();
      if (interactionTypeStr == null) {
        throw Exception('interaction_type is null');
      }

      final InteractionType type;
      switch (interactionTypeStr.toLowerCase()) {
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
      final isRevoked = json['is_revoked'] == true;
      final canRevoke = !isRevoked;

      // Parser la date correctement - plusieurs champs possibles
      DateTime timestamp = DateTime.now();
      final timestampFields = ['created_at', 'liked_at', 'passed_at'];
      for (final field in timestampFields) {
        if (json[field] != null) {
          try {
            timestamp = DateTime.parse(json[field].toString());
            break;
          } catch (e) {
            debugPrint('⚠️ Error parsing $field: $e');
          }
        }
      }

      // Extraire l'ID de l'interaction
      String interactionId = '';
      if (json['id'] != null) {
        interactionId = json['id'].toString();
      }

      // Mapper le match - plusieurs noms de champs possibles
      bool isMatched = false;
      if (json['is_match'] == true || json['is_matched'] == true) {
        isMatched = true;
      }

      debugPrint(
          '✅ Mapped interaction: $interactionId, type: $type, isMatched: $isMatched');

      return InteractionHistory(
        id: interactionId,
        profile: profile,
        type: type,
        timestamp: timestamp,
        isMatched: isMatched,
        matchId: null,
        canRevoke: canRevoke,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR Mapping interaction: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('JSON complet: $json');
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
      totalInteractionsWeek: _parseOptionalInt(
        json['total_interactions_week'] ??
            json['total_interactions_this_week'] ??
            json['weekly_interactions'],
      ),
      dailyLimit: json['daily_limit'] as int? ?? 50, // Défaut si non fourni
      remainingToday:
          json['remaining_today'] as int? ?? 50, // Défaut si non fourni
    );
  }

  int? _parseOptionalInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
