import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/error/exceptions.dart';
import 'package:hivmeet/data/datasources/remote/matching_api.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';

@LazySingleton(as: MatchRepository)
class MatchRepositoryImpl implements MatchRepository {
  final MatchingApi _matchingApi;

  const MatchRepositoryImpl(this._matchingApi);

  @override
  Future<Either<Failure, List<DiscoveryProfile>>> getDiscoveryProfiles({
    int limit = 20,
    String? lastProfileId,
  }) async {
    try {
      final response = await _matchingApi.getDiscoveryProfiles(
        page: 1,
        perPage: limit,
      );

      final profiles = (response.data!['profiles'] as List)
          .map((json) => _mapJsonToDiscoveryProfile(json))
          .toList();

      return Right(profiles);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(
          ServerFailure(message: 'Erreur lors du chargement des profils: $e'));
    }
  }

  @override
  Future<Either<Failure, DiscoveryProfile>> getDiscoveryProfile(
      String profileId) async {
    try {
      // TODO: Implémenter getProfile individuel dans l'API ou utiliser getDiscoveryProfiles
      // Pour l'instant, simulons avec des données fictives
      final profile = DiscoveryProfile(
        id: profileId,
        displayName: 'Profile $profileId',
        age: 25,
        mainPhotoUrl: 'https://example.com/photo.jpg',
        otherPhotosUrls: [],
        bio: 'Profile bio',
        city: 'Paris',
        country: 'France',
        distance: 5.0,
        interests: [],
        relationshipType: 'serious',
        isVerified: false,
        isPremium: false,
        lastActive: DateTime.now(),
        compatibilityScore: 75,
      );
      return Right(profile);
    } catch (e) {
      return Left(
          ServerFailure(message: 'Erreur lors du chargement du profil: $e'));
    }
  }

