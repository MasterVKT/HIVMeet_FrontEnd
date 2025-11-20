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
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with TickerProviderStateMixin {
  late AnimationController _swipeController;
  late AnimationController _pulseController;
  late Animation<double> _swipeAnimation;
  late Animation<double> _pulseAnimation;

  Offset _dragOffset = Offset.zero;
  double _rotation = 0.0;
  int _currentPhotoIndex = 0;
  bool _isDragging = false;
  SwipeDirection? _swipeDirection;

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

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardHeight = size.height * 0.75;
    final cardWidth = size.width * 0.9;

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
          child: Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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

                  // Actions rapides
                  if (!widget.isPreview) _buildQuickActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection(double cardHeight) {
    // Si c'est un aperçu, ne pas afficher d'image du tout
    if (widget.isPreview) {
      return SizedBox(
        height: cardHeight * 0.6,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }

    return SizedBox(
      height: cardHeight * 0.6, // Réduire davantage pour plus d'espace info
      child: PageView.builder(
        itemCount: widget.profile.allPhotos.length,
        onPageChanged: (index) {
          setState(() {
            _currentPhotoIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return Hero(
            tag: '${widget.profile.id}_photo_$index',
            child: OptimizedImage(
              imageUrl: widget.profile.allPhotos[index],
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
                    : Colors.white.withOpacity(0.3),
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
        overlayColor = AppColors.success.withOpacity(0.8);
        overlayIcon = Icons.favorite;
        overlayText = LocalizationService.translate('discovery.like');
        break;
      case SwipeDirection.left:
        overlayColor = AppColors.error.withOpacity(0.8);
        overlayIcon = Icons.close;
        overlayText = LocalizationService.translate('discovery.dislike');
        break;
      case SwipeDirection.up:
        overlayColor = AppColors.info.withOpacity(0.8);
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
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16,
            120), // Augmenter le padding bottom pour éviter les boutons
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.profile.displayName}, ${widget.profile.age}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.profile.distance != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
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
              ],
            ),
            if (widget.profile.bio.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                widget.profile.bio,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14, // Augmenter la taille pour la lisibilité
                ),
                maxLines: 3, // Augmenter à 3 lignes pour plus de contenu
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (widget.profile.interests.isNotEmpty) ...[
              const SizedBox(height: 6),
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
                      color: AppColors.primaryPurple.withOpacity(0.8),
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
              const SizedBox(height: 6),
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
                        'percent':
                            widget.profile.compatibilityScore.round().toString()
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

  Widget _buildQuickActions() {
    return Positioned(
      bottom: 200, // Déplacer plus haut pour éviter les boutons d'action
      right: 16,
      child: Column(
        children: [
          _QuickActionButton(
            icon: Icons.info_outline,
            onTap: widget.onTap,
            tooltip: LocalizationService.translate('common.view_profile'),
          ),
          const SizedBox(height: 8),
          if (widget.profile.interests.isNotEmpty)
            _QuickActionButton(
              icon: Icons.favorite_border,
              onTap: () => _showInterestsDialog(),
              tooltip:
                  LocalizationService.translate('discovery.common_interests'),
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

  void _showInterestsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header avec gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryPurple,
                        AppColors.primaryPurple.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        LocalizationService.translate(
                            'discovery.common_interests'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        LocalizationService.translate(
                            'discovery.interests_subtitle'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Contenu avec intérêts
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: widget.profile.interests.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.slate,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  LocalizationService.translate(
                                      'discovery.no_interests'),
                                  style: TextStyle(
                                    color: AppColors.slate,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children:
                                  widget.profile.interests.map((interest) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryPurple
                                            .withOpacity(0.1),
                                        AppColors.primaryPurple
                                            .withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.primaryPurple
                                          .withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.favorite,
                                        color: AppColors.primaryPurple,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        interest,
                                        style: TextStyle(
                                          color: AppColors.primaryPurple,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ),

                // Bouton de fermeture
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        LocalizationService.translate('common.close'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  const _QuickActionButton({
    required this.icon,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: AppColors.primaryPurple,
            size: 20,
          ),
        ),
      ),
    );
  }
}
