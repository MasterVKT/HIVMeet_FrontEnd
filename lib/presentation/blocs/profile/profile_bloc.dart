// lib/presentation/blocs/profile/profile_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';
import 'package:hivmeet/domain/usecases/profile/get_current_profile.dart';
import 'package:hivmeet/domain/usecases/profile/update_profile.dart';
import 'package:hivmeet/domain/usecases/profile/upload_photo.dart' as upload;
import 'package:hivmeet/domain/usecases/profile/delete_photo.dart' as delete;
import 'package:hivmeet/domain/usecases/profile/set_main_photo.dart' as set_main;
import 'package:hivmeet/domain/usecases/profile/reorder_photos.dart' as reorder;
import 'package:hivmeet/domain/usecases/profile/update_location.dart' as update_loc;
import 'package:hivmeet/domain/usecases/profile/block_user.dart' as block;
import 'package:hivmeet/domain/usecases/profile/unblock_user.dart' as unblock;
import 'package:hivmeet/domain/usecases/profile/toggle_profile_visibility.dart' as toggle;
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

  StreamSubscription<Profile?>? _profileSubscription;

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
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UploadPhoto>(_onUploadPhoto);
    on<DeletePhoto>(_onDeletePhoto);
    on<SetMainPhoto>(_onSetMainPhoto);
    on<ReorderPhotos>(_onReorderPhotos);
    on<ToggleProfileVisibility>(_onToggleProfileVisibility);
    on<UpdateLocation>(_onUpdateLocation);
    on<BlockUser>(_onBlockUser);
    on<UnblockUser>(_onUnblockUser);

    // Écouter les changements de profil
    _profileSubscription =
        _profileRepository.watchCurrentUserProfile().listen((profile) {
      if (profile != null && state is ProfileLoaded) {
        add(LoadProfile());
      }
    });
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    final result = await _getCurrentProfile(NoParams());

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (profile) => emit(ProfileLoaded(profile: profile)),
    );
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(ProfileUpdating(profile: currentState.profile));

      final result = await _updateProfile(
        UpdateProfileParams(
          displayName: event.displayName,
          bio: event.bio,
          city: event.city,
          country: event.country,
          latitude: event.latitude,
          longitude: event.longitude,
          interests: event.interests,
          relationshipType: event.relationshipType,
          searchPreferences: event.searchPreferences,
          privacySettings: event.privacySettings,
        ),
      );

      result.fold(
        (failure) => emit(ProfileError(
          message: failure.message,
          profile: currentState.profile,
        )),
        (profile) => emit(ProfileActionSuccess(
          message: 'Profil mis à jour avec succès',
          profile: profile,
        )),
      );

      // Retour à l'état loaded après succès
      await Future.delayed(const Duration(seconds: 2));
      if (state is ProfileActionSuccess) {
        emit(ProfileLoaded(profile: (state as ProfileActionSuccess).profile));
      }
    }
  }

  Future<void> _onUploadPhoto(
    UploadPhoto event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(PhotoUploading(
        profile: currentState.profile,
        progress: 0.0,
      ));

      final params = upload.UploadPhotoParams(
        photo: event.photo,
        isMain: event.isMain,
        isPrivate: event.isPrivate,
      );

      final result = await _uploadPhoto(params);

      result.fold(
        (failure) => emit(ProfileError(
          message: failure.message,
          profile: currentState.profile,
        )),
        (photoUrl) async {
          emit(ProfileActionSuccess(
            message: 'Photo téléchargée avec succès',
            profile: currentState.profile,
          ));

          // Recharger le profil pour obtenir la mise à jour
          add(LoadProfile());
        },
      );
    }
  }

  Future<void> _onDeletePhoto(
    DeletePhoto event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      final params = delete.DeletePhotoParams(photoUrl: event.photoUrl);
      final result = await _deletePhoto(params);

      result.fold(
        (failure) => emit(ProfileError(
          message: failure.message,
          profile: currentState.profile,
        )),
        (_) {
          emit(ProfileActionSuccess(
            message: 'Photo supprimée avec succès',
            profile: currentState.profile,
          ));
          add(LoadProfile());
        },
      );
    }
  }

  Future<void> _onSetMainPhoto(
    SetMainPhoto event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      final params = set_main.SetMainPhotoParams(photoUrl: event.photoUrl);
      final result = await _setMainPhoto(params);

      result.fold(
        (failure) => emit(ProfileError(
          message: failure.message,
          profile: currentState.profile,
        )),
        (_) {
          emit(ProfileActionSuccess(
            message: 'Photo principale définie',
            profile: currentState.profile,
          ));
          add(LoadProfile());
        },
      );
    }
  }

  Future<void> _onReorderPhotos(
    ReorderPhotos event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      final params = reorder.ReorderPhotosParams(photoUrls: event.photoUrls);
      final result = await _reorderPhotos(params);

      result.fold(
        (failure) => emit(ProfileError(
          message: failure.message,
          profile: currentState.profile,
        )),
        (_) {
          emit(ProfileActionSuccess(
            message: 'Photos réorganisées',
            profile: currentState.profile,
          ));
          add(LoadProfile());
        },
      );
    }
  }

  Future<void> _onToggleProfileVisibility(
    ToggleProfileVisibility event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      final params = toggle.ToggleProfileVisibilityParams(
        isHidden: event.isHidden,
      );
      final result = await _toggleProfileVisibility(params);

      result.fold(
        (failure) => emit(ProfileError(
          message: failure.message,
          profile: currentState.profile,
        )),
        (_) {
          final message = event.isHidden
              ? 'Profil masqué de la découverte'
              : 'Profil visible dans la découverte';
          emit(ProfileActionSuccess(
            message: message,
            profile: currentState.profile,
          ));
          add(LoadProfile());
        },
      );
    }
  }

  Future<void> _onUpdateLocation(
    UpdateLocation event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      final params = update_loc.UpdateLocationParams(
        latitude: event.latitude,
        longitude: event.longitude,
        city: event.city,
        country: event.country,
      );
      final result = await _updateLocation(params);

      result.fold(
        (failure) => emit(ProfileError(
          message: failure.message,
          profile: currentState.profile,
        )),
        (_) {
          emit(ProfileActionSuccess(
            message: 'Localisation mise à jour',
            profile: currentState.profile,
          ));
          add(LoadProfile());
        },
      );
    }
  }

  Future<void> _onBlockUser(
    BlockUser event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      final params = block.BlockUserParams(userId: event.userId);
      final result = await _blockUser(params);

      result.fold(
        (failure) => emit(ProfileError(
          message: failure.message,
          profile: currentState.profile,
        )),
        (_) {
          emit(ProfileActionSuccess(
            message: 'Utilisateur bloqué',
            profile: currentState.profile,
          ));
        },
      );
    }
  }

  Future<void> _onUnblockUser(
    UnblockUser event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      final params = unblock.UnblockUserParams(userId: event.userId);
      final result = await _unblockUser(params);

      result.fold(
        (failure) => emit(ProfileError(
          message: failure.message,
          profile: currentState.profile,
        )),
        (_) {
          emit(ProfileActionSuccess(
            message: 'Utilisateur débloqué',
            profile: currentState.profile,
          ));
        },
      );
    }
  }

  @override
  Future<void> close() {
    _profileSubscription?.cancel();
    return super.close();
  }
}
