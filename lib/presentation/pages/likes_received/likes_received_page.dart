// lib/presentation/pages/likes_received/likes_received_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/matches/matches_bloc.dart';
import 'package:hivmeet/presentation/blocs/matches/matches_event.dart';
import 'package:hivmeet/presentation/blocs/matches/matches_state.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';
import 'package:go_router/go_router.dart';

class LikesReceivedPage extends StatelessWidget {
  const LikesReceivedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MatchesBloc>()..add(LoadLikesReceived()),
      child: Scaffold(
        backgroundColor: AppColors.primaryWhite,
        appBar: AppBar(
          title: const Text('Qui m\'a liké'),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: BlocBuilder<MatchesBloc, MatchesState>(
          builder: (context, state) {
            if (state is LikesReceivedLoading) {
              return const Center(child: HIVLoader());
            }
            
            if (state is LikesReceivedLoaded) {
              if (state.profiles.isEmpty) {
                return _buildEmptyState(context);
              }
              
              return GridView.builder(
                padding: EdgeInsets.all(AppSpacing.md),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                ),
                itemCount: state.profiles.length,
                itemBuilder: (context, index) {
                  final profile = state.profiles[index];
                  return GestureDetector(
                    onTap: () => context.push('/profile/${profile.id}', extra: profile),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              profile.mainPhotoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.platinum,
                                  child: const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: AppColors.slate,
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${profile.displayName}, ${profile.age}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (profile.distance != null)
                                      Text(
                                        '${profile.distance!.round()} km',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: AppSpacing.sm,
                              right: AppSpacing.sm,
                              child: Container(
                                padding: EdgeInsets.all(AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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
              Icons.favorite_outline,
              size: 80,
              color: AppColors.slate,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Pas encore de likes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Les profils qui vous likent apparaîtront ici',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.slate,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}