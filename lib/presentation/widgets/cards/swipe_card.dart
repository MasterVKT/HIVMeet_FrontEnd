// lib/presentation/widgets/cards/swipe_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/presentation/widgets/common/optimized_image.dart';

class SwipeCard extends StatefulWidget {
  final DiscoveryProfile profile;
  final Function(SwipeDirection)? onSwipe;
  final bool isPreview;
  final VoidCallback? onTap;

  const SwipeCard({
    super.key,
    required this.profile,
    this.onSwipe,
    this.isPreview = false,
    this.onTap,
  });

  @override
  State<SwipeCard> createState() => SwipeCardState();

  /// Méthode publique pour déclencher l'animation programmatiquement
  static SwipeCardState? of(BuildContext context) {
    return context.findAncestorStateOfType<SwipeCardState>();
  }
}

class SwipeCardState extends State<SwipeCard> with TickerProviderStateMixin {
  late AnimationController _swipeController;
  late AnimationController _pulseController;
  late AnimationController _superLikeAnimController;
  late Animation<double> _swipeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _superLikeFadeAnimation;
  late Animation<double> _superLikeGlowAnimation;
  late Animation<double> _superLikeScaleAnimation;

  Offset _dragOffset = Offset.zero;
  double _rotation = 0.0;
  int _currentPhotoIndex = 0;
  bool _isDragging = false;
  SwipeDirection? _swipeDirection;
  bool _isSuperLikeAnimating = false;

  @override
  void initState() {
    super.initState();

    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _superLikeAnimController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _swipeAnimation = CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOutCubic,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _superLikeFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _superLikeAnimController,
      curve: Curves.easeInOut,
    ));

    _superLikeGlowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _superLikeAnimController,
      curve: Curves.easeOut,
    ));

    // Scale animation: starts at 1.0, grows to 1.15 during fade out, then back to 1.0
    _superLikeScaleAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 1.15),
        weight: 50,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.15, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _superLikeAnimController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _pulseController.dispose();
    _superLikeAnimController.dispose();
    super.dispose();
  }

  /// Méthode publique pour animer le swipe programmatiquement (appelée par les boutons)
  void triggerSwipe(SwipeDirection direction) {
    if (widget.isPreview) return;

    setState(() {
      _swipeDirection = direction;
      // Simuler un drag dans la bonne direction
      switch (direction) {
        case SwipeDirection.right:
          _dragOffset = Offset(MediaQuery.of(context).size.width, 0);
          _rotation = 0.3;
          break;
        case SwipeDirection.left:
          _dragOffset = Offset(-MediaQuery.of(context).size.width, 0);
          _rotation = -0.3;
          break;
        case SwipeDirection.up:
          _dragOffset = Offset(0, -MediaQuery.of(context).size.height * 0.5);
          _isSuperLikeAnimating = true;
          break;
        default:
          break;
      }
    });

    if (direction == SwipeDirection.up) {
      // Animation spéciale pour super like
      _animateSuperLike();
    } else {
      // Animation normale pour like/dislike
      _animateSwipe(direction);
    }
  }

  // Helper pour afficher le nom du profil avec fallback
  String _getDisplayName() {
    if (widget.profile.displayName.isNotEmpty) {
      return widget.profile.displayName;
    }
    // Fallback : afficher "Profil" si pas de nom (backend problème temporaire)
    return 'Profil';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardHeight =
        size.height * 0.68; // Réduction de 75% à 68% pour plus d'espace
    final cardWidth = size.width * 0.9;

    // Pour les previews, retourner un widget simplifié sans animations
    if (widget.isPreview) {
      return Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Fond simple sans image
              Container(
                color: Colors.grey.shade300,
              ),
              // Info minimale
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.profile.displayName}, ${widget.profile.age}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Widget complet pour la carte principale
    return AnimatedBuilder(
      animation: _swipeAnimation,
      builder: (context, child) {
        final swipeProgress = _swipeAnimation.value;
        final currentOffset = Offset.lerp(
          _dragOffset,
          _getSwipeEndOffset(size),
          swipeProgress,
        )!;
        final currentRotation = _rotation * (1.0 - swipeProgress * 0.5);

        return Transform.translate(
          offset: currentOffset,
          child: Transform.rotate(
            angle: currentRotation,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.isPreview ? null : widget.onTap,
        onPanStart: widget.isPreview ? null : _onPanStart,
        onPanUpdate: widget.isPreview ? null : _onPanUpdate,
        onPanEnd: widget.isPreview ? null : _onPanEnd,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.isPreview ? 1.0 : _pulseAnimation.value,
              child: child,
            );
          },
          child: AnimatedBuilder(
            animation: _superLikeAnimController,
            builder: (context, child) {
              // Super-like effect simplified to avoid emulator OpenGL shader issues.
              if (_isSuperLikeAnimating) {
                return Opacity(
                  opacity: _superLikeFadeAnimation.value,
                  child: Transform.scale(
                    scale: _superLikeScaleAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(
                                alpha: _superLikeGlowAnimation.value * 0.45),
                            blurRadius: 24 * _superLikeGlowAnimation.value,
                            spreadRadius: 6 * _superLikeGlowAnimation.value,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  ),
                );
              }
              return child!;
            },
            child: Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Photo principale avec PageView
                    _buildPhotoSection(cardHeight),

                    // Indicateurs de photos
                    if (widget.profile.allPhotos.length > 1)
                      _buildPhotoIndicators(),

                    // Overlay de swipe
                    if (_isDragging && !widget.isPreview) _buildSwipeOverlay(),

                    // Informations du profil
                    _buildProfileInfo(),

                    // Badges (verified, premium, online)
                    _buildBadges(),
                  ],
                ),
              ),
            ), // Fermeture Container
          ), // Fermeture AnimatedBuilder super like
        ), // Fermeture AnimatedBuilder pulse
      ), // Fermeture GestureDetector
    ); // Fermeture AnimatedBuilder swipe
  }

  Widget _buildPhotoSection(double cardHeight) {
    // Si c'est un aperçu, ne pas afficher d'image du tout
    if (widget.isPreview) {
      return SizedBox(
        height: cardHeight * 0.6,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }

    return SizedBox(
      height: cardHeight *
          0.65, // Proportion optimisée pour équilibrer photo et infos
      child: PageView.builder(
        itemCount: widget.profile.allPhotos.length,
        onPageChanged: (index) {
          setState(() {
            _currentPhotoIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final photoUrl = widget.profile.allPhotos[index];

          // Si c'est le placeholder, afficher une image par défaut
          if (photoUrl == 'placeholder' || photoUrl.isEmpty) {
            return Container(
              color: AppColors.primaryPurple.withValues(alpha: 0.1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person,
                    size: 120,
                    color: AppColors.primaryPurple.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pas de photo',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.slate,
                    ),
                  ),
                ],
              ),
            );
          }

          return Hero(
            tag: '${widget.profile.id}_photo_$index',
            child: OptimizedImage(
              imageUrl: photoUrl,
              fit: BoxFit.cover,
              enableLazyLoading: false, // Désactiver temporairement pour debug
              fadeInDuration: const Duration(milliseconds: 200),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoIndicators() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        children: List.generate(
          widget.profile.allPhotos.length,
          (index) => Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index <= _currentPhotoIndex
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeOverlay() {
    Color overlayColor;
    IconData overlayIcon;
    String overlayText;

    switch (_swipeDirection) {
      case SwipeDirection.right:
        overlayColor = AppColors.success.withValues(alpha: 0.8);
        overlayIcon = Icons.favorite;
        overlayText = LocalizationService.translate('discovery.like');
        break;
      case SwipeDirection.left:
        overlayColor = AppColors.error.withValues(alpha: 0.8);
        overlayIcon = Icons.close;
        overlayText = LocalizationService.translate('discovery.dislike');
        break;
      case SwipeDirection.up:
        overlayColor = AppColors.info.withValues(alpha: 0.8);
        overlayIcon = Icons.star;
        overlayText = LocalizationService.translate('discovery.super_like');
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      color: overlayColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              overlayIcon,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              overlayText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    // Si c'est un aperçu, ne pas afficher d'informations
    if (widget.isPreview) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.85),
              ],
            ),
          ),
          padding:
              const EdgeInsets.fromLTRB(16, 20, 16, 24), // Padding optimisé
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getDisplayName()}, ${widget.profile.age}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Ville et pays
                        if (widget.profile.city.isNotEmpty ||
                            widget.profile.country.isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  widget.profile.country.isNotEmpty
                                      ? widget.profile.city.isNotEmpty
                                          ? '${widget.profile.city}, ${widget.profile.country}'
                                          : widget.profile.country
                                      : widget.profile.city,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (widget.profile.distance != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${widget.profile.distance!.round()} km',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (widget.onTap != null)
                        GestureDetector(
                          onTap: widget.onTap,
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (widget.profile.bio.isNotEmpty) ...[
                const SizedBox(height: 8), // Espacement légèrement augmenté
                Text(
                  widget.profile.bio,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14, // Augmenter la taille pour la lisibilité
                  ),
                  maxLines: 2, // Réduction à 2 lignes pour éviter trop de texte
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (widget.profile.interests.isNotEmpty) ...[
                const SizedBox(height: 8), // Espacement uniformisé
                Wrap(
                  spacing: 4,
                  runSpacing: 3,
                  children: widget.profile.interests.take(3).map((interest) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        interest,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              // Score de compatibilité
              if (widget.profile.compatibilityScore > 0) ...[
                const SizedBox(height: 8), // Espacement uniformisé
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 14,
                      color: AppColors.primaryPurple,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      LocalizationService.translate(
                        'discovery.compatibility',
                        params: {
                          'percent': widget.profile.compatibilityScore
                              .round()
                              .toString()
                        },
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadges() {
    // Si c'est un aperçu, ne pas afficher de badges
    if (widget.isPreview) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 20,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (widget.profile.isOnline)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    LocalizationService.translate('discovery.online_now'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          if (widget.profile.isVerified)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.info,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified,
                color: Colors.white,
                size: 16,
              ),
            ),
          const SizedBox(height: 4),
          if (widget.profile.isPremium)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.warning,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star,
                color: Colors.white,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
    HapticFeedback.lightImpact();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.isPreview) return;

    setState(() {
      _dragOffset += details.delta;
      _rotation = _dragOffset.dx / 300;
    });

    // Déterminer la direction du swipe
    final dragDistance = _dragOffset.dx.abs();
    final verticalDistance = _dragOffset.dy.abs();

    SwipeDirection? newDirection;

    if (verticalDistance > 50 && _dragOffset.dy < -50) {
      newDirection = SwipeDirection.up; // Super like
    } else if (dragDistance > 50) {
      newDirection =
          _dragOffset.dx > 0 ? SwipeDirection.right : SwipeDirection.left;
    }

    if (newDirection != _swipeDirection) {
      setState(() {
        _swipeDirection = newDirection;
      });
      if (newDirection != null) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.isPreview) return;

    setState(() {
      _isDragging = false;
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dragDistance = _dragOffset.dx.abs();
    final verticalDistance = _dragOffset.dy.abs();

    // Seuils pour déclencher le swipe
    final horizontalThreshold = screenWidth * 0.25;
    final verticalThreshold = screenHeight * 0.15;

    SwipeDirection? finalDirection;

    // Super like (swipe up)
    if (verticalDistance > verticalThreshold &&
        _dragOffset.dy < -verticalThreshold) {
      finalDirection = SwipeDirection.up;
    }
    // Like ou dislike (swipe horizontal)
    else if (dragDistance > horizontalThreshold) {
      finalDirection =
          _dragOffset.dx > 0 ? SwipeDirection.right : SwipeDirection.left;
    }

    if (finalDirection != null) {
      _animateSwipe(finalDirection);
    } else {
      _animateBack();
    }
  }

  void _animateSwipe(SwipeDirection direction) {
    HapticFeedback.mediumImpact();

    _swipeController.forward().then((_) {
      widget.onSwipe?.call(direction);
      _resetPosition();
    });
  }

  void _animateSuperLike() {
    HapticFeedback.mediumImpact();

    // Phase 1: Fade out avec glow doré (500ms)
    _superLikeAnimController.forward().then((_) {
      // Phase 2: Callback immédiat
      widget.onSwipe?.call(SwipeDirection.up);

      // Phase 3: Fade in (500ms)
      _superLikeAnimController.reverse().then((_) {
        _resetPosition();
      });
    });
  }

  void _animateBack() {
    _swipeController.forward().then((_) {
      _resetPosition();
    });
  }

  void _resetPosition() {
    setState(() {
      _dragOffset = Offset.zero;
      _rotation = 0.0;
      _swipeDirection = null;
      _isSuperLikeAnimating = false;
    });
    _swipeController.reset();
  }

  Offset _getSwipeEndOffset(Size screenSize) {
    switch (_swipeDirection) {
      case SwipeDirection.right:
        return Offset(screenSize.width, _dragOffset.dy);
      case SwipeDirection.left:
        return Offset(-screenSize.width, _dragOffset.dy);
      case SwipeDirection.up:
        return Offset(_dragOffset.dx, -screenSize.height);
      default:
        return Offset.zero;
    }
  }
}
