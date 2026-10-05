import 'package:dartz/dartz.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/interaction_history.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/repositories/interaction_history_repository.dart';

/// In-memory implementation kept contract-compatible with the REST repository.
class InteractionHistoryRepositoryMock implements InteractionHistoryRepository {
  final List<InteractionHistory> _likes = [];
  final List<InteractionHistory> _passes = [];

  InteractionHistoryRepositoryMock() {
    _seed();
  }

  @override
  Future<Either<Failure, InteractionHistoryPage>> getMyLikes({
    int page = 1,
    int pageSize = 20,
    String query = '',
    InteractionMatchFilter matchFilter = InteractionMatchFilter.all,
  }) =>
      _page(_likes, page, pageSize, query, matchFilter);

  @override
  Future<Either<Failure, InteractionHistoryPage>> getMyPasses({
    int page = 1,
    int pageSize = 20,
    String query = '',
    InteractionMatchFilter matchFilter = InteractionMatchFilter.all,
  }) =>
      _page(_passes, page, pageSize, query, matchFilter);

  Future<Either<Failure, InteractionHistoryPage>> _page(
    List<InteractionHistory> source,
    int page,
    int pageSize,
    String query,
    InteractionMatchFilter filter,
  ) async {
    final filtered = _filter(source, query, filter);
    final start = (page - 1) * pageSize;
    final entries = start >= filtered.length
        ? const <InteractionHistory>[]
        : filtered.sublist(
            start,
            (start + pageSize).clamp(0, filtered.length).toInt(),
          );
    return Right(InteractionHistoryPage(
      interactions: entries,
      totalCount: filtered.length,
      selectableCount: filtered.where((item) => item.canRevoke).length,
      hasNextPage: start + pageSize < filtered.length,
    ));
  }

  @override
  Future<Either<Failure, void>> revokeInteraction(String interactionId) async {
    final result = await revokeInteractions(BulkRevokeRequest(
      historyType: _likes.any((item) => item.id == interactionId)
          ? InteractionHistoryType.likes
          : InteractionHistoryType.passes,
      interactionIds: [interactionId],
    ));
    return result.fold(Left.new, (_) => const Right(null));
  }

  @override
  Future<Either<Failure, BulkRevokeResult>> revokeInteractions(
    BulkRevokeRequest request,
  ) async {
    final source =
        request.historyType == InteractionHistoryType.likes ? _likes : _passes;
    final selected = request.selectAll
        ? _filter(source, request.query, request.matchFilter)
        : source
            .where((item) => request.interactionIds.contains(item.id))
            .toList();
    if (selected.any((item) => !item.canRevoke)) {
      return const Left(ServerFailure(
        code: 'bulk_revoke_not_possible',
        message: 'Selection cannot be revoked.',
      ));
    }
    final ids = selected.map((item) => item.id).toList(growable: false);
    source.removeWhere((item) => ids.contains(item.id));
    return Right(BulkRevokeResult(
      revokedCount: ids.length,
      revokedInteractionIds: ids,
    ));
  }

  @override
  Future<Either<Failure, InteractionStats>> getStats() async => Right(
        InteractionStats(
          totalLikes:
              _likes.where((item) => item.type == InteractionType.like).length,
          totalSuperLikes: _likes
              .where((item) => item.type == InteractionType.superLike)
              .length,
          totalDislikes: _passes.length,
          totalMatches: _likes.where((item) => item.isMatched).length,
          likeToMatchRatio: 0,
          totalInteractionsToday: 0,
          dailyLimit: 0,
          remainingToday: 0,
        ),
      );

  List<InteractionHistory> _filter(
    List<InteractionHistory> source,
    String query,
    InteractionMatchFilter filter,
  ) {
    final needle = query.trim().toLowerCase();
    return source.where((item) {
      final matchesFilter = switch (filter) {
        InteractionMatchFilter.all => true,
        InteractionMatchFilter.matched => item.isMatched,
        InteractionMatchFilter.unmatched => !item.isMatched,
      };
      return matchesFilter &&
          (needle.isEmpty ||
              item.profile.displayName.toLowerCase().contains(needle));
    }).toList(growable: false);
  }

  void _seed() {
    final now = DateTime.now();
    for (var index = 0; index < 25; index++) {
      _likes.add(_entry(
        id: 'like-$index',
        type: index % 5 == 0 ? InteractionType.superLike : InteractionType.like,
        at: now.subtract(Duration(days: index)),
        matched: index % 4 == 0,
      ));
      _passes.add(_entry(
        id: 'pass-$index',
        type: InteractionType.dislike,
        at: now.subtract(Duration(days: index + 1)),
      ));
    }
  }

  InteractionHistory _entry({
    required String id,
    required InteractionType type,
    required DateTime at,
    bool matched = false,
  }) {
    final name = type == InteractionType.dislike ? 'Marc' : 'Sophie';
    return InteractionHistory(
      id: id,
      profile: DiscoveryProfile(
        id: 'profile-$id',
        displayName: name,
        age: 30,
        mainPhotoUrl: '',
        otherPhotosUrls: const [],
        bio: '',
        city: '',
        country: '',
        interests: const [],
        relationshipType: '',
        isVerified: false,
        isPremium: false,
        lastActive: at,
        compatibilityScore: 0,
      ),
      type: type,
      timestamp: at,
      isMatched: matched,
      matchId: matched ? 'match-$id' : null,
      canRevoke: !matched,
    );
  }
}
