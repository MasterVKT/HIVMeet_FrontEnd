// lib/presentation/widgets/cards/swipe_card.dart

import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_event.dart';

class SwipeCard extends StatefulWidget {
  final DiscoveryProfile profile;
  final Function(SwipeDirection)? onSwipe;
  final bool isPreview;

  const SwipeCard({
    Key? key,
    required this.profile,
    this.onSwipe,
    this.isPreview = false,
  }) : super(key: key);

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _dragOffset = Offset.zero;
  double _rotation = 0.0;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.isPreview) return;
    
    setState(() {
      _dragOffset += details.delta;
      _rotation = _dragOffset.dx / 300;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.isPreview) return;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final dragDistance = _dragOffset.dx.abs();
    
    if (dragDistance > screenWidth * 0.3) {
      final direction = _dragOffset.dx > 0 
          ? SwipeDirection.right 
          : SwipeDirection.left;
      
      _animateSwipe(direction);
    } else {
      _animateBack();
    }
  }

  void _animateSwipe(SwipeDirection direction) {
    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = direction == SwipeDirection.right ? screenWidth : -screenWidth;
    
    _controller.forward().then((_) {
      widget.onSwipe?.call(direction);
      _resetPosition();
    });
    
    setState(() {
      _dragOffset = Offset(targetX * 2, _dragOffset.dy);
      _rotation = direction == SwipeDirection.right ? 0.5 : -0.5;
    });
  }

  void _animateBack() {
    _controller.forward().then((_) {
      _controller.reset();
    });
    
    setState(() {
      _dragOffset = Offset.zero;
      _rotation = 0.0;
    });
  }

  void _resetPosition() {
    setState(() {
      _dragOffset = Offset.zero;
      _rotation = 0.0;
    });
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedContainer(
        duration: _controller.isAnimating 
            ? const Duration(milliseconds: 300) 
            : Duration.zero,
        transform: Matrix4.identity()
          ..translate(_dragOffset.dx, _dragOffset.dy)
          ..rotateZ(_rotation * 0.1),
        child: Container(
          margin: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Photo
                Image.network(
                  widget.profile.allPhotos[_currentPhotoIndex],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.platinum,
                      child: const Icon(
                        Icons.person,
                        size: 100,
                        color: AppColors.slate,
                      ),
                    );
                  },
                ),
                
                // Gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 200,
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
                  ),
                ),
                
                // Photo navigation
                if (widget.profile.allPhotos.length > 1 && !widget.isPreview) ...[
                  Positioned(
                    top: AppSpacing.md,
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    child: Row(
                      children: widget.profile.allPhotos.map((photo) {
                        final index = widget.profile.allPhotos.indexOf(photo);
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                            height: 4,
                            decoration: BoxDecoration(
                              color: index == _currentPhotoIndex
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  // Tap areas
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_currentPhotoIndex > 0) {
                              setState(() => _currentPhotoIndex--);
                            }
                          },
                          behavior: HitTestBehavior.translucent,
                          child: Container(height: 300),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_currentPhotoIndex < widget.profile.allPhotos.length - 1) {
                              setState(() => _currentPhotoIndex++);
                            }
                          },
                          behavior: HitTestBehavior.translucent,
                          child: Container(height: 300),
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Profile info
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${widget.profile.displayName}, ${widget.profile.age}',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (widget.profile.isVerified)
                              Container(
                                padding: EdgeInsets.all(AppSpacing.xs),
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
                        ),
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
                              '${widget.profile.city}${widget.profile.distance != null ? ' • ${widget.profile.distance!.round()} km' : ''}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        if (widget.profile.bio.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            widget.profile.bio,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Swipe indicators
                if (!widget.isPreview && _dragOffset.dx.abs() > 50) ...[
                  Positioned(
                    top: 100,
                    left: _dragOffset.dx > 0 ? 50 : null,
                    right: _dragOffset.dx < 0 ? 50 : null,
                    child: Transform.rotate(
                      angle: _dragOffset.dx > 0 ? -0.5 : 0.5,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: _dragOffset.dx > 0 ? AppColors.success : AppColors.error,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                        ),
                        child: Text(
                          _dragOffset.dx > 0 ? 'LIKE' : 'NOPE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}