// lib/presentation/widgets/cards/feed_post_card.dart

import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/domain/entities/resource.dart';
import 'package:go_router/go_router.dart';

class FeedPostCard extends StatelessWidget {
  final FeedPost post;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final VoidCallback? onComment;
  final VoidCallback? onReport;

  const FeedPostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onShare,
    this.onComment,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppSpacing.md),
            _buildContent(context),
            if (post.imageUrl != null) ...[
              const SizedBox(height: AppSpacing.md),
              _buildImage(context),
            ],
            const SizedBox(height: AppSpacing.md),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: post.authorPhotoUrl.isNotEmpty
              ? NetworkImage(post.authorPhotoUrl)
              : null,
          child: post.authorPhotoUrl.isEmpty
              ? Text(
                  post.authorName.substring(0, 1).toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    post.authorName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  // TODO: Add expert verification badge if needed
                ],
              ),
              Text(
                _formatDate(post.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.slate,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showPostOptions(context),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Text(
      post.content,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildImage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        post.imageUrl!,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 200,
            color: AppColors.silver,
            child: const Icon(
              Icons.broken_image,
              color: AppColors.slate,
            ),
          );
        },
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        _buildActionButton(
          icon: post.isLikedByCurrentUser
              ? Icons.favorite
              : Icons.favorite_border,
          label: post.likeCount.toString(),
          color: post.isLikedByCurrentUser ? AppColors.error : AppColors.slate,
          onTap: onLike,
        ),
        const SizedBox(width: AppSpacing.lg),
        _buildActionButton(
          icon: Icons.chat_bubble_outline,
          label: post.commentCount.toString(),
          color: AppColors.slate,
          onTap: onComment ?? () => context.push('/feed/post/${post.id}'),
        ),
        const SizedBox(width: AppSpacing.lg),
        _buildActionButton(
          icon: Icons.share_outlined,
          label: 'Partager',
          color: AppColors.slate,
          onTap: onShare,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Signaler'),
              onTap: () {
                Navigator.pop(context);
                onReport?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Bloquer l\'utilisateur'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement block functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
