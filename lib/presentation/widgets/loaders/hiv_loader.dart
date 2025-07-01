// lib/presentation/widgets/loaders/hiv_loader.dart

import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';

class HIVLoader extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const HIVLoader({
    super.key,
    this.size = 40,
    this.color,
    this.strokeWidth = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primaryPurple,
        ),
        strokeWidth: strokeWidth,
      ),
    );
  }
}

// Full screen loader with optional message
class HIVFullScreenLoader extends StatelessWidget {
  final String? message;
  final bool showBackground;

  const HIVFullScreenLoader({
    super.key,
    this.message,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      color: showBackground
          ? Colors.black.withOpacity(0.5)
          : Colors.transparent,
      child: Center(
        child: Card(
          elevation: showBackground ? 8 : 0,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HIVLoader(),
                if (message != null) ...[
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    message!,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
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

// Shimmer loading effect for skeleton screens
class HIVShimmer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const HIVShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<HIVShimmer> createState() => _HIVShimmerState();
}

class _HIVShimmerState extends State<HIVShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isDarkMode
                  ? [
                      Colors.grey[800]!,
                      Colors.grey[700]!,
                      Colors.grey[600]!,
                      Colors.grey[700]!,
                      Colors.grey[800]!,
                    ]
                  : [
                      Colors.grey[300]!,
                      Colors.grey[200]!,
                      Colors.grey[100]!,
                      Colors.grey[200]!,
                      Colors.grey[300]!,
                    ],
              stops: [
                0.0,
                0.35 + _animation.value * 0.15,
                0.5 + _animation.value * 0.15,
                0.65 + _animation.value * 0.15,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

// Profile card skeleton loader
class ProfileCardSkeleton extends StatelessWidget {
  const ProfileCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 600,
      child: Stack(
        children: [
          // Main card shimmer
          HIVShimmer(
            width: double.infinity,
            height: 600,
            borderRadius: BorderRadius.circular(24),
          ),
          
          // Bottom info section
          Positioned(
            bottom: AppSpacing.lg,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HIVShimmer(
                  width: 200,
                  height: 32,
                  borderRadius: BorderRadius.circular(16),
                ),
                SizedBox(height: AppSpacing.sm),
                HIVShimmer(
                  width: 120,
                  height: 20,
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Match list item skeleton
class MatchCardSkeleton extends StatelessWidget {
  const MatchCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Avatar shimmer
          HIVShimmer(
            width: 56,
            height: 56,
            borderRadius: BorderRadius.circular(28),
          ),
          SizedBox(width: AppSpacing.md),
          
          // Content shimmer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HIVShimmer(
                  width: 120,
                  height: 20,
                  borderRadius: BorderRadius.circular(10),
                ),
                SizedBox(height: AppSpacing.xs),
                HIVShimmer(
                  width: 200,
                  height: 16,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          ),
          
          // Time shimmer
          HIVShimmer(
            width: 40,
            height: 16,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }
}

// Pulsating loader for subtle loading states
class HIVPulseLoader extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const HIVPulseLoader({
    super.key,
    required this.child,
    this.isLoading = false,
  });

  @override
  State<HIVPulseLoader> createState() => _HIVPulseLoaderState();
}

class _HIVPulseLoaderState extends State<HIVPulseLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 1.0,
      end: 0.4,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isLoading) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(HIVPulseLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _controller.repeat(reverse: true);
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}