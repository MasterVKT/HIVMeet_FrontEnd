import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/network/api_client.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/interaction_history.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/repositories/interaction_history_repository.dart';

class InteractionHistoryRepositoryImpl implements InteractionHistoryRepository {
  final ApiClient _apiClient;
  static const _basePath = 'discovery/interactions';

  InteractionHistoryRepositoryImpl(this._apiClient);

  @override
  Future<Either<Failure, InteractionHistoryPage>> getMyLikes({
    int page = 1,
    int pageSize = 20,
    String query = '',
    InteractionMatchFilter matchFilter = InteractionMatchFilter.all,
  }) =>
      _loadPage(
        path: '$_basePath/my-likes',
        page: page,
        pageSize: pageSize,
        query: query,
        matchFilter: matchFilter,
      );

  @override
  Future<Either<Failure, InteractionHistoryPage>> getMyPasses({
    int page = 1,
    int pageSize = 20,
    String query = '',
    InteractionMatchFilter matchFilter = InteractionMatchFilter.all,
  }) =>
      _loadPage(
        path: '$_basePath/my-passes',
        page: page,
        pageSize: pageSize,
        query: query,
        matchFilter: matchFilter,
      );

  Future<Either<Failure, InteractionHistoryPage>> _loadPage({
    required String path,
    required int page,
    required int pageSize,
    required String query,
    required InteractionMatchFilter matchFilter,
  }) async {
    try {
      final response = await _apiClient.get(
        path,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          'q': query.trim(),
          'match_state': matchFilter.apiValue,
          'include_revoked': false,
          'order_by': 'recent',
        },
      );
      final payload = Map<String, dynamic>.from(response.data as Map);
      final results = (payload['results'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => _mapInteraction(Map<String, dynamic>.from(item)))
          .toList(growable: false);
      return Right(
        InteractionHistoryPage(
          interactions: results,
          totalCount: (payload['count'] as num?)?.toInt() ?? results.length,
          selectableCount: (payload['selectable_count'] as num?)?.toInt() ??
              results.where((item) => item.canRevoke).length,
          hasNextPage: payload['next'] != null,
        ),
      );
    } on DioException catch (error) {
      return Left(_failureFromDio(error, fallbackKey: 'history.load_error'));
    } on FormatException {
      return Left(ServerFailure(
        code: 'invalid_history_response',
        message: LocalizationService.translate('history.load_error'),
      ));
    } catch (_) {
      return Left(ServerFailure(
        code: 'history_unavailable',
        message: LocalizationService.translate('history.load_error'),
      ));
    }
  }

  @override
  Future<Either<Failure, void>> revokeInteraction(String interactionId) async {
    try {
      await _apiClient.post('$_basePath/$interactionId/revoke');
      return const Right(null);
    } on DioException catch (error) {
      return Left(_failureFromDio(error, fallbackKey: 'history.revoke_error'));
    } catch (_) {
      return Left(ServerFailure(
        code: 'revoke_failed',
        message: LocalizationService.translate('history.revoke_error'),
      ));
    }
  }

  @override
  Future<Either<Failure, BulkRevokeResult>> revokeInteractions(
    BulkRevokeRequest request,
  ) async {
    try {
      final response = await _apiClient.post(
        '$_basePath/revoke-bulk',
        data: {
          'history_type': request.historyType.apiValue,
          'select_all': request.selectAll,
          if (!request.selectAll) 'interaction_ids': request.interactionIds,
          if (request.selectAll) ...{
            'q': request.query.trim(),
            'match_state': request.matchFilter.apiValue,
            'include_revoked': false,
          },
        },
      );
      final payload = Map<String, dynamic>.from(response.data as Map);
      return Right(
        BulkRevokeResult(
          revokedCount: (payload['revoked_count'] as num?)?.toInt() ?? 0,
          revokedInteractionIds:
              (payload['revoked_interaction_ids'] as List? ?? const [])
                  .map((id) => id.toString())
                  .toList(growable: false),
        ),
      );
    } on DioException catch (error) {
      return Left(
          _failureFromDio(error, fallbackKey: 'history.bulk_revoke_error'));
    } catch (_) {
      return Left(ServerFailure(
        code: 'bulk_revoke_failed',
        message: LocalizationService.translate('history.bulk_revoke_error'),
      ));
    }
  }

