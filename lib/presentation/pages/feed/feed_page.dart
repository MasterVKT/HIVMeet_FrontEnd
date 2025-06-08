// lib/presentation/pages/feed/feed_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/feed/feed_bloc.dart';
import 'package:hivmeet/presentation/blocs/feed/feed_event.dart';
import 'package:hivmeet/presentation/blocs/feed/feed_state.dart';
import 'package:hivmeet/presentation/widgets/cards/feed_post_card.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';
import 'package:go_router/go_router.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<FeedBloc>()..add(const LoadFeedPosts()),
      child: Scaffold(
        backgroundColor: AppColors.primaryWhite,
        appBar: AppBar(
          title: const Text('Fil d\'actualités'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => context.push('/feed/create'),
            ),
          ],
        ),
        body: BlocBuilder<FeedBloc, FeedState>(
          builder: (context, state) {
            if (state is FeedLoading) {
              return const Center(child: HIVLoader());
            }
            
            if (state is FeedError) {
              return Center(
                child: Text(state.message),
              );
            }
            
            if (state is FeedLoaded) {
              if (state.posts.isEmpty) {
                return _buildEmptyState(context);
              }
              
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<FeedBloc>().add(const LoadFeedPosts(refresh: true));
                },
                child: ListView.builder(
                  padding: EdgeInsets.all(AppSpacing.md),
                  itemCount: state.posts.length + (state.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.posts.length) {
                      if (!state.isLoadingMore) {
                        context.read<FeedBloc>().add(LoadMoreFeedPosts());
                      }
                      return const Center(child: HIVLoader());
                    }
                    
                    final post = state.posts[index];
                    return FeedPostCard(
                      post: post,
                      onLike: () {
                        context.read<FeedBloc>().add(TogglePostLike(postId: post.id));
                      },
                      onComment: () => context.push('/feed/post/${post.id}'),
                      onReport: () {
                        _showReportDialog(context, post.id);
                      },
                    );
                  },
                ),
              );
            }
            
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dynamic_feed_outlined,
              size: 80,
              color: AppColors.slate,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Aucune publication',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Soyez le premier à partager avec la communauté',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.slate,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () => context.push('/feed/create'),
              icon: const Icon(Icons.add),
              label: const Text('Créer une publication'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Signaler cette publication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Contenu inapproprié'),
              onTap: () {
                Navigator.of(dialogContext).pop();
                context.read<FeedBloc>().add(
                  ReportPost(postId: postId, reason: 'inappropriate'),
                );
              },
            ),
            ListTile(
              title: const Text('Spam'),
              onTap: () {
                Navigator.of(dialogContext).pop();
                context.read<FeedBloc>().add(
                  ReportPost(postId: postId, reason: 'spam'),
                );
              },
            ),
            ListTile(
              title: const Text('Désinformation'),
              onTap: () {
                Navigator.of(dialogContext).pop();
                context.read<FeedBloc>().add(
                  ReportPost(postId: postId, reason: 'misinformation'),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
}