import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';
import 'package:hivmeet/domain/usecases/match/unlock_free_match.dart';

class _MockMatchRepository extends Mock implements MatchRepository {}

void main() {
  test('delegates the explicit Free unlock retry to the repository', () async {
    final repository = _MockMatchRepository();
    final useCase = UnlockFreeMatch(repository);
    final match = Match(
      id: 'match-1',
      profile: _profile(),
      matchedAt: DateTime(2026, 9, 22),
      accessLevel: 'free_limited',
      freeMessagesRemaining: 10,
    );
    when(() => repository.unlockFreeMatch('match-1'))
        .thenAnswer((_) async => Right(match));

    final result = await useCase(const UnlockFreeMatchParams('match-1'));

    expect(result, Right(match));
    verify(() => repository.unlockFreeMatch('match-1')).called(1);
  });
}

Profile _profile() => Profile(
      id: 'profile-1',
      userId: 'user-1',
      displayName: 'Profile',
      birthDate: DateTime(1990, 1, 1),
      bio: '',
      location: const Location(latitude: 0, longitude: 0, geohash: ''),
      city: '',
      country: '',
      interests: const [],
      relationshipType: 'casual',
      photos: const PhotoCollection(main: ''),
      searchPreferences: const SearchPreferences(
        minAge: 18,
        maxAge: 99,
        maxDistance: 50,
        interestedIn: [],
        relationshipTypes: [],
      ),
      lastActive: DateTime(2026, 9, 22),
      isHidden: false,
      verificationStatus: const VerificationStatus(
        status: 'not_started',
        documents: {},
      ),
      privacySettings: const PrivacySettings(
        profileVisibility: 'visible_to_all',
        showOnlineStatus: true,
        showDistance: true,
        showExactLocation: false,
        profileDiscoverable: true,
      ),
      createdAt: DateTime(2026, 9, 22),
      updatedAt: DateTime(2026, 9, 22),
    );