  @override
  Future<Either<Failure, InteractionStats>> getStats() async {
    try {
      final response = await _apiClient.get('$_basePath/stats');
      final json = Map<String, dynamic>.from(response.data as Map);
      final totalLikes = (json['total_likes'] as num?)?.toInt() ?? 0;
      final totalSuperLikes = (json['total_super_likes'] as num?)?.toInt() ?? 0;
      final totalMatches = (json['total_matches'] as num?)?.toInt() ?? 0;
      final allLikes = totalLikes + totalSuperLikes;
      return Right(InteractionStats(
        totalLikes: totalLikes,
        totalSuperLikes: totalSuperLikes,
        totalDislikes: (json['total_dislikes'] as num?)?.toInt() ?? 0,
        totalMatches: totalMatches,
        likeToMatchRatio: allLikes == 0 ? 0 : totalMatches / allLikes,
        totalInteractionsToday:
            (json['total_interactions_today'] as num?)?.toInt() ?? 0,
        totalInteractionsWeek:
            (json['total_interactions_week'] as num?)?.toInt(),
        dailyLimit: (json['daily_limit'] as num?)?.toInt() ?? 0,
        remainingToday: (json['remaining_today'] as num?)?.toInt() ?? 0,
      ));
    } on DioException catch (error) {
      return Left(_failureFromDio(error, fallbackKey: 'history.load_error'));
    } catch (_) {
      return Left(ServerFailure(
        code: 'stats_unavailable',
        message: LocalizationService.translate('history.load_error'),
      ));
    }
  }

  InteractionHistory _mapInteraction(Map<String, dynamic> json) {
    final profileJson = json['profile'];
    if (profileJson is! Map) {
      throw const FormatException('History response is missing profile.');
    }
    final profile = Map<String, dynamic>.from(profileJson);
    final userId = (profile['user_id'] ?? profile['id'])?.toString();
    final interactionId = json['id']?.toString();
    if (userId == null ||
        userId.isEmpty ||
        interactionId == null ||
        interactionId.isEmpty) {
      throw const FormatException('History response is missing an identifier.');
    }

    final photoUrls = (profile['photos'] as List? ?? const [])
        .map((photo) =>
            photo is Map ? photo['photo_url']?.toString() : photo.toString())
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    final relationshipTypes =
        (profile['relationship_types_sought'] as List? ?? const [])
            .map((type) => type.toString())
            .toList(growable: false);
    final type = switch (json['interaction_type']?.toString()) {
      'super_like' => InteractionType.superLike,
      'dislike' => InteractionType.dislike,
      _ => InteractionType.like,
    };
    final timestamp = DateTime.tryParse(
          (json['created_at'] ?? json['liked_at'] ?? json['passed_at'])
                  ?.toString() ??
              '',
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);

    return InteractionHistory(
      id: interactionId,
      profile: DiscoveryProfile(
        id: userId,
        displayName: profile['display_name']?.toString() ?? '',
        age: (profile['age'] as num?)?.toInt() ?? 0,
        mainPhotoUrl: photoUrls.isEmpty ? '' : photoUrls.first,
        otherPhotosUrls: photoUrls.length < 2 ? const [] : photoUrls.sublist(1),
        bio: profile['bio']?.toString() ?? '',
        city: profile['city']?.toString() ?? '',
        country: profile['country']?.toString() ?? '',
        distance: (profile['distance_km'] as num?)?.toDouble(),
        distanceEstimated: profile['distance_estimated'] == true,
        sameCity: profile['same_city'] == true,
        interests: (profile['interests'] as List? ?? const [])
            .map((interest) => interest.toString())
            .toList(growable: false),
        relationshipTypesSought: relationshipTypes,
        relationshipType: relationshipTypes.isEmpty
            ? profile['relationship_type']?.toString() ?? ''
            : relationshipTypes.first,
        isVerified: profile['is_verified'] == true,
        isPremium: profile['is_premium'] == true,
        lastActive:
            DateTime.tryParse(profile['last_active']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
        compatibilityScore:
            (profile['compatibility_score'] as num?)?.toDouble() ?? 0,
      ),
      type: type,
      timestamp: timestamp,
      isMatched: json['is_matched'] == true,
      matchId: json['match_id']?.toString(),
      canRevoke: json['can_revoke'] == true,
    );
  }

  ServerFailure _failureFromDio(
    DioException error, {
    required String fallbackKey,
  }) {
    final data = error.response?.data;
    final payload = data is Map
        ? Map<String, dynamic>.from(data)
        : const <String, dynamic>{};
    final code = (payload['code'] ?? payload['error'])?.toString();
    final key =
        code == 'cannot_revoke_match' || code == 'active_match_requires_unmatch'
            ? 'history.revoke_match_requires_unmatch'
            : code == 'bulk_revoke_not_possible'
                ? 'history.bulk_revoke_changed'
                : fallbackKey;
    return ServerFailure(
        code: code, message: LocalizationService.translate(key));
  }
}
