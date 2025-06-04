// lib/presentation/widgets/cards/hiv_card.dart

import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';

class HIVCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Border? border;

  const HIVCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.onTap,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultRadius = borderRadius ?? BorderRadius.circular(16);
    
    return Container(
      margin: margin,
      child: Material(
        color: backgroundColor ?? theme.cardColor,
        elevation: elevation ?? 2,
        borderRadius: defaultRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: defaultRadius,
          child: Container(
            padding: padding ?? EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: defaultRadius,
              border: border,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Profile Card for discovery swipe
class ProfileCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final int age;
  final String? city;
  final bool isVerified;
  final bool isPremium;
  final VoidCallback? onTap;
  final double? height;
  final double? width;

  const ProfileCard({
    Key? key,
    required this.imageUrl,
    required this.name,
    required this.age,
    this.city,
    this.isVerified = false,
    this.isPremium = false,
    this.onTap,
    this.height,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return HIVCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: height ?? 600,
        width: width ?? double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Profile Image
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: theme.colorScheme.surface,
                    child: const Icon(
                      Icons.person,
                      size: 80,
                      color: AppColors.slate,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: theme.colorScheme.surface,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            
            // User info
            Positioned(
              bottom: AppSpacing.lg,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '$name, $age',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryPurple,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                            if (isPremium) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.turquoise,
                                      AppColors.success,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (city != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                city!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Match Card for matches list
class MatchCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool isOnline;
  final bool hasUnreadMessage;
  final VoidCallback? onTap;

  const MatchCard({
    Key? key,
    required this.imageUrl,
    required this.name,
    this.lastMessage,
    this.lastMessageTime,
    this.isOnline = false,
    this.hasUnreadMessage = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return HIVCard(
      onTap: onTap,
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          // Profile image with online indicator
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(imageUrl),
                backgroundColor: theme.colorScheme.surface,
              ),
              if (isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.cardColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          
          // Message info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: hasUnreadMessage
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (lastMessage != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    lastMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: hasUnreadMessage
                          ? theme.colorScheme.onSurface
                          : AppColors.greyMedium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          // Time and unread indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (lastMessageTime != null)
                Text(
                  _formatTime(lastMessageTime!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.greyMedium,
                  ),
                ),
              if (hasUnreadMessage) ...[
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: EdgeInsets.all(AppSpacing.xs),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 8,
                    minHeight: 8,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Maintenant';
    }
  }
}