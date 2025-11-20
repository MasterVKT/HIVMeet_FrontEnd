// lib/domain/repositories/match_repository.dart

import 'package:dartz/dartz.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/entities/profile.dart';

abstract class MatchRepository {
  // Discovery
  Future<Either<Failure, List<DiscoveryProfile>>> getDiscoveryProfiles({
    int limit = 20,
    String? lastProfileId,
  });

  Future<Either<Failure, DiscoveryProfile>> getDiscoveryProfile(
      String profileId);

  // Swipe actions
  Future<Either<Failure, SwipeResult>> likeProfile(String profileId);
  Future<Either<Failure, SwipeResult>> superLikeProfile(String profileId);
  Future<Either<Failure, void>> dislikeProfile(String profileId);
  Future<Either<Failure, SwipeResult>> rewindLastSwipe();

  // Matches
  Future<Either<Failure, List<Match>>> getMatches({
    int limit = 20,
    String? lastMatchId,
  });

  Future<Either<Failure, Match>> getMatch(String matchId);
  Future<Either<Failure, void>> deleteMatch(String matchId);
  Stream<List<Match>> watchMatches();

  // Likes received (Premium)
  Future<Either<Failure, List<DiscoveryProfile>>> getLikesReceived({
    int limit = 20,
    String? lastProfileId,
  });

  Future<Either<Failure, int>> getLikesReceivedCount();

  // Daily limits
  Future<Either<Failure, DailyLikeLimit>> getDailyLikeLimit();
  Future<Either<Failure, int>> getSuperLikesRemaining();

  // Boost (Premium)
  Future<Either<Failure, BoostStatus>> activateBoost();
  Future<Either<Failure, BoostStatus>> getBoostStatus();

  // Filters
  Future<Either<Failure, void>> updateSearchFilters(SearchPreferences filters);
  Future<Either<Failure, SearchPreferences>> getSearchFilters();
}
