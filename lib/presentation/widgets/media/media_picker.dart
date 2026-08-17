import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/message.dart';

class MediaPicker extends StatelessWidget {
  final void Function(File, MessageType) onMediaSelected;

  const MediaPicker({
    super.key,
    required this.onMediaSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required void Function(File, MessageType) onMediaSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => MediaPicker(onMediaSelected: onMediaSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            LocalizationService.translate('chat.attach_media'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.charcoal,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildOption(
                  icon: Icons.photo_camera_outlined,
                  label: LocalizationService.translate('chat.camera'),
                  onTap: () => _pickImage(ImageSource.camera, context),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildOption(
                  icon: Icons.photo_library_outlined,
                  label: LocalizationService.translate('chat.gallery'),
                  onTap: () => _pickImage(ImageSource.gallery, context),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildOption(
                  icon: Icons.videocam_outlined,
                  label: LocalizationService.translate('chat.video'),
                  onTap: () => _pickVideo(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, BuildContext context) async {
    final pickedFile = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickedFile == null || !context.mounted) return;

    Navigator.of(context).pop();
    onMediaSelected(File(pickedFile.path), MessageType.image);
  }

  Future<void> _pickVideo(BuildContext context) async {
    final pickedFile = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
    );

    if (pickedFile == null || !context.mounted) return;

    Navigator.of(context).pop();
    onMediaSelected(File(pickedFile.path), MessageType.video);
  }
}
