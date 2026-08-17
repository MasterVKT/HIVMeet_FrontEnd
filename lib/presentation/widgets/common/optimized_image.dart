// lib/presentation/widgets/common/optimized_image.dart

import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';

class OptimizedImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableLazyLoading;
  final Duration fadeInDuration;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.enableLazyLoading = true,
    this.fadeInDuration = const Duration(milliseconds: 300),
  });

  @override
  State<OptimizedImage> createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: widget.fadeInDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Vérifier si l'URL est vide ou invalide
    if (widget.imageUrl.isEmpty || widget.imageUrl == 'placeholder') {
      return _buildEmptyPlaceholder();
    }

    if (widget.enableLazyLoading) {
      return _buildLazyImage();
    } else {
      return _buildDirectImage();
    }
  }

  Widget _buildEmptyPlaceholder() {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withOpacityValues(0.1),
            AppColors.primaryPurple.withOpacityValues(0.05),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              size: widget.height != null ? widget.height! * 0.3 : 60,
              color: AppColors.primaryPurple.withOpacityValues(0.3),
            ),
            const SizedBox(height: 8),
            Text(
              LocalizationService.translate('profile.no_photo'),
              style: TextStyle(
                color: AppColors.slate,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLazyImage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Image.network(
          widget.imageUrl,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              if (!_isLoaded) {
                _isLoaded = true;
                _fadeController.forward();
              }
              return FadeTransition(
                opacity: _fadeAnimation,
                child: child,
              );
            }
            return _buildPlaceholder();
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget();
          },
          // Optimisations de performance
          cacheWidth: (widget.width != null && widget.width!.isFinite)
              ? widget.width!.toInt()
              : null,
          cacheHeight: (widget.height != null && widget.height!.isFinite)
              ? widget.height!.toInt()
              : null,
          filterQuality: FilterQuality.medium,
        );
      },
    );
  }

  Widget _buildDirectImage() {
    return Image.network(
      widget.imageUrl,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          if (!_isLoaded) {
            _isLoaded = true;
            _fadeController.forward();
          }
          return FadeTransition(
            opacity: _fadeAnimation,
            child: child,
          );
        }
        return _buildPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorWidget();
      },
      // Optimisations de performance
      cacheWidth: widget.width?.toInt(),
      cacheHeight: widget.height?.toInt(),
      filterQuality: FilterQuality.medium,
    );
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.slate.withOpacityValues(0.1),
            AppColors.slate.withOpacityValues(0.05),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              LocalizationService.translate('common.loading'),
              style: TextStyle(
                color: AppColors.slate,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withOpacityValues(0.3),
            AppColors.primaryPurple.withOpacityValues(0.1),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: widget.height != null ? widget.height! * 0.3 : 60,
            color: AppColors.primaryPurple,
          ),
          const SizedBox(height: 8),
          Text(
            LocalizationService.translate('profile.profile_photo'),
            style: TextStyle(
              color: AppColors.primaryPurple,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
