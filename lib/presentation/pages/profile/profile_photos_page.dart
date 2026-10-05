import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_bloc.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_event.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_state.dart';
import 'package:hivmeet/presentation/widgets/common/hiv_toast.dart';
import 'package:hivmeet/presentation/widgets/common/optimized_image.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePhotosPage extends StatelessWidget {
  const ProfilePhotosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(LoadProfile()),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            HIVToast.showError(context: context, message: _tr(state.message));
          }
          if (state is ProfileActionSuccess) {
            HIVToast.showSuccess(context: context, message: _tr(state.message));
          }
        },
        builder: (context, state) {
          final loaded = _loadedFrom(state);
          return Scaffold(
            backgroundColor: AppColors.primaryWhite,
            appBar: AppBar(
              title: Text(_tr('profile.photos')),
              backgroundColor: AppColors.primaryWhite,
            ),
            floatingActionButton: loaded == null ||
                    loaded.profile.photoCount >= _photoLimit(loaded)
                ? null
                : FloatingActionButton.extended(
                    onPressed: () => _pickAndUpload(context, loaded),
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(_tr('profile.add_photo')),
                  ),
            body: loaded == null
                ? state is ProfileError
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_tr('profile.photos_load_error')),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => context
                                  .read<ProfileBloc>()
                                  .add(LoadProfile()),
                              child: Text(_tr('common.retry')),
                            ),
                          ],
                        ),
                      )
                    : const Center(child: HIVLoader())
                : _PhotoList(
                    loaded: loaded,
                    canReorder: loaded.premiumStatus?.isPremium == true,
                    canReplace:
                        loaded.profile.photoCount >= _photoLimit(loaded),
                  ),
          );
        },
      ),
    );
  }

  Future<void> _pickAndUpload(
      BuildContext context, ProfileLoaded loaded) async {
    final limit = _photoLimit(loaded);
    if (loaded.profile.photoCount >= limit) {
      HIVToast.showWarning(
        context: context,
        message: _tr('profile.photo_limit_reached'),
      );
      return;
    }
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!context.mounted) return;
    final file = File(picked.path);
    final lowerPath = picked.path.toLowerCase();
    final validType = lowerPath.endsWith('.jpg') ||
        lowerPath.endsWith('.jpeg') ||
        lowerPath.endsWith('.png');
    if (!validType) {
      HIVToast.showError(
          context: context, message: _tr('profile.photo_type_error'));
      return;
    }
    final fileLength = await file.length();
    if (!context.mounted) return;
    if (fileLength > 5 * 1024 * 1024) {
      HIVToast.showError(
          context: context, message: _tr('profile.photo_size_error'));
      return;
    }
    context.read<ProfileBloc>().add(UploadPhoto(
          photo: file,
          isMain: loaded.profile.photoCount == 0,
        ));
  }
}

class _PhotoList extends StatelessWidget {
  final ProfileLoaded loaded;
  final bool canReorder;
  final bool canReplace;

  const _PhotoList({
    required this.loaded,
    required this.canReorder,
    required this.canReplace,
  });

  @override
  Widget build(BuildContext context) {
    final photos = loaded.profile.photoItems;
    if (photos.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Text(
            _tr('profile.no_photos'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final ordered = [...photos]..sort((a, b) => a.order.compareTo(b.order));
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: ordered.length,
      buildDefaultDragHandles: canReorder,
      onReorderItem: canReorder
          ? (oldIndex, newIndex) {
              final next = [...ordered];
              final moved = next.removeAt(oldIndex);
              next.insert(newIndex, moved);
              context.read<ProfileBloc>().add(
                    ReorderPhotos(
                        photoIds: next.map((photo) => photo.id).toList()),
                  );
            }
          : (_, __) {},
      itemBuilder: (context, index) => _PhotoTile(
        key: ValueKey(ordered[index].id),
        photo: ordered[index],
        canReorder: canReorder,
        canReplace: canReplace,
        canDelete: ordered.length > 1,
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final ProfilePhoto photo;
  final bool canReorder;
  final bool canReplace;
  final bool canDelete;

  const _PhotoTile({
    super.key,
    required this.photo,
    required this.canReorder,
    required this.canReplace,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 180,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              OptimizedImage(imageUrl: photo.photoUrl, fit: BoxFit.cover),
              Positioned(
                left: 8,
                top: 8,
                child: Chip(
                  label: Text(photo.isMain
                      ? _tr('profile.main_photo')
                      : '${photo.order + 1}'),
                  backgroundColor: Colors.white,
                ),
              ),
              Positioned(
                right: 4,
                bottom: 4,
                child: Row(
                  children: [
                    if (canReorder)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.drag_handle),
                      ),
                    if (!photo.isMain)
                      IconButton.filledTonal(
                        tooltip: _tr('profile.set_main_photo'),
                        onPressed: () => context.read<ProfileBloc>().add(
                              SetMainPhoto(
                                  photoUrl: photo.photoUrl, photoId: photo.id),
                            ),
                        icon: const Icon(Icons.star_outline),
                      ),
                    if (canReplace) ...[
                      const SizedBox(width: 4),
                      IconButton.filledTonal(
                        tooltip: _tr('profile.replace_photo'),
                        onPressed: () => _pickAndReplace(context),
                        icon: const Icon(Icons.photo_camera_back_outlined),
                      ),
                    ],
                    const SizedBox(width: 4),
                    if (canDelete)
                      IconButton.filledTonal(
                        tooltip: _tr('common.delete'),
                        onPressed: () => _confirmDelete(context),
                        icon: const Icon(Icons.delete_outline),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndReplace(BuildContext context) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !context.mounted) return;
    final file = File(picked.path);
    final lowerPath = picked.path.toLowerCase();
    final validType = lowerPath.endsWith('.jpg') ||
        lowerPath.endsWith('.jpeg') ||
        lowerPath.endsWith('.png');
    if (!validType) {
      HIVToast.showError(context: context, message: _tr('profile.photo_type_error'));
      return;
    }
    if (await file.length() > 5 * 1024 * 1024) {
      if (context.mounted) {
        HIVToast.showError(context: context, message: _tr('profile.photo_size_error'));
      }
      return;
    }
    if (context.mounted) {
      context.read<ProfileBloc>().add(ReplacePhoto(photoId: photo.id, photo: file));
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_tr('profile.delete_photo')),
        content: Text(_tr('profile.delete_photo_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ProfileBloc>().add(
                    DeletePhoto(photoUrl: photo.photoUrl, photoId: photo.id),
                  );
            },
            child: Text(_tr('common.delete')),
          ),
        ],
      ),
    );
  }
}

int _photoLimit(ProfileLoaded loaded) {
  return loaded.premiumStatus?.isPremium == true
      ? AppLimits.maxPhotosPremium
      : AppLimits.maxPhotosGratuit;
}

ProfileLoaded? _loadedFrom(ProfileState state) {
  if (state is ProfileLoaded) return state;
  if (state is ProfileActionSuccess) return state.loadedState;
  if (state is ProfileError) return state.loadedState;
  if (state is ProfileSectionLoading) return state.previousState;
  return null;
}

String _tr(String key) => LocalizationService.translate(key);
