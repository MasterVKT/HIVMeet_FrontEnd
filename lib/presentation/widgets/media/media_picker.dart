// lib/presentation/widgets/media/media_picker.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';

class MediaPicker extends StatelessWidget {
  final Function(File, MessageType) onMediaSelected;

  const MediaPicker({
    Key? key,
    required this.onMediaSelected,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required Function(File, MessageType) onMediaSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => MediaPicker(onMediaSelected: onMediaSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.silver,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOption(
                icon: Icons.photo_camera,
                label: 'Caméra',
                onTap: () => _pickImage(ImageSource.camera, context),
              ),
              _buildOption(
                icon: Icons.photo_library,
                label: 'Galerie',
                onTap: () => _pickImage(ImageSource.gallery, context),
              ),
              _buildOption(
                icon: Icons.videocam,
                label: 'Vidéo',
                onTap: () => _pickVideo(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
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
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(label),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    
    if (pickedFile != null) {
      Navigator.of(context).pop();
      onMediaSelected(File(pickedFile.path), MessageType.image);
    }
  }

  Future<void> _pickVideo(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      Navigator.of(context).pop();
      onMediaSelected(File(pickedFile.path), MessageType.video);
    }
  }
}