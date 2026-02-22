// lib/presentation/pages/discovery/discovery_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/core/config/routes.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_bloc.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_event.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_state.dart';
import 'package:hivmeet/presentation/widgets/cards/swipe_card.dart';
import 'package:hivmeet/presentation/widgets/common/loading_widget.dart';
import 'package:hivmeet/presentation/widgets/common/error_widget.dart'
    as custom;
import 'package:hivmeet/presentation/widgets/common/empty_state_widget.dart';
import 'package:hivmeet/presentation/widgets/buttons/action_button.dart';
import 'package:hivmeet/presentation/widgets/modals/filters_modal.dart';
import 'package:hivmeet/presentation/widgets/modals/match_found_modal.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/widgets/navigation/app_scaffold.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  late DiscoveryBloc _discoveryBloc;
  final GlobalKey<State<SwipeCard>> _swipeCardKey =
      GlobalKey<State<SwipeCard>>();

  @override
  void initState() {
    super.initState();
    print('🔄 DEBUG DiscoveryPage: initState()');
    _discoveryBloc = getIt<DiscoveryBloc>();
    print('🔄 DEBUG DiscoveryPage: DiscoveryBloc récupéré (singleton)');

    // Charger les profils seulement si l'état est Initial
    // (première utilisation ou après une révocation)
    if (_discoveryBloc.state is DiscoveryInitial) {
      print('🔄 DEBUG DiscoveryPage: État Initial, chargement des profils');
      _discoveryBloc.add(const LoadDiscoveryProfiles(limit: 5));
    } else {
      print('✅ DEBUG DiscoveryPage: État déjà chargé, pas de rechargement');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 DEBUG DiscoveryPage: build() appelé');
    return BlocProvider<DiscoveryBloc>.value(
      value: _discoveryBloc,
      child: AppScaffold(
        currentIndex: 0, // Discovery tab
        appBar: AppBar(
          backgroundColor: AppColors.primaryWhite,
          elevation: 0,
          title: Text(
            'HIVMeet',
            style: GoogleFonts.pacifico(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: AppColors.primaryPurple,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune, color: AppColors.primaryPurple),
              onPressed: () => _showFiltersModal(),
            ),
          ],
        ),
        body: Container(
          color: AppColors.primaryWhite,
          child: BlocConsumer<DiscoveryBloc, DiscoveryState>(
            listener: _handleStateChanges,
            builder: (context, state) {
              print('🔄 DEBUG DiscoveryPage: State change: $state');

              if (state is DiscoveryLoading) {
                print('🔄 DEBUG DiscoveryPage: DiscoveryLoading state');
                return const Center(
                  child: LoadingWidget(
                    message: 'Chargement des profils...',
                  ),
                );
              }

              if (state is DiscoveryError) {
                print(
                    '❌ DEBUG DiscoveryPage: DiscoveryError state: ${state.message}');
                if (state.previousState != null) {
                  return _buildDiscoveryContentWithMessage(
                    state.previousState!,
                    state.message,
                  );
                }

                return custom.ErrorWidget(
                  message: state.message,
                  onRetry: () =>
                      _discoveryBloc.add(const LoadDiscoveryProfiles()),
                );
              }

              if (state is NoMoreProfiles) {
                print('ℹ️ DEBUG DiscoveryPage: NoMoreProfiles state');
                return _buildNoMoreProfilesState();
              }

              if (state is DiscoveryLoaded) {
                print('✅ DEBUG DiscoveryPage: DiscoveryLoaded state');
                return _buildDiscoveryContent(state);
              }

              if (state is DiscoveryLoadingMore) {
                print('🔄 DEBUG DiscoveryPage: DiscoveryLoadingMore state');
                return _buildDiscoveryContent(state.currentState);
              }

              if (state is DailyLimitReached) {
                print('⚠️ DEBUG DiscoveryPage: DailyLimitReached state');
                return _buildDailyLimitReachedState(state);
              }

              print('❓ DEBUG DiscoveryPage: État inconnu: $state');
              // État par défaut - afficher le loader
              return Container(
                color: AppColors.primaryWhite,
                child: const Center(
                  child: LoadingWidget(
                    message: 'Initialisation...',
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoveryContent(DiscoveryLoaded state) {
    return Stack(
      children: [
        // Zone de swipe principale
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Profil principal (non-positioned, centré)
              SwipeCard(
                key: _swipeCardKey,
                profile: state.currentProfile,
                onSwipe: _handleSwipe,
                onTap: _showProfileDetail,
              ),

              // Profils suivants en arrière-plan (max 2 pour éviter les problèmes de rendu)
              ...state.nextProfiles
                  .take(2)
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) {
                final index = entry.key;
                final profile = entry.value;
                return Positioned(
                  top: 50.0 + (index * 20.0),
                  left: 50.0 + (index * 12.0),
                  right: 50.0 - (index * 12.0),
                  child: IgnorePointer(
                    child: Transform.scale(
                      scale: 0.85 - (index * 0.1),
                      child: Opacity(
                        opacity: 0.3 - (index * 0.15), // Opacité plus visible
                        child: SwipeCard(
                          profile: profile,
                          isPreview: true,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        // Boutons d'action
        _buildActionButtons(state),

        // Indicateur de likes restants
        if (state.dailyLimit != null)
          _buildDailyLimitIndicator(state.dailyLimit!),

        // Indicateur de chargement progressif
        if (_discoveryBloc.state is DiscoveryLoadingMore)
          _buildLoadingMoreIndicator(),

        // Bouton de retour en arrière
        if (state.canRewind) _buildRewindButton(),
      ],
    );
  }

  Widget _buildDiscoveryContentWithMessage(
      DiscoveryLoaded state, String message) {
    return Stack(
      children: [
        _buildDiscoveryContent(state),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(DiscoveryLoaded state) {
    return Positioned(
      bottom: 80, // Position plus basse pour éviter le chevauchement
      left: 20, // Ajouter des marges latérales
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Bouton dislike
          ActionButton(
            icon: Icons.close,
            color: AppColors.error,
            onPressed: () {
              // Déclencher l'animation + le swipe
              final swipeCardState = _swipeCardKey.currentState;
              if (swipeCardState != null) {
                try {
                  (swipeCardState as dynamic).triggerSwipe(SwipeDirection.left);
                } catch (e) {
                  // Fallback si la méthode n'existe pas
                  _handleSwipe(SwipeDirection.left);
                }
              } else {
                _handleSwipe(SwipeDirection.left);
              }
            },
            size: 56, // Réduire légèrement la taille
          ),

          // Bouton super like (premium)
          ActionButton(
            icon: Icons.star,
            color: AppColors.warning,
            onPressed: () {
              // Déclencher l'animation + le swipe
              final swipeCardState = _swipeCardKey.currentState;
              if (swipeCardState != null) {
                try {
                  (swipeCardState as dynamic).triggerSwipe(SwipeDirection.up);
                } catch (e) {
                  // Fallback si la méthode n'existe pas
                  _handleSwipe(SwipeDirection.up);
                }
              } else {
                _handleSwipe(SwipeDirection.up);
              }
            },
            size: 56, // Uniformiser la taille
            isPremium: true,
          ),

          // Bouton like
          ActionButton(
            icon: Icons.favorite,
            color: AppColors.success,
            onPressed: () {
              // Déclencher l'animation + le swipe
              final swipeCardState = _swipeCardKey.currentState;
              if (swipeCardState != null) {
                try {
                  (swipeCardState as dynamic)
                      .triggerSwipe(SwipeDirection.right);
                } catch (e) {
                  // Fallback si la méthode n'existe pas
                  _handleSwipe(SwipeDirection.right);
                }
              } else {
                _handleSwipe(SwipeDirection.right);
              }
            },
            size: 56, // Réduire légèrement la taille
          ),
        ],
      ),
    );
  }

  Widget _buildDailyLimitIndicator(DailyLikeLimit limit) {
    return Positioned(
      top: 70, // Position optimisée
      left: 20,
      right: 120, // Laisser plus d'espace pour le bouton rewind
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              LocalizationService.translate(
                'discovery.likes_remaining',
                params: {'count': limit.remaining.toString()},
              ),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewindButton() {
    return Positioned(
      top: 70, // Aligner avec l'indicateur de likes
      right: 20,
      child: FloatingActionButton(
        mini: true,
        backgroundColor: AppColors.primaryPurple,
        onPressed: () => _discoveryBloc.add(RewindLastSwipe()),
        child: const Icon(
          Icons.undo,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Positioned(
      bottom: 200,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                LocalizationService.translate('discovery.loading_more'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoMoreProfilesState() {
    print('🔄 DEBUG _buildNoMoreProfilesState: Début de construction');
    try {
      final title =
          LocalizationService.translate('discovery.no_more_profiles_title');
      final message =
          LocalizationService.translate('discovery.no_more_profiles_message');
      final actionText =
          LocalizationService.translate('discovery.adjust_filters');

      print(
          '🔄 DEBUG _buildNoMoreProfilesState: title=$title, message=$message, actionText=$actionText');

      return Container(
        color: AppColors.primaryWhite,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              EmptyStateWidget(
                icon: Icons.people_outline,
                title: title,
                message: message,
                actionText: actionText,
                onAction: _showFiltersModal,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  print('🔄 DEBUG: Réinitialisation des filtres demandée');
                  _discoveryBloc.add(const LoadDiscoveryProfiles(limit: 5));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Rechargement des profils...'),
                      backgroundColor: AppColors.primaryPurple,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text(
                  'Recharger',
                  style: TextStyle(fontSize: 16),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryPurple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('❌ ERROR _buildNoMoreProfilesState: $e');
      print('Stack trace: $stackTrace');
      return Center(
        child: Text('Erreur: $e', style: const TextStyle(color: Colors.red)),
      );
    }
  }

  Widget _buildDailyLimitReachedState(DailyLimitReached state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: AppColors.warning,
          ),
          const SizedBox(height: 24),
          Text(
            LocalizationService.translate(
                'discovery.daily_limit_reached_title'),
            style: GoogleFonts.openSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            LocalizationService.translate(
              'discovery.daily_limit_reached_message',
              params: {
                'limit': state.limitInfo.limit.toString(),
                'resetTime': _formatResetTime(state.limitInfo.resetAt),
              },
            ),
            style: GoogleFonts.openSans(
              fontSize: 16,
              color: AppColors.slate,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.go('/subscription'),
            icon: const Icon(Icons.star),
            label: Text(
                LocalizationService.translate('discovery.upgrade_premium')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _handleStateChanges(BuildContext context, DiscoveryState state) {
    if (state is MatchFound) {
      _showMatchFoundModal(state);
    }

    if (state is DiscoveryError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleSwipe(SwipeDirection direction) {
    _discoveryBloc.add(SwipeProfile(direction: direction));
  }

  void _showProfileDetail() {
    final currentState = _discoveryBloc.state;
    if (currentState is DiscoveryLoaded) {
      context.push(AppRoutes.profileDetail, extra: currentState.currentProfile);
    }
  }

  void _showFiltersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FiltersModal(),
    );
  }

  void _showMatchFoundModal(MatchFound state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MatchFoundModal(
        matchedProfile: state.matchedProfile,
        matchId: state.matchId,
        onSendMessage: () {
          Navigator.of(context).pop();
          context.go('/conversations');
        },
        onContinue: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  String _formatResetTime(DateTime resetTime) {
    final now = DateTime.now();
    final difference = resetTime.difference(now);

    if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }
}
