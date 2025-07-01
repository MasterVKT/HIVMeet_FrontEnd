// lib/presentation/widgets/cards/swipe_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/match.dart';

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
    return SizedBox(
      height: cardHeight * 0.7,
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
            child: Image.network(
              widget.profile.allPhotos[index],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: AppColors.slate.withOpacity(0.1),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.slate.withOpacity(0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person,
                        size: 80,
                        color: AppColors.slate,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        LocalizationService.translate('common.image_error'),
                        style: TextStyle(color: AppColors.slate),
                      ),
                    ],
                  ),
                );
              },
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
        padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 8),
              Text(
                widget.profile.bio,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (widget.profile.interests.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    size: 16,
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
                      fontSize: 12,
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
    return Positioned(
      top: 16,
      right: 16,
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
      bottom: 120,
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
    final screenWidth = MediaQuery.of(context).size.width;
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
      builder: (context) {
        return AlertDialog(
          title:
              Text(LocalizationService.translate('discovery.common_interests')),
          content: Wrap(
            spacing: 8,
            children: widget.profile.interests.map((interest) {
              return Chip(
                label: Text(interest),
                backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(LocalizationService.translate('common.close')),
            ),
          ],
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