  @override
  Future<Either<Failure, SwipeResult>> likeProfile(String profileId) async {
    try {
      final response = await _matchingApi.sendLike(
        targetProfileId: profileId,
        action: 'like',
      );

      final data = response.data!;
      final result = data['result'] as String;
      final isMatch = result == 'match';

      return Right(SwipeResult(
        isMatch: isMatch,
        matchId: isMatch ? data['match_id'] as String? : null,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur lors du like: $e'));
    }
  }

  @override
  Future<Either<Failure, SwipeResult>> superLikeProfile(
      String profileId) async {
    try {
      final response = await _matchingApi.sendSuperLike(
        targetProfileId: profileId,
      );

      final data = response.data!;
      final result = data['result'] as String;
      final isMatch = result == 'match';

      return Right(SwipeResult(
        isMatch: isMatch,
        matchId: isMatch ? data['match_id'] as String? : null,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur lors du super like: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> dislikeProfile(String profileId) async {
    try {
      await _matchingApi.sendDislike(
        targetProfileId: profileId,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur lors du dislike: $e'));
    }
  }

  @override
  Future<Either<Failure, SwipeResult>> rewindLastSwipe() async {
    try {
      final response = await _matchingApi.rewindLastSwipe();

      final data = response.data!;
      final success = data['success'] as bool;

      return Right(SwipeResult(
        isMatch: false,
        matchId: null,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur lors du rewind: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Match>>> getMatches({
    int limit = 20,
    String? lastMatchId,
  }) async {
    try {
      final response = await _matchingApi.getMatches(
        page: 1,
        perPage: limit,
      );

      final matches = (response.data!['matches'] as List)
          .map((json) => _mapJsonToMatch(json))
          .toList();

      return Right(matches);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(
          ServerFailure(message: 'Erreur lors du chargement des matches: $e'));
    }
  }

  @override
  Future<Either<Failure, Match>> getMatch(String matchId) async {
    try {
      // TODO: Créer un match temporaire pour les tests
      final match = Match(
        id: 'temp_match_id',
        profile: Profile(
          id: 'temp_profile_id',
          userId: 'temp_user_id',
          displayName: 'Profil temporaire',
          birthDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
          bio: 'Bio temporaire',
          location: const Location(
            latitude: 48.8566,
            longitude: 2.3522,
            geohash: 'u09tvw0',
          ),
          city: 'Paris',
          country: 'France',
          interests: const [],
          relationshipType: RelationshipType.longTerm,
          photos: const PhotoCollection(
            main: 'https://example.com/photo.jpg',
            others: [],
            private: [],
          ),
          searchPreferences: const SearchPreferences(
            minAge: 18,
            maxAge: 50,
            maxDistance: 50.0,
            interestedIn: [Gender.female],
            relationshipTypes: [RelationshipType.longTerm],
          ),
          lastActive: DateTime.now(),
          isHidden: false,
          verificationStatus: const VerificationStatus(
            status: 'not_started',
            documents: {},
          ),
          privacySettings: const PrivacySettings(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        matchedAt: DateTime.now(),
      );
      return Right(match);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(
          ServerFailure(message: 'Erreur lors du chargement du match: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMatch(String matchId) async {
    try {
      // TODO: Implémenter deleteMatch dans l'API
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur lors de la suppression: $e'));
    }
  }

  @override
  Stream<List<Match>> watchMatches() {
    // TODO: Implement real-time stream
    throw UnimplementedError('Real-time matches stream not implemented yet');
  }

  @override
  Future<Either<Failure, List<DiscoveryProfile>>> getLikesReceived({
    int limit = 20,
    String? lastProfileId,
  }) async {
    try {
      // Convertir lastProfileId en page pour l'API
      int page = 1;
      // TODO: Implémenter la pagination basée sur lastProfileId

      final response = await _matchingApi.getLikesReceived(
        page: page,
        limit: limit,
      );

      final profiles = (response.data!['data'] as List)
          .map((json) => _mapJsonToDiscoveryProfile(json))
          .toList();

      return Right(profiles);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getLikesReceivedCount() async {
    try {
      final response = await _matchingApi.getLikesReceivedCount();
      final count = response.data!['count'] as int;
      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(
          ServerFailure(message: 'Erreur lors du chargement du compteur: $e'));
    }
  }

  @override
  Future<Either<Failure, DailyLikeLimit>> getDailyLikeLimit() async {
    try {
      // TODO: Implement API call
      final limit = DailyLikeLimit(
        remainingLikes: 10,
        totalLikes: 50,
        resetAt: DateTime.now().add(const Duration(days: 1)),
      );
      return Right(limit);
    } catch (e) {
      return Left(
          ServerFailure(message: 'Erreur lors du chargement des limites: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getSuperLikesRemaining() async {
    try {
      // TODO: Implement API call
      return const Right(5);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Erreur lors du chargement des super likes: $e'));
    }
  }

  @override
  Future<Either<Failure, BoostStatus>> activateBoost() async {
    try {
      // Utiliser une durée par défaut pour le boost
      final response = await _matchingApi.activateBoost(duration: "30min");
      final data = response.data!;

      final boost = BoostStatus(
        isActive: data['is_active'] as bool,
        activatedAt: data['activated_at'] != null
            ? DateTime.parse(data['activated_at'] as String)
            : null,
        endsAt: data['ends_at'] != null
            ? DateTime.parse(data['ends_at'] as String)
            : null,
        boostsRemaining: data['boosts_remaining'] as int? ?? 0,
      );

      return Right(boost);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BoostStatus>> getBoostStatus() async {
    try {
      final response = await _matchingApi.getBoostStatus();
      final data = response.data!;

      final boost = BoostStatus(
        isActive: data['is_active'] as bool,
        activatedAt: data['activated_at'] != null
            ? DateTime.parse(data['activated_at'] as String)
            : null,
        endsAt: data['ends_at'] != null
            ? DateTime.parse(data['ends_at'] as String)
            : null,
        boostsRemaining: data['boosts_remaining'] as int? ?? 0,
      );

      return Right(boost);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateSearchFilters(
      SearchPreferences filters) async {
    try {
      await _matchingApi.updateFilters(
        ageMin: filters.minAge,
        ageMax: filters.maxAge,
        distanceMaxKm: filters.maxDistance.round(),
        genders: filters.interestedIn,
        relationshipTypes: filters.relationshipTypes,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SearchPreferences>> getSearchFilters() async {
    try {
      // TODO: Implémenter la récupération des filtres depuis l'API
      final filters = SearchPreferences(
        minAge: 18,
        maxAge: 50,
        maxDistance: 50.0,
        interestedIn: const ['all'],
        relationshipTypes: const ['all'],
      );
      return Right(filters);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // Helper methods
  DiscoveryProfile _mapJsonToDiscoveryProfile(Map<String, dynamic> json) {
    return DiscoveryProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      age: json['age'] as int,
      mainPhotoUrl: json['main_photo_url'] as String? ?? '',
      otherPhotosUrls: (json['other_photos'] as List?)?.cast<String>() ?? [],
      bio: json['bio'] as String? ?? '',
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      distance: (json['distance'] as num?)?.toDouble(),
      interests: (json['interests'] as List?)?.cast<String>() ?? [],
      relationshipType: json['relationship_type'] as String? ?? 'casual',
      isVerified: json['is_verified'] as bool? ?? false,
      isPremium: json['is_premium'] as bool? ?? false,
      lastActive: DateTime.parse(json['last_active'] as String),
      compatibilityScore:
          (json['compatibility_score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Match _mapJsonToMatch(Map<String, dynamic> json) {
    // Créer un profil à partir des données du match
    final profileData = json['profile'] ?? json['matched_user'] ?? {};

    // Calculer la date de naissance à partir de l'âge
    final age = profileData['age'] as int? ?? 25;
    final birthDate = DateTime.now().subtract(Duration(days: age * 365));

    final profile = Profile(
      id: profileData['id'] as String? ?? json['matched_user_id'] as String,
      userId: profileData['user_id'] as String? ??
          profileData['id'] as String? ??
          json['matched_user_id'] as String,
      displayName: profileData['display_name'] as String? ?? 'Utilisateur',
      birthDate: birthDate,
      bio: profileData['bio'] as String? ?? '',
      location: Location(
        latitude: (profileData['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (profileData['longitude'] as num?)?.toDouble() ?? 0.0,
        geohash: profileData['geohash'] as String? ?? '',
      ),
      city: profileData['city'] as String? ?? '',
      country: profileData['country'] as String? ?? '',
      interests: (profileData['interests'] as List?)?.cast<String>() ?? [],
      relationshipType: profileData['relationship_type'] as String? ?? 'casual',
      photos: PhotoCollection(
        main: profileData['main_photo_url'] as String? ?? '',
        others: (profileData['other_photos'] as List?)?.cast<String>() ?? [],
        private: const [],
      ),
      searchPreferences: SearchPreferences(
        minAge: 18,
        maxAge: 50,
        maxDistance: 50.0,
        interestedIn: const ['all'],
        relationshipTypes: const ['all'],
        showVerifiedOnly: false,
        showOnlineOnly: false,
      ),
      lastActive: profileData['last_active'] != null
          ? DateTime.parse(profileData['last_active'] as String)
          : DateTime.now(),
      isHidden: profileData['is_hidden'] as bool? ?? false,
      verificationStatus: VerificationStatus(
        status: profileData['verification_status'] as String? ?? 'not_started',
        documents: const {},
      ),
      privacySettings: PrivacySettings(
        profileVisibility:
            profileData['profile_visibility'] as String? ?? 'visible_to_all',
        showOnlineStatus: profileData['show_online_status'] as bool? ?? true,
        showDistance: profileData['show_distance'] as bool? ?? true,
        showExactLocation: profileData['show_exact_location'] as bool? ?? false,
        profileDiscoverable:
            profileData['profile_discoverable'] as bool? ?? true,
      ),
      createdAt: profileData['created_at'] != null
          ? DateTime.parse(profileData['created_at'] as String)
          : DateTime.now(),
      updatedAt: profileData['updated_at'] != null
          ? DateTime.parse(profileData['updated_at'] as String)
          : DateTime.now(),
    );

    // Créer le message si présent
    Message? lastMessage;
    if (json['last_message'] != null) {
      final msgData = json['last_message'] as Map<String, dynamic>;
      lastMessage = Message(
        id: msgData['id'] as String,
        conversationId:
            json['id'] as String, // Utiliser l'ID du match comme conversation
        senderId: msgData['sender_id'] as String,
        content: msgData['content'] as String,
        type: MessageType.text,
        createdAt: DateTime.parse(msgData['created_at'] as String),
        isRead: msgData['is_read'] as bool? ?? false,
        reactions: const {},
        status: MessageStatus.sent,
      );
    }

    return Match(
      id: json['id'] as String,
      profile: profile,
      matchedAt: DateTime.parse(json['created_at'] as String),
      lastMessage: lastMessage,
      isNew: json['is_new'] as bool? ?? false,
      unreadCounts: Map<String, int>.from(json['unread_counts'] ?? {}),
    );
  }

  MatchStatus _parseMatchStatus(String status) {
    switch (status) {
      case 'active':
        return MatchStatus.active;
      case 'pending':
        return MatchStatus.pending;
      case 'expired':
        return MatchStatus.expired;
      case 'deleted':
        return MatchStatus.deleted;
      default:
        return MatchStatus.active;
    }
  }
}
