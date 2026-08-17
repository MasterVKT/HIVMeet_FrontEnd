// lib/presentation/widgets/common/safe_circle_avatar.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';

/// A circular avatar that safely loads network images with error handling.
///
/// Unlike [CircleAvatar] with [NetworkImage] as [backgroundImage], this widget
/// gracefully handles network errors (404, timeout, etc.) by showing a fallback
/// icon instead of throwing [NetworkImageLoadException] on every rebuild —
/// which can flood the console with hundreds of exceptions in a chat page that
/// rebuilds frequently.
class SafeCircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final IconData fallbackIcon;
  final Color? fallbackIconColor;
  final Color? backgroundColor;
  final Widget? fallbackWidget;

  const SafeCircleAvatar({
    super.key,
    this.imageUrl,
    required this.radius,
    this.fallbackIcon = Icons.person,
    this.fallbackIconColor,
    this.backgroundColor,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    final hasValidUrl = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final diameter = radius * 2;

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppColors.slate.withValues(alpha: 0.2),
      ),
      child: ClipOval(
        child: hasValidUrl
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                width: diameter,
                height: diameter,
                placeholder: (context, url) => _buildFallback(),
                errorWidget: (context, url, error) => _buildFallback(),
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    if (fallbackWidget != null) {
      return fallbackWidget!;
    }
    return Icon(
      fallbackIcon,
      size: radius,
      color: fallbackIconColor ?? AppColors.slate,
    );
  }
}