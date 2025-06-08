// lib/presentation/pages/matches/matches_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/matches/matches_bloc.dart';
import 'package:hivmeet/presentation/blocs/matches/matches_event.dart';
import 'package:hivmeet/presentation/blocs/matches/matches_state.dart';
import 'package:hivmeet/presentation/widgets/cards/hiv_card.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';
import 'package:go_router/go_router.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({Key? key}) : super(key: key);

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MatchesBloc>()..add(const LoadMatches()),
      child: Scaffold(
        backgroundColor: AppColors.primaryWhite,
        appBar: AppBar(
          title: const Text('Matches'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryPurple,
            labelColor: AppColors.primaryPurple,
            unselectedLabelColor: AppColors.slate,
            tabs: [
              const Tab(text: 'Matches'),
              Tab(
                child: BlocBuilder<MatchesBloc, MatchesState>(
                  builder: (context, state) {
                    final count = state is MatchesLoaded ? state.likesReceivedCount : 0;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Likes'),
                        if (count > 0) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              count > 99 ? '99+' : count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMatchesTab(),
            _buildLikesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesTab() {
    return BlocConsumer<MatchesBloc, MatchesState>(
      listener: (context, state) {
        if (state is MatchesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is MatchesLoading) {
          return const Center(child: HIVLoader());
        }
        
        if (state is MatchesLoaded) {
          if (state.matches.isEmpty) {
            return _buildEmptyState();
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              context.read<MatchesBloc>().add(const LoadMatches(refresh: true));
            },
            child: ListView.builder(
              itemCount: state.matches.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.matches.length) {
                  if (!state.isLoadingMore) {
                    context.read<MatchesBloc>().add(LoadMoreMatches());
                  }
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Center(child: HIVLoader()),
                  );
                }
                
                final match = state.matches[index];
                return MatchCard(
                  imageUrl: '', // TODO: Ajouter URL depuis profile
                  name: 'Match ${index + 1}', // TODO: Nom réel
                  lastMessage: match.lastMessageContent,
                  lastMessageTime: match.lastMessageAt,
                  hasUnreadMessage: match.hasUnreadMessages,
                  onTap: () {
                    context.read<MatchesBloc>().add(MarkMatchAsSeen(matchId: match.id));
                    context.push('/chat/${match.id}');
                  },
                );
              },
            ),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLikesTab() {
    return BlocBuilder<MatchesBloc, MatchesState>(
      builder: (context, state) {
        // TODO: Implémenter la logique premium
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Voir qui vous a liké',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Passez à Premium pour voir les profils\nqui s\'intéressent à vous !',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.slate,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: () => context.push('/premium'),
                child: const Text('Découvrir Premium'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: AppColors.slate,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Pas encore de match',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Commencez à swiper pour rencontrer\ndes personnes qui vous correspondent',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.slate,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () => context.go('/discovery'),
              child: const Text('Découvrir des profils'),
            ),
          ],
        ),
      ),
    );
  }
}