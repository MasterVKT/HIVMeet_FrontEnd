// test/presentation/blocs/profile/profile_bloc_test.dart

import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';
import 'package:hivmeet/domain/usecases/profile/block_user.dart' as block;
import 'package:hivmeet/domain/usecases/profile/delete_photo.dart' as delete;
import 'package:hivmeet/domain/usecases/profile/get_current_profile.dart';
import 'package:hivmeet/domain/usecases/profile/reorder_photos.dart' as reorder;
import 'package:hivmeet/domain/usecases/profile/set_main_photo.dart'
    as set_main;
import 'package:hivmeet/domain/usecases/profile/toggle_profile_visibility.dart'
    as toggle;
import 'package:hivmeet/domain/usecases/profile/unblock_user.dart' as unblock;
import 'package:hivmeet/domain/usecases/profile/update_location.dart'
    as update_loc;
import 'package:hivmeet/domain/usecases/profile/update_profile.dart';
import 'package:hivmeet/domain/usecases/profile/upload_photo.dart' as upload;
import 'package:hivmeet/presentation/blocs/profile/profile_bloc.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_event.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_state.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCurrentProfile extends Mock implements GetCurrentProfile {}

class MockUpdateProfile extends Mock implements UpdateProfile {}

class MockUploadPhoto extends Mock implements upload.UploadPhoto {}

class MockDeletePhoto extends Mock implements delete.DeletePhoto {}

class MockSetMainPhoto extends Mock implements set_main.SetMainPhoto {}

class MockReorderPhotos extends Mock implements reorder.ReorderPhotos {}

class MockUpdateLocation extends Mock implements update_loc.UpdateLocation {}

class MockBlockUser extends Mock implements block.BlockUser {}

class MockUnblockUser extends Mock implements unblock.UnblockUser {}

class MockToggleProfileVisibility extends Mock
    implements toggle.ToggleProfileVisibility {}

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late ProfileBloc bloc;
  late MockGetCurrentProfile mockGetCurrentProfile;
  late MockUpdateProfile mockUpdateProfile;
  late MockUploadPhoto mockUploadPhoto;
  late MockDeletePhoto mockDeletePhoto;
  late MockSetMainPhoto mockSetMainPhoto;
  late MockReorderPhotos mockReorderPhotos;
  late MockUpdateLocation mockUpdateLocation;
  late MockBlockUser mockBlockUser;
  late MockUnblockUser mockUnblockUser;
  late MockToggleProfileVisibility mockToggleProfileVisibility;
  late MockProfileRepository mockProfileRepository;

  setUp(() {
    mockGetCurrentProfile = MockGetCurrentProfile();
    mockUpdateProfile = MockUpdateProfile();
    mockUploadPhoto = MockUploadPhoto();
    mockDeletePhoto = MockDeletePhoto();
    mockSetMainPhoto = MockSetMainPhoto();
    mockReorderPhotos = MockReorderPhotos();
    mockUpdateLocation = MockUpdateLocation();
    mockBlockUser = MockBlockUser();
    mockUnblockUser = MockUnblockUser();
    mockToggleProfileVisibility = MockToggleProfileVisibility();
    mockProfileRepository = MockProfileRepository();

    bloc = ProfileBloc(
      getCurrentProfile: mockGetCurrentProfile,
      updateProfile: mockUpdateProfile,
      uploadPhoto: mockUploadPhoto,
      deletePhoto: mockDeletePhoto,
      setMainPhoto: mockSetMainPhoto,
      reorderPhotos: mockReorderPhotos,
      updateLocation: mockUpdateLocation,
      blockUser: mockBlockUser,
      unblockUser: mockUnblockUser,
      toggleProfileVisibility: mockToggleProfileVisibility,
      profileRepository: mockProfileRepository,
    );

    registerFallbackValue(NoParams());
    registerFallbackValue(const UpdateProfileParams());
    registerFallbackValue(
      upload.UploadPhotoParams(
        photo: File('fallback.jpg'),
        isMain: false,
      ),
    );
    registerFallbackValue(
      delete.DeletePhotoParams(photoUrl: 'https://example.com/fallback.jpg'),
    );
    registerFallbackValue(
      set_main.SetMainPhotoParams(photoUrl: 'https://example.com/fallback.jpg'),
    );
    registerFallbackValue(
      reorder.ReorderPhotosParams(photoUrls: const []),
    );
    registerFallbackValue(
      update_loc.UpdateLocationParams(
        latitude: 0,
        longitude: 0,
        city: '',
        country: '',
      ),
    );
    registerFallbackValue(const block.BlockUserParams(userId: 'fallback'));
    registerFallbackValue(const unblock.UnblockUserParams(userId: 'fallback'));
    registerFallbackValue(
      const toggle.ToggleProfileVisibilityParams(isHidden: false),
    );
  });

  tearDown(() => bloc.close());

  Profile createProfileFixture({
    String id = 'profile_1',
    String userId = 'user_1',
    String displayName = 'Test User',
    String bio = 'Hello',
    DateTime? birthDate,
  }) {
    final now = birthDate ?? DateTime(1990, 1, 1);
    final created = DateTime(2024, 1, 1);
    return Profile(
      id: id,
      userId: userId,
      displayName: displayName,
      birthDate: now,
      bio: bio,
      location: const Location(
          latitude: 48.8566, longitude: 2.3522, geohash: 'u09tvqx'),
      city: 'Paris',
      country: 'France',
      interests: const ['music', 'travel'],
      relationshipType: 'long_term',
      relationshipTypesSought: const ['long_term'],
      photos: const PhotoCollection(main: 'https://example.com/main.jpg'),
      searchPreferences: const SearchPreferences(
        minAge: 18,
        maxAge: 99,
        maxDistance: 50,
        interestedIn: ['female'],
        relationshipTypes: ['long_term'],
      ),
      lastActive: DateTime.now(),
      isHidden: false,
      verificationStatus: const VerificationStatus(
        status: 'not_started',
        documents: {},
      ),
      privacySettings: const PrivacySettings(),
      createdAt: created,
      updatedAt: created,
    );
  }

  void stubLoadProfileSnapshot(Profile profile) {
    when(() => mockGetCurrentProfile(any()))
        .thenAnswer((_) async => Right(profile));
    when(() => mockProfileRepository.getPremiumProfileStatus())
        .thenAnswer((_) async => const Left(ServerFailure(message: 'n/a')));
    when(() => mockProfileRepository.getVerificationDetails())
        .thenAnswer((_) async => const Left(ServerFailure(message: 'n/a')));
    when(() => mockProfileRepository.getPrivacyPreferences())
        .thenAnswer((_) async => const Left(ServerFailure(message: 'n/a')));
    when(() => mockProfileRepository.getNotificationPreferences())
        .thenAnswer((_) async => const Left(ServerFailure(message: 'n/a')));
    when(() => mockProfileRepository.getBlockedUsers())
        .thenAnswer((_) async => const Left(ServerFailure(message: 'n/a')));
  }

  group('ProfileBloc', () {
    test('initial state is ProfileInitial', () {
      expect(bloc.state, equals(ProfileInitial()));
    });

    group('LoadProfile', () {
      test('should emit [ProfileLoading, ProfileLoaded] when successful',
          () async {
        final profile = createProfileFixture();
        stubLoadProfileSnapshot(profile);

        final expected = [
          ProfileLoading(),
          ProfileLoaded(profile: profile),
        ];
        expectLater(bloc.stream, emitsInOrder(expected));

        bloc.add(LoadProfile());
      });

      test('should emit [ProfileLoading, ProfileError] when fails', () async {
        const tFailure = ServerFailure(message: 'Failed to load profile');
        when(() => mockGetCurrentProfile(any()))
            .thenAnswer((_) async => const Left(tFailure));

        final expected = [
          ProfileLoading(),
          const ProfileError(message: 'Failed to load profile'),
        ];
        expectLater(bloc.stream, emitsInOrder(expected));

        bloc.add(LoadProfile());
      });
    });

    group('UpdateProfileEvent', () {
      test(
          'should emit [ProfileUpdating, ProfileActionSuccess] when successful',
          () async {
        final current = createProfileFixture();
        final updated = current.copyWith(bio: 'Updated bio');

        // Seed loaded state so _currentLoaded returns current profile.
        stubLoadProfileSnapshot(current);
        bloc.add(LoadProfile());
        await Future.delayed(const Duration(milliseconds: 50));

        when(() => mockUpdateProfile(any()))
            .thenAnswer((_) async => Right(updated));

        final expected = [
          ProfileUpdating(profile: current),
          ProfileActionSuccess(
            message: 'profile.success_updated',
            profile: updated,
            loadedState: ProfileLoaded(profile: updated),
          ),
        ];
        expectLater(bloc.stream, emitsInOrder(expected));

        bloc.add(const UpdateProfileEvent(bio: 'Updated bio'));
      });

      test('should emit [ProfileUpdating, ProfileError] when fails', () async {
        final current = createProfileFixture();
        stubLoadProfileSnapshot(current);
        bloc.add(LoadProfile());
        await Future.delayed(const Duration(milliseconds: 50));

        const tFailure = ServerFailure(message: 'Update failed');
        when(() => mockUpdateProfile(any()))
            .thenAnswer((_) async => const Left(tFailure));

        final expected = [
          ProfileUpdating(profile: current),
          ProfileError(
            message: 'Update failed',
            profile: current,
            loadedState: ProfileLoaded(profile: current),
          ),
        ];
        expectLater(bloc.stream, emitsInOrder(expected));

        bloc.add(const UpdateProfileEvent(bio: 'Updated bio'));
      });

      test('should do nothing if no loaded state exists', () async {
        const tFailure = ServerFailure(message: 'Should not be called');
        when(() => mockUpdateProfile(any()))
            .thenAnswer((_) async => const Left(tFailure));

        // Because _currentLoaded is null, the bloc returns immediately without
        // emitting anything. We expect the stream to complete with no events.
        expectLater(bloc.stream, emitsDone);

        bloc.add(const UpdateProfileEvent(bio: 'Updated bio'));
        await bloc.close();

        verifyNever(() => mockUpdateProfile(any()));
      });
    });

    group('UploadPhoto', () {
      test('should emit [PhotoUploading, ProfileActionSuccess] when successful',
          () async {
        final current = createProfileFixture();
        final updated = current.copyWith(
          photos: const PhotoCollection(
            main: 'https://example.com/main.jpg',
            others: ['https://example.com/new.jpg'],
          ),
        );
        stubLoadProfileSnapshot(current);
        bloc.add(LoadProfile());
        await Future.delayed(const Duration(milliseconds: 50));

        when(() => mockUploadPhoto(any())).thenAnswer(
            (_) async => const Right('https://example.com/new.jpg'));
        // After upload, the bloc reloads the snapshot to build the success state.
        when(() => mockGetCurrentProfile(any()))
            .thenAnswer((_) async => Right(updated));

        final expected = [
          PhotoUploading(profile: current, progress: 0),
          ProfileActionSuccess(
            message: 'profile.success_photo_uploaded',
            profile: updated,
            loadedState: ProfileLoaded(profile: updated),
          ),
        ];
        expectLater(bloc.stream, emitsInOrder(expected));

        final file = File('${Directory.systemTemp.path}/test_photo.jpg');
        bloc.add(UploadPhoto(photo: file, isMain: false));
      });

      test('should emit [PhotoUploading, ProfileError] when upload fails',
          () async {
        final current = createProfileFixture();
        stubLoadProfileSnapshot(current);
        bloc.add(LoadProfile());
        await Future.delayed(const Duration(milliseconds: 50));

        const tFailure = ServerFailure(message: 'Upload failed');
        when(() => mockUploadPhoto(any()))
            .thenAnswer((_) async => const Left(tFailure));

        final expected = [
          PhotoUploading(profile: current, progress: 0),
          ProfileError(
            message: 'Upload failed',
            profile: current,
            loadedState: ProfileLoaded(profile: current),
          ),
        ];
        expectLater(bloc.stream, emitsInOrder(expected));

        final file = File('${Directory.systemTemp.path}/test_photo.jpg');
        bloc.add(UploadPhoto(photo: file, isMain: false));
      });
    });

    group('DeletePhoto', () {
      test('should emit ProfileActionSuccess when deletion succeeds', () async {
        final current = createProfileFixture();
        final updated = current.copyWith(
          photos: const PhotoCollection(main: ''),
        );
        stubLoadProfileSnapshot(current);
        bloc.add(LoadProfile());
        await Future.delayed(const Duration(milliseconds: 50));

        when(() => mockDeletePhoto(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockGetCurrentProfile(any()))
            .thenAnswer((_) async => Right(updated));

        final expected = [
          ProfileActionSuccess(
            message: 'profile.success_photo_deleted',
            profile: updated,
            loadedState: ProfileLoaded(profile: updated),
          ),
        ];
        expectLater(bloc.stream, emitsInOrder(expected));

        bloc.add(const DeletePhoto(photoUrl: 'https://example.com/main.jpg'));
      });

      test('should use repository deleteProfilePhotoById when photoId provided',
          () async {
        final current = createProfileFixture();
        final updated = current.copyWith(
          photos: const PhotoCollection(main: ''),
        );
        stubLoadProfileSnapshot(current);
        bloc.add(LoadProfile());
        await Future.delayed(const Duration(milliseconds: 50));

        when(() => mockProfileRepository.deleteProfilePhotoById('photo_123'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockGetCurrentProfile(any()))
            .thenAnswer((_) async => Right(updated));

        bloc.add(const DeletePhoto(
          photoUrl: 'https://example.com/main.jpg',
          photoId: 'photo_123',
        ));
        await Future.delayed(const Duration(milliseconds: 50));

        verify(() => mockProfileRepository.deleteProfilePhotoById('photo_123'))
            .called(1);
        verifyNever(() => mockDeletePhoto(any()));
      });
    });

    group('RGPD actions', () {
      test('RequestDataExport emits ProfileActionPending on success', () async {
        final current = createProfileFixture();
        stubLoadProfileSnapshot(current);
        bloc.add(LoadProfile());
        await Future.delayed(const Duration(milliseconds: 50));

        final result = DataRequestResult(
          requestId: 'export_1',
          message: 'Export requested',
          requestedAt: DateTime(2024, 1, 1),
          status: 'pending',
        );
        when(() => mockProfileRepository.requestDataExport())
            .thenAnswer((_) async => Right(result));

        final expected = [
          ProfileSectionLoading(ProfileLoaded(profile: current)),
          ProfileActionPending(
            message: 'Export requested',
            requestId: 'export_1',
            actionType: 'export',
            requestedAt: DateTime(2024, 1, 1),
            loadedState: ProfileLoaded(profile: current),
          ),
        ];
        expectLater(bloc.stream, emitsInOrder(expected));

        bloc.add(RequestDataExport());
      });

      test('RequestAccountDeletion emits ProfileActionPending on success',
          () async {
        final current = createProfileFixture();
        stubLoadProfileSnapshot(current);
        bloc.add(LoadProfile());
        await Future.delayed(const Duration(milliseconds: 50));

        final result = DataRequestResult(
          requestId: 'delete_1',
          message: 'Deletion requested',
          requestedAt: DateTime(2024, 1, 1),
          status: 'pending',
        );
        when(() => mockProfileRepository.requestAccountDeletion())
            .thenAnswer((_) async => Right(result));

        final expected = [
          ProfileSectionLoading(ProfileLoaded(profile: current)),
          ProfileActionPending(
            message: 'Deletion requested',
            requestId: 'delete_1',
            actionType: 'deletion',
            requestedAt: DateTime(2024, 1, 1),
            loadedState: ProfileLoaded(profile: current),
          ),
        ];
        expectLater(bloc.stream, emitsInOrder(expected));

        bloc.add(RequestAccountDeletion());
      });

      test('RequestDataExport emits ProfileError on failure', () async {
        final current = createProfileFixture();
        stubLoadProfileSnapshot(current);
        bloc.add(LoadProfile());
        await Future.delayed(const Duration(milliseconds: 50));

        const tFailure = ServerFailure(message: 'Export request failed');
        when(() => mockProfileRepository.requestDataExport())
            .thenAnswer((_) async => const Left(tFailure));

        final expected = [
          ProfileSectionLoading(ProfileLoaded(profile: current)),
          ProfileError(
            message: 'Export request failed',
            profile: current,
            loadedState: ProfileLoaded(profile: current),
          ),
        ];
        expectLater(bloc.stream, emitsInOrder(expected));

        bloc.add(RequestDataExport());
      });
    });
  });
}
