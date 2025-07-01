// lib/presentation/pages/resources/resource_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/domain/entities/resource.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/resource_detail/resource_detail_bloc.dart';
import 'package:hivmeet/presentation/blocs/resource_detail/resource_detail_event.dart';
import 'package:hivmeet/presentation/blocs/resource_detail/resource_detail_state.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourceDetailPage extends StatelessWidget {
  final String resourceId;

  const ResourceDetailPage({
    super.key,
    required this.resourceId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ResourceDetailBloc>()
        ..add(LoadResourceDetail(resourceId: resourceId)),
      child: Scaffold(
        backgroundColor: AppColors.primaryWhite,
        body: BlocBuilder<ResourceDetailBloc, ResourceDetailState>(
          builder: (context, state) {
            if (state is ResourceDetailLoading) {
              return const Center(child: HIVLoader());
            }
            
            if (state is ResourceDetailError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      state.message,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Retour'),
                    ),
                  ],
                ),
              );
            }
            
            if (state is ResourceDetailLoaded) {
              final resource = state.resource;
              
              // Check if premium content is locked
              if (resource.isPremium && !state.userHasPremium) {
                return _buildPremiumLockedView(context, resource);
              }
              
              return CustomScrollView(
                slivers: [
                  _buildAppBar(context, resource),
                  SliverToBoxAdapter(
                    child: _buildContent(context, resource),
                  ),
                  if (resource.relatedResources != null && 
                      resource.relatedResources!.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildRelatedResources(context, resource.relatedResources!),
                    ),
                ],
              );
            }
            
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Resource resource) {
    return SliverAppBar(
      expandedHeight: resource.thumbnailUrl != null ? 250 : null,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          resource.title,
          style: const TextStyle(fontSize: 16),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        background: resource.thumbnailUrl != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    resource.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.platinum,
                        child: const Icon(
                          Icons.image,
                          size: 64,
                          color: AppColors.slate,
                        ),
                      );
                    },
                  ),
                  Container(
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
                  ),
                ],
              )
            : null,
      ),
      actions: [
        BlocBuilder<ResourceDetailBloc, ResourceDetailState>(
          builder: (context, state) {
            if (state is ResourceDetailLoaded) {
              return IconButton(
                icon: Icon(
                  state.resource.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_outline,
                ),
                onPressed: () {
                  context.read<ResourceDetailBloc>().add(
                    ToggleResourceFavorite(resourceId: resource.id),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            Share.share(
              'Découvrez cette ressource sur HIVMeet: ${resource.title}',
              subject: resource.title,
            );
          },
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, Resource resource) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metadata
          _buildMetadata(context, resource),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Tags
          if (resource.tags.isNotEmpty) ...[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: resource.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: AppColors.platinum,
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          
          // Content based on type
          _buildResourceContent(context, resource),
          
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildMetadata(BuildContext context, Resource resource) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              _getIconForType(resource.type),
              size: 20,
              color: AppColors.slate,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              resource.categoryName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.slate,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            if (resource.estimatedReadTimeMinutes != null) ...[
              const Icon(
                Icons.timer_outlined,
                size: 16,
                color: AppColors.slate,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${resource.estimatedReadTimeMinutes} min',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.slate,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            if (resource.authorName != null) ...[
              const Icon(
                Icons.person_outline,
                size: 16,
                color: AppColors.slate,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                resource.authorName!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.slate,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Text(
              DateFormat('dd MMMM yyyy').format(resource.publicationDate),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.slate,
              ),
            ),
            const Spacer(),
            if (resource.isVerifiedExpert)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      'Contenu vérifié',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildResourceContent(BuildContext context, Resource resource) {
    switch (resource.type) {
      case ResourceType.article:
        return Html(
          data: resource.content,
          style: {
            'body': Style(
              fontSize: FontSize(16),
              lineHeight: LineHeight(1.6),
            ),
            'h1': Style(
              fontSize: FontSize(24),
              fontWeight: FontWeight.bold,
              margin: Margins.only(top: 16, bottom: 8),
            ),
            'h2': Style(
              fontSize: FontSize(20),
              fontWeight: FontWeight.bold,
              margin: Margins.only(top: 16, bottom: 8),
            ),
            'p': Style(
              margin: Margins.only(bottom: 12),
            ),
            'a': Style(
              color: AppColors.primaryPurple,
              textDecoration: TextDecoration.underline,
            ),
          },
          onLinkTap: (url, _, __) {
            if (url != null) {
              launchUrl(Uri.parse(url));
            }
          },
        );
        
      case ResourceType.video:
        return Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: IconButton(
                    icon: const Icon(
                      Icons.play_circle_filled,
                      size: 64,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (resource.externalLink != null) {
                        launchUrl(Uri.parse(resource.externalLink!));
                      }
                    },
                  ),
                ),
              ),
            ),
            if (resource.content.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                resource.content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ],
        );
        
      case ResourceType.link:
        return Column(
          children: [
            if (resource.content.isNotEmpty)
              Text(
                resource.content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            if (resource.externalLink != null) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    launchUrl(Uri.parse(resource.externalLink!));
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Ouvrir le lien'),
                ),
              ),
            ],
          ],
        );
        
      case ResourceType.contact:
        return _buildContactInfo(context, resource);
    }
  }

  Widget _buildContactInfo(BuildContext context, Resource resource) {
    // Parse contact info from content (assuming JSON format)
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resource.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implement call
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Appeler'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implement map
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text('Localiser'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumLockedView(BuildContext context, Resource resource) {
    return Scaffold(
      appBar: AppBar(
        title: Text(resource.title),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
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
                  Icons.lock,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Contenu Premium',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Cette ressource est réservée aux membres Premium',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
        ),
      ),
    );
  }

  Widget _buildRelatedResources(BuildContext context, List<RelatedResource> related) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'Ressources similaires',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: related.length,
            itemBuilder: (context, index) {
              final item = related[index];
              return Container(
                width: 200,
                margin: EdgeInsets.only(right: AppSpacing.md),
                child: Card(
                  child: InkWell(
                    onTap: () => context.push('/resources/${item.id}'),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.thumbnailUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.thumbnailUrl!,
                                height: 60,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  IconData _getIconForType(ResourceType type) {
    switch (type) {
      case ResourceType.article:
        return Icons.article;
      case ResourceType.video:
        return Icons.play_circle_outline;
      case ResourceType.link:
        return Icons.link;
      case ResourceType.contact:
        return Icons.phone;
    }
  }
}