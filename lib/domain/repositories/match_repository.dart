// lib/domain/repositories/match_repository.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
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

class SwipeResult extends Equatable {
  final bool isMatch;
  final String? matchId;
  final Profile? matchedProfile;

  const SwipeResult({
    required this.isMatch,
    this.matchId,
    this.matchedProfile,
  });

  @override
  List<Object?> get props => [isMatch, matchId, matchedProfile];
}

class BoostStatus extends Equatable {
  final bool isActive;
  final DateTime? endsAt;
  final int boostsRemaining;
  final DateTime? activatedAt;

  const BoostStatus({
    required this.isActive,
    this.endsAt,
    required this.boostsRemaining,
    this.activatedAt,
  });

  @override
  List<Object?> get props => [isActive, endsAt, boostsRemaining, activatedAt];
}
