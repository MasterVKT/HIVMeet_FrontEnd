// lib/presentation/pages/profile/profile_detail_page.dart

import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:go_router/go_router.dart';

class ProfileDetailPage extends StatefulWidget {
  final DiscoveryProfile profile;

  const ProfileDetailPage({
    Key? key,
    required this.profile,
  }) : super(key: key);

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  late PageController _pageController;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Photos
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPhotoIndex = index);
            },
            itemCount: widget.profile.allPhotos.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                panEnabled: false,
                minScale: 1.0,
                maxScale: 3.0,
                child: Image.network(
                  widget.profile.allPhotos[index],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.charcoal,
                      child: const Icon(
                        Icons.person,
                        size: 100,
                        color: AppColors.slate,
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // Photo indicators
          if (widget.profile.allPhotos.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + AppSpacing.md,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: Row(
                children: widget.profile.allPhotos.map((photo) {
                  final index = widget.profile.allPhotos.indexOf(photo);
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                      height: 3,
                      decoration: BoxDecoration(
                        color: index == _currentPhotoIndex
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Info sheet
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: AppSpacing.md),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.silver,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Profile info
                      Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${widget.profile.displayName}, ${widget.profile.age}',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                if (widget.profile.isPremium) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  Container(
                                    padding: EdgeInsets.all(AppSpacing.xs),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.star,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: AppSpacing.sm),

                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 20,
                                  color: AppColors.slate,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  '${widget.profile.city}${widget.profile.distance != null ? ' • ${widget.profile.distance!.round()} km' : ''}',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.slate,
                                  ),
                                ),
                              ],
                            ),

                            if (widget.profile.isOnline) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    'En ligne',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: AppSpacing.lg),

                            // Bio
                            if (widget.profile.bio.isNotEmpty) ...[
                              Text(
                                'À propos',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                widget.profile.bio,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                            ],

                            // Relationship type
                            Text(
                              'Recherche',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getRelationshipTypeLabel(widget.profile.relationshipType),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.primaryPurple,
                                ),
                              ),
                            ),

                            // Interests
                            if (widget.profile.interests.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'Centres d\'intérêt',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: widget.profile.interests.map((interest) {
                                  return Chip(
                                    label: Text(interest),
                                    backgroundColor: AppColors.platinum,
                                  );
                                }).toList(),
                              ),
                            ],

                            const SizedBox(height: AppSpacing.xxl),

                            // Report button
                            Center(
                              child: TextButton.icon(
                                onPressed: () => _showReportDialog(context),
                                icon: const Icon(Icons.flag_outlined),
                                label: const Text('Signaler ce profil'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.slate,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getRelationshipTypeLabel(String type) {
    switch (type) {
      case 'friendship':
        return 'Amitié';
      case 'long_term_relationship':
        return 'Relation sérieuse';
      case 'short_term_relationship':
        return 'Relation courte';
      case 'casual_dating':
        return 'Rencontres occasionnelles';
      case 'networking':
        return 'Réseautage';
      default:
        return type;
    }
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler ce profil'),
        content: const Text(
          'Signalez ce profil si vous pensez qu\'il enfreint nos conditions d\'utilisation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implémenter le signalement
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profil signalé')),
              );
            },
            child: const Text('Signaler'),
          ),
        ],
      ),
    );
  }
}