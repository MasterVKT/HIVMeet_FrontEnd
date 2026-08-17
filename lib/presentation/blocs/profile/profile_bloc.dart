// lib/presentation/blocs/profile/profile_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/usecases/profile/get_current_profile.dart';
import 'package:hivmeet/domain/usecases/profile/update_profile.dart';
import 'package:hivmeet/domain/usecases/profile/upload_photo.dart' as upload;
import 'package:hivmeet/domain/usecases/profile/delete_photo.dart' as delete;
import 'package:hivmeet/domain/usecases/profile/set_main_photo.dart'
    as set_main;
import 'package:hivmeet/domain/usecases/profile/reorder_photos.dart' as reorder;
import 'package:hivmeet/domain/usecases/profile/update_location.dart'
    as update_loc;
import 'package:hivmeet/domain/usecases/profile/block_user.dart' as block;
import 'package:hivmeet/domain/usecases/profile/unblock_user.dart' as unblock;
import 'package:hivmeet/domain/usecases/profile/toggle_profile_visibility.dart'
    as toggle;
import 'profile_event.dart';
import 'profile_state.dart';

@injectable
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetCurrentProfile _getCurrentProfile;
  final UpdateProfile _updateProfile;
  final upload.UploadPhoto _uploadPhoto;
  final delete.DeletePhoto _deletePhoto;
  final set_main.SetMainPhoto _setMainPhoto;
  final reorder.ReorderPhotos _reorderPhotos;
  final update_loc.UpdateLocation _updateLocation;
  final block.BlockUser _blockUser;
  final unblock.UnblockUser _unblockUser;
  final toggle.ToggleProfileVisibility _toggleProfileVisibility;
  final ProfileRepository _profileRepository;

  ProfileBloc({
    required GetCurrentProfile getCurrentProfile,
    required UpdateProfile updateProfile,
    required upload.UploadPhoto uploadPhoto,
    required delete.DeletePhoto deletePhoto,
    required set_main.SetMainPhoto setMainPhoto,
    required reorder.ReorderPhotos reorderPhotos,
    required update_loc.UpdateLocation updateLocation,
    required block.BlockUser blockUser,
    required unblock.UnblockUser unblockUser,
    required toggle.ToggleProfileVisibility toggleProfileVisibility,
    required ProfileRepository profileRepository,
  })  : _getCurrentProfile = getCurrentProfile,
        _updateProfile = updateProfile,
        _uploadPhoto = uploadPhoto,
        _deletePhoto = deletePhoto,
        _setMainPhoto = setMainPhoto,
        _reorderPhotos = reorderPhotos,
        _updateLocation = updateLocation,
        _blockUser = blockUser,
        _unblockUser = unblockUser,
        _toggleProfileVisibility = toggleProfileVisibility,
        _profileRepository = profileRepository,
        super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<CreateProfile>(_onCreateProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UploadPhoto>(_onUploadPhoto);
    on<DeletePhoto>(_onDeletePhoto);
    on<SetMainPhoto>(_onSetMainPhoto);
    on<ReorderPhotos>(_onReorderPhotos);
    on<ToggleProfileVisibility>(_onToggleProfileVisibility);
    on<UpdateLocation>(_onUpdateLocation);
    on<BlockUser>(_onBlockUser);
    on<UnblockUser>(_onUnblockUser);
    on<LoadPrivacyPreferences>(_onLoadPrivacyPreferences);
    on<SavePrivacyPreferences>(_onSavePrivacyPreferences);
    on<LoadNotificationPreferences>(_onLoadNotificationPreferences);
    on<SaveNotificationPreferences>(_onSaveNotificationPreferences);
    on<LoadBlockedUsers>(_onLoadBlockedUsers);
    on<RequestDataExport>(_onRequestDataExport);
    on<RequestAccountDeletion>(_onRequestAccountDeletion);
    on<LoadVerificationDetails>(_onLoadVerificationDetails);
    on<SubmitVerificationDocuments>(_onSubmitVerificationDocuments);
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    final profileResult = await _getCurrentProfile(NoParams());
    await profileResult.fold(
      (failure) async => emit(ProfileError(message: failure.message)),
      (profile) async {
        var loaded = ProfileLoaded(profile: profile);

        final premium = await _profileRepository.getPremiumProfileStatus();
        premium.fold((_) {}, (value) {
          loaded = loaded.copyWith(premiumStatus: value);
        });

        final verification = await _profileRepository.getVerificationDetails();
        verification.fold((_) {}, (value) {
          loaded = loaded.copyWith(verification: value);
        });

        final privacy = await _profileRepository.getPrivacyPreferences();
        privacy.fold((_) {}, (value) {
          loaded = loaded.copyWith(privacyPreferences: value);
        });

        final notifications =
            await _profileRepository.getNotificationPreferences();
        notifications.fold((_) {}, (value) {
          loaded = loaded.copyWith(notificationPreferences: value);
        });

        final blockedUsers = await _profileRepository.getBlockedUsers();
        blockedUsers.fold((_) {}, (value) {
          loaded = loaded.copyWith(blockedUsers: value);
        });

        emit(loaded);
      },
    );
  }

  Future<void> _onCreateProfile(
    CreateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    // 1. Charger le profil existant (get_or_create côté backend).
    final initialProfile = await _getCurrentProfile(NoParams());
    Profile? currentProfile;
    initialProfile.fold(
      (failure) {
        emit(ProfileError(message: failure.message));
        return;
      },
      (profile) => currentProfile = profile,
    );

    if (currentProfile == null) return;

    // 2. Uploader la photo principale.
    emit(PhotoUploading(profile: currentProfile!, progress: 0));
    final uploadResult = await _uploadPhoto(upload.UploadPhotoParams(
      photo: event.mainPhoto,
      isMain: true,
    ));

    await uploadResult.fold(
      (failure) async => emit(ProfileError(
        message: failure.message,
        profile: currentProfile,
      )),
      (_) async {
        // 3. Mettre à jour les informations du profil.
        emit(ProfileUpdating(profile: currentProfile!));
        final searchPreferences = SearchPreferences(
          minAge: event.minAge,
          maxAge: event.maxAge,
          maxDistance: event.maxDistance,
          interestedIn: event.interestedIn,
          relationshipTypes: event.relationshipTypesSought,
        );

        final updateResult = await _updateProfile(UpdateProfileParams(
          bio: event.bio,
          city: event.city,
          country: event.country,
          interests: event.interests,
          relationshipType: event.relationshipType,
          relationshipTypesSought: event.relationshipTypesSought,
          searchPreferences: searchPreferences,
        ));

        await updateResult.fold(
          (failure) async => emit(ProfileError(
            message: failure.message,
            profile: currentProfile,
          )),
          (updatedProfile) async {
            // 4. Mettre à jour la localisation GPS.
            final locationResult = await _updateLocation(
              update_loc.UpdateLocationParams(
                latitude: event.latitude,
                longitude: event.longitude,
                city: event.city,
                country: event.country,
              ),
            );

            locationResult.fold(
              (failure) => emit(ProfileError(
                message: failure.message,
                profile: updatedProfile,
              )),
              (_) => emit(ProfileActionSuccess(
                message: 'profile.success_created',
                profile: updatedProfile,
                loadedState: ProfileLoaded(profile: updatedProfile),
              )),
            );
          },
        );
      },
    );
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;
    emit(ProfileUpdating(profile: current.profile));

    final result = await _updateProfile(
      UpdateProfileParams(
        displayName: event.displayName,
        bio: event.bio,
        city: event.city,
        country: event.country,
        interests: event.interests,
        relationshipType: event.relationshipType,
        relationshipTypesSought: event.relationshipTypesSought,
        searchPreferences: event.searchPreferences,
        privacySettings: event.privacySettings,
      ),
    );

    result.fold(
      (failure) => emit(ProfileError(
        message: failure.message,
        profile: current.profile,
        loadedState: current,
      )),
      (profile) => emit(ProfileActionSuccess(
        message: 'profile.success_updated',
        profile: profile,
        loadedState: current.copyWith(profile: profile),
      )),
    );
  }

  Future<void> _onUploadPhoto(
    UploadPhoto event,
    Emitter<ProfileState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;
    emit(PhotoUploading(profile: current.profile, progress: 0));

    final result = await _uploadPhoto(upload.UploadPhotoParams(
      photo: event.photo,
      isMain: event.isMain,
      isPrivate: event.isPrivate,
      caption: event.caption,
    ));

    await result.fold(
      (failure) async => emit(ProfileError(
        message: failure.message,
        profile: current.profile,
        loadedState: current,
      )),
      (_) async => _reloadAfterAction(emit, 'profile.success_photo_uploaded'),
    );
  }

  Future<void> _onDeletePhoto(
    DeletePhoto event,
    Emitter<ProfileState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;
    final result = event.photoId != null
        ? await _profileRepository.deleteProfilePhotoById(event.photoId!)
        : await _deletePhoto(
            delete.DeletePhotoParams(photoUrl: event.photoUrl));

    await result.fold(
      (failure) async => emit(ProfileError(
        message: failure.message,
        profile: current.profile,
        loadedState: current,
      )),
      (_) async => _reloadAfterAction(emit, 'profile.success_photo_deleted'),
    );
  }

  Future<void> _onSetMainPhoto(
    SetMainPhoto event,
    Emitter<ProfileState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;
    final result = event.photoId != null
        ? await _profileRepository.setMainPhotoById(event.photoId!)
        : await _setMainPhoto(
            set_main.SetMainPhotoParams(photoUrl: event.photoUrl),
          );

    await result.fold(
      (failure) async => emit(ProfileError(
        message: failure.message,
        profile: current.profile,
        loadedState: current,
      )),
      (_) async => _reloadAfterAction(emit, 'profile.success_main_photo'),
    );
  }

  Future<void> _onReorderPhotos(
    ReorderPhotos event,
    Emitter<ProfileState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;
    final result = await _reorderPhotos(
        reorder.ReorderPhotosParams(photoUrls: event.photoUrls));
    result.fold(
      (failure) => emit(ProfileError(
        message: failure.message,
        profile: current.profile,
        loadedState: current,
      )),
      (_) => emit(ProfileActionSuccess(
        message: 'profile.feature_unavailable',
        profile: current.profile,
        loadedState: current,
      )),
    );
  }

  Future<void> _onToggleProfileVisibility(
    ToggleProfileVisibility event,
    Emitter<ProfileState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;
    final result = await _toggleProfileVisibility(
      toggle.ToggleProfileVisibilityParams(isHidden: event.isHidden),
    );
    await result.fold(
      (failure) async => emit(ProfileError(
        message: failure.message,
        profile: current.profile,
        loadedState: current,
      )),
      (_) async => _reloadAfterAction(emit, 'profile.success_privacy_saved'),
    );
  }

  Future<void> _onUpdateLocation(
    UpdateLocation event,
    Emitter<ProfileState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;
    final result = await _updateLocation(update_loc.UpdateLocationParams(
      latitude: event.latitude,
      longitude: event.longitude,
      city: event.city,
      country: event.country,
    ));
    await result.fold(
      (failure) async => emit(ProfileError(
        message: failure.message,
        profile: current.profile,
        loadedState: current,
      )),
      (_) async => _reloadAfterAction(emit, 'profile.success_updated'),
    );
  }

  Future<void> _onLoadPrivacyPreferences(
    LoadPrivacyPreferences event,
    Emitter<ProfileState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) {
      final result = await _profileRepository.getPrivacyPreferences();
      result.fold(
        (failure) => emit(ProfileError(message: failure.message)),
        (prefs) => emit(_emptyProfile.copyWith(privacyPreferences: prefs)),
      );
      return;
    }

    emit(ProfileSectionLoading(current));
    final result = await _profileRepository.getPrivacyPreferences();
    result.fold(
      (failure) => emit(ProfileError(
        message: failure.message,
        profile: current.profile,
        loadedState: current,
      )),
      (prefs) => emit(current.copyWith(privacyPreferences: prefs)),
    );
  }

  Future<void> _onSavePrivacyPreferences(
    SavePrivacyPreferences event,
    Emitter<ProfileState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;
    emit(ProfileSectionLoading(current));
    final result = await _profileRepository.updatePrivacyPreferences(
      event.preferences,
    );
    await result.fold(
      (failure) async => emit(ProfileError(
        message: failure.message,
        profile: current.profile,
        loadedState: current,
      )),
      (_) async => _reloadAfterAction(emit, 'profile.success_privacy_saved'),
    );
  }

  Future<void> _onLoadNotificationPreferences(
    LoadNotificationPreferences event,
    Emitter<ProfileState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) {
      final result = await _profileRepository.getNotificationPreferences();
      result.fold(
        (failure) => emit(ProfileError(message: failure.message)),
        (prefs) => emit(_emptyProfile.copyWith(notificationPreferences: prefs)),
      );
      return;
    }

    emit(ProfileSectionLoading(current));
    final result = await _profileRepository.getNotificationPreferences();
    result.fold(
      (failure) => emit(ProfileError(
        message: failure.message,
        profile: current.profile,
        loadedState: current,
      )),
      (prefs) => emit(current.copyWith(notificationPreferences: prefs)),
    );
  }

  Future<void> _onSaveNotificationPreferences(
    SaveNotificationPreferences event,
    Emitter<ProfileState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;
    emit(ProfileSectionLoading(current));
    final result = await _profileRepository.updateNotificationPreferences(
      event.preferences,
    );
    result.fold(
      (failure) => emit(ProfileError(
        message: failure.message,
        profile: current.profile,
        loadedState: current,
      )),
      (prefs) => emit(ProfileActionSuccess(
        message: 'profile.success_notifications_saved',
        profile: current.profile,
        loadedState: current.copyWith(notificationPreferences: prefs),
      )),
    );
  }

  Future<void> _onLoadBlockedUsers(
    LoadBlockedUsers event,
    Emitter<ProfileState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) {
      final result = await _profileRepository.getBlockedUsers();
      result.fold(
        (failure) => emit(ProfileError(message: failure.message)),
        (blockedUsers) =>
            emit(_emptyProfile.copyWith(blockedUsers: blockedUsers)),
      );
      return;
    }

    emit(ProfileSectionLoading(current));
    final result = await _profileRepository.getBlockedUsers();
    result.fold(
      (failure) => emit(ProfileError(
        message: failure.message,
        profile: current.profile,
        loadedState: current,
      )),
      (blockedUsers) => emit(current.copyWith(blockedUsers: blockedUsers)),
    );
  }

  Future<void> _onBlockUser(
    BlockUser event,
    Emitter<ProfileState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;
    final result =
        await _blockUser(block.BlockUserParams(userId: event.userId));
    await result.fold(
      (failure) async => emit(ProfileError(
        message: failure.message,
        profile: current.profile,
        loadedState: current,
      )),
      (_) async {
        final blocked = await _profileRepository.getBlockedUsers();
        emit(ProfileActionSuccess(
          message: 'profile.success_user_blocked',
          profile: current.profile,
          loadedState: current.copyWith(
            blockedUsers: blocked.getOrElse(() => current.blockedUsers),
          ),
        ));
      },
    );
  }

  Future<void> _onUnblockUser(
    UnblockUser event,
    Emitter<ProfileState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;
    final result =
        await _unblockUser(unblock.UnblockUserParams(userId: event.userId));
    await result.fold(
      (failure) async => emit(ProfileError(
        message: failure.message,
        profile: current.profile,
        loadedState: current,
      )),
      (_) async {
        final blocked = await _profileRepository.getBlockedUsers();
        emit(ProfileActionSuccess(
          message: 'profile.success_user_unblocked',
          profile: current.profile,
          loadedState: current.copyWith(
            blockedUsers: blocked.getOrElse(() => current.blockedUsers),
          ),
        ));
      },
    );
  }

  Future<void> _onRequestDataExport(
    RequestDataExport event,
    Emitter<ProfileState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;
    emit(ProfileSectionLoading(current));
    final result = await _profileRepository.requestDataExport();
    result.fold(
      (failure) => emit(ProfileError(
        message: failure.message,
        profile: current.profile,
        loadedState: current,
      )),
      (request) => emit(ProfileActionPending(
        message: request.message,
        requestId: request.requestId,
        actionType: 'export',
        requestedAt: request.requestedAt,
        loadedState: current,
      )),
    );
  }

  Future<void> _onRequestAccountDeletion(
    RequestAccountDeletion event,
    Emitter<ProfileState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;
    emit(ProfileSectionLoading(current));
    final result = await _profileRepository.requestAccountDeletion();
    result.fold(
      (failure) => emit(ProfileError(
        message: failure.message,
        profile: current.profile,
        loadedState: current,
      )),
      (request) => emit(ProfileActionPending(
        message: request.message,
        requestId: request.requestId,
        actionType: 'deletion',
        requestedAt: request.requestedAt,
        loadedState: current,
      )),
    );
  }

  Future<void> _onLoadVerificationDetails(
    LoadVerificationDetails event,
    Emitter<ProfileState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;
    final result = await _profileRepository.getVerificationDetails();
    result.fold(
      (failure) => emit(ProfileError(
        message: failure.message,
        profile: current.profile,
        loadedState: current,
      )),
      (verification) => emit(current.copyWith(verification: verification)),
    );
  }

  Future<void> _onSubmitVerificationDocuments(
    SubmitVerificationDocuments event,
    Emitter<ProfileState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;
    emit(ProfileSectionLoading(current));
    final result = await _profileRepository.submitVerificationDocuments(
      identityDocument: event.identityDocument,
      medicalDocument: event.medicalDocument,
      selfieWithCode: event.selfieWithCode,
      verificationCode: event.selfieCode,
    );
    await result.fold(
      (failure) async => emit(ProfileError(
        message: failure.message,
        profile: current.profile,
        loadedState: current,
      )),
      (_) async =>
          _reloadAfterAction(emit, 'profile.success_verification_submitted'),
    );
  }

  ProfileLoaded? get _currentLoaded {
    final current = state;
    if (current is ProfileLoaded) return current;
    if (current is ProfileActionSuccess) return current.loadedState;
    if (current is ProfileActionPending) return current.loadedState;
    if (current is ProfileError) return current.loadedState;
    if (current is ProfileSectionLoading) return current.previousState;
    return null;
  }

  Future<void> _reloadAfterAction(
    Emitter<ProfileState> emit,
    String message,
  ) async {
    final result = await _loadProfileSnapshot();
    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (loaded) => emit(ProfileActionSuccess(
        message: message,
        profile: loaded.profile,
        loadedState: loaded,
      )),
    );
  }

  ProfileLoaded get _emptyProfile {
    final now = DateTime.now();
    return ProfileLoaded(
      profile: Profile(
        id: '',
        userId: '',
        displayName: '',
        birthDate: now,
        bio: '',
        location: const Location(latitude: 0, longitude: 0, geohash: ''),
        city: '',
        country: '',
        interests: const [],
        relationshipType: '',
        relationshipTypesSought: const [],
        photos: const PhotoCollection(main: ''),
        searchPreferences: const SearchPreferences(
          minAge: 18,
          maxAge: 99,
          maxDistance: 50,
          interestedIn: [],
          relationshipTypes: [],
        ),
        lastActive: now,
        isHidden: false,
        verificationStatus: const VerificationStatus(
          status: 'not_started',
          documents: {},
        ),
        privacySettings: const PrivacySettings(),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<Either<Failure, ProfileLoaded>> _loadProfileSnapshot() async {
    final profileResult = await _getCurrentProfile(NoParams());
    return await profileResult.fold(
      (failure) async => Left<Failure, ProfileLoaded>(failure),
      (profile) async {
        var loaded = ProfileLoaded(profile: profile);

        final premium = await _profileRepository.getPremiumProfileStatus();
        premium.fold((_) {}, (value) {
          loaded = loaded.copyWith(premiumStatus: value);
        });

        final verification = await _profileRepository.getVerificationDetails();
        verification.fold((_) {}, (value) {
          loaded = loaded.copyWith(verification: value);
        });

        final privacy = await _profileRepository.getPrivacyPreferences();
        privacy.fold((_) {}, (value) {
          loaded = loaded.copyWith(privacyPreferences: value);
        });

        final notifications =
            await _profileRepository.getNotificationPreferences();
        notifications.fold((_) {}, (value) {
          loaded = loaded.copyWith(notificationPreferences: value);
        });

        final blockedUsers = await _profileRepository.getBlockedUsers();
        blockedUsers.fold((_) {}, (value) {
          loaded = loaded.copyWith(blockedUsers: value);
        });

        return Right<Failure, ProfileLoaded>(loaded);
      },
    );
  }
}
