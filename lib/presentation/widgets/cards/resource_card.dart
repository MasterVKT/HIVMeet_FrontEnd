// lib/presentation/widgets/cards/resource_card.dart

import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/domain/entities/resource.dart';
import 'package:intl/intl.dart';

class ResourceCard extends StatelessWidget {
  final Resource resource;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const ResourceCard({
    Key? key,
    required this.resource,
    required this.onTap,
    required this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              if (resource.thumbnailUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    resource.thumbnailUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: AppColors.platinum,
                        child: Icon(
                          _getIconForType(resource.type),
                          size: 40,
                          color: AppColors.slate,
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIconForType(resource.type),
                    size: 40,
                    color: AppColors.primaryPurple,
                  ),
                ),
              
              const SizedBox(width: AppSpacing.md),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resource.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  Icon(
                                    _getIconForType(resource.type),
                                    size: 16,
                                    color: AppColors.slate,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    resource.categoryName,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.slate,
                                    ),
                                  ),
                                  if (resource.estimatedReadTimeMinutes != null) ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      '• ${resource.estimatedReadTimeMinutes} min',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.slate,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            resource.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_outline,
                            color: resource.isFavorite
                                ? AppColors.primaryPurple
                                : AppColors.slate,
                          ),
                          onPressed: onFavoriteToggle,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    
                    // Tags
                    if (resource.tags.isNotEmpty)
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: resource.tags.take(3).map((tag) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.platinum,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tag,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        }).toList(),
                      ),
                    
                    const SizedBox(height: AppSpacing.sm),
                    
                    // Bottom info
                    Row(
                      children: [
                        if (resource.isVerifiedExpert)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified,
                                  size: 14,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: AppSpacing.xxs),
                                Text(
                                  'Vérifié',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (resource.isPremium) ...[
                          if (resource.isVerifiedExpert)
                            const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: AppSpacing.xxs),
                                Text(
                                  'Premium',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          DateFormat('dd MMM yyyy').format(resource.publicationDate),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.slate,
                          ),
                        ),
                      ],
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

  IconData _getIconForType(ResourceType type) {
    switch (type) {
      case ResourceType.article:
        return Icons.article;
      case ResourceType.video:
        return Icons.play_circle_outline;
      case ResourceType.link:
        return Icons.link;
      case ResourceType.contact:
        return Icons.phone;
    }
  }
}