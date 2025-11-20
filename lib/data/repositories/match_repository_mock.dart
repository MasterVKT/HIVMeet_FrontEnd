// lib/data/repositories/match_repository_mock.dart

import 'package:dartz/dartz.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';

class MatchRepositoryMock implements MatchRepository {
  @override
  Future<Either<Failure, List<DiscoveryProfile>>> getDiscoveryProfiles({
    int limit = 20,
    String? lastProfileId,
  }) async {
    // Simuler un délai réseau réaliste (200-800ms)
    await Future.delayed(
        Duration(milliseconds: 200 + (DateTime.now().millisecond % 600)));

    // Calculer l'index de départ basé sur lastProfileId
    int startIndex = 0;
    if (lastProfileId != null) {
      final match = RegExp(r'profile_(\d+)').firstMatch(lastProfileId);
      if (match != null) {
        startIndex = int.parse(match.group(1)!) + 1;
      }
    }

    // Données mock pour les tests
    final mockProfiles = List.generate(limit, (index) {
      final globalIndex = startIndex + index;
      return DiscoveryProfile(
        id: 'profile_$globalIndex',
        displayName: 'Utilisateur $globalIndex',
        age: 25 + (globalIndex % 20),
        mainPhotoUrl: 'https://picsum.photos/400/600?random=$globalIndex',
        otherPhotosUrls: [
          'https://picsum.photos/400/600?random=${globalIndex + 100}',
          'https://picsum.photos/400/600?random=${globalIndex + 200}',
        ],
        bio:
            'Bio de l\'utilisateur $globalIndex. Passionné(e) de musique et de voyage.',
        city: 'Paris',
        country: 'France',
        distance: (globalIndex * 2.5).toDouble(),
        interests: [
          'Musique',
          'Voyage',
          'Sport',
          'Cinéma',
          'Lecture',
        ].take(2 + (globalIndex % 3)).toList(),
        relationshipType: [
          'any',
          'friendship',
          'relationship',
          'casual'
        ][globalIndex % 4],
        isVerified: globalIndex % 3 == 0,
        isPremium: globalIndex % 5 == 0,
        lastActive: DateTime.now().subtract(Duration(minutes: globalIndex * 5)),
        compatibilityScore: 60.0 + (globalIndex * 2.0),
      );
    });

    return Right(mockProfiles);
  }

  @override
  Future<Either<Failure, DiscoveryProfile>> getDiscoveryProfile(
      String profileId) async {
    // Simuler un profil spécifique
    final profile = DiscoveryProfile(
      id: profileId,
      displayName: 'Profil $profileId',
      age: 28,
      mainPhotoUrl: 'https://picsum.photos/400/600?random=$profileId',
      otherPhotosUrls: [],
      bio: 'Bio du profil $profileId',
      city: 'Paris',
      country: 'France',
      distance: 5.0,
      interests: ['Musique', 'Voyage'],
      relationshipType: 'any',
      isVerified: true,
      isPremium: false,
      lastActive: DateTime.now(),
      compatibilityScore: 85.0,
    );
    return Right(profile);
  }

  @override
  Future<Either<Failure, SwipeResult>> likeProfile(String profileId) async {
    // Simuler un match aléatoire (20% de chance)
    final isMatch = (DateTime.now().millisecond % 5) == 0;
    return Right(SwipeResult(
      isMatch: isMatch,
      matchId:
          isMatch ? 'match_${DateTime.now().millisecondsSinceEpoch}' : null,
    ));
  }

  @override
  Future<Either<Failure, void>> dislikeProfile(String profileId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, SwipeResult>> superLikeProfile(
      String profileId) async {
    // Simuler un match aléatoire (30% de chance pour super like)
    final isMatch = (DateTime.now().millisecond % 3) == 0;
    return Right(SwipeResult(
      isMatch: isMatch,
      matchId:
          isMatch ? 'match_${DateTime.now().millisecondsSinceEpoch}' : null,
    ));
  }

  @override
  Future<Either<Failure, SwipeResult>> rewindLastSwipe() async {
    // Simuler un match aléatoire (10% de chance pour rewind)
    final isMatch = (DateTime.now().millisecond % 10) == 0;
    return Right(SwipeResult(
      isMatch: isMatch,
      matchId:
          isMatch ? 'match_${DateTime.now().millisecondsSinceEpoch}' : null,
    ));
  }

  @override
  Future<Either<Failure, List<Match>>> getMatches({
    int limit = 20,
    String? lastMatchId,
  }) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, Match>> getMatch(String matchId) async {
    return Left(ServerFailure(message: 'Match not found'));
  }

  @override
  Future<Either<Failure, void>> deleteMatch(String matchId) async {
    return const Right(null);
  }

  @override
  Stream<List<Match>> watchMatches() async* {
    yield [];
  }

  @override
  Future<Either<Failure, List<DiscoveryProfile>>> getLikesReceived({
    int limit = 20,
    String? lastProfileId,
  }) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, int>> getLikesReceivedCount() async {
    return const Right(0);
  }

  @override
  Future<Either<Failure, DailyLikeLimit>> getDailyLikeLimit() async {
    // Simuler une limite quotidienne
    final now = DateTime.now();
    final resetTime = DateTime(now.year, now.month, now.day + 1);
    final remaining = 10 - (now.hour * 2); // Décrémente selon l'heure

    return Right(DailyLikeLimit(
      remainingLikes: remaining.clamp(0, 10),
      totalLikes: 10,
      resetAt: resetTime,
    ));
  }

  @override
  Future<Either<Failure, int>> getSuperLikesRemaining() async {
    return const Right(3);
  }

  @override
  Future<Either<Failure, BoostStatus>> activateBoost() async {
    return Right(BoostStatus(
      isActive: true,
      endsAt: DateTime.now().add(const Duration(hours: 1)),
      boostsRemaining: 2,
      activatedAt: DateTime.now(),
    ));
  }

  @override
  Future<Either<Failure, BoostStatus>> getBoostStatus() async {
    return Right(BoostStatus(
      isActive: false,
      endsAt: null,
      boostsRemaining: 3,
      activatedAt: null,
    ));
  }

  @override
  Future<Either<Failure, void>> updateSearchFilters(
      SearchPreferences filters) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, SearchPreferences>> getSearchFilters() async {
    final filters = SearchPreferences(
      minAge: 18,
      maxAge: 99,
      maxDistance: 50.0,
      interestedIn: [],
      relationshipTypes: [],
      showVerifiedOnly: false,
    );
    return Right(filters);
  }
}
