// lib/presentation/pages/resources/resources_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/resources/resources_bloc.dart';
import 'package:hivmeet/presentation/blocs/resources/resources_event.dart';
import 'package:hivmeet/presentation/blocs/resources/resources_state.dart';
import 'package:hivmeet/presentation/widgets/cards/resource_card.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';
import 'package:go_router/go_router.dart';

class ResourcesPage extends StatefulWidget {
  const ResourcesPage({super.key});

  @override
  State<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends State<ResourcesPage> {
  late TextEditingController _searchController;
  
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ResourcesBloc>()..add(LoadCategories()),
      child: Scaffold(
        backgroundColor: AppColors.primaryWhite,
        appBar: AppBar(
          title: const Text('Ressources'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.favorite_outline),
              onPressed: () => context.push('/resources/favorites'),
            ),
          ],
        ),
        body: BlocBuilder<ResourcesBloc, ResourcesState>(
          builder: (context, state) {
            if (state is ResourcesLoading) {
              return const Center(child: HIVLoader());
            }
            
            if (state is ResourcesError) {
              return Center(
                child: Text(state.message),
              );
            }
            
            if (state is ResourcesLoaded) {
              return Column(
                children: [
                  // Search bar
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher des ressources...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  context.read<ResourcesBloc>().add(
                                    const LoadResources(),
                                  );
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.platinum,
                      ),
                      onSubmitted: (query) {
                        if (query.isNotEmpty) {
                          context.read<ResourcesBloc>().add(
                            SearchResources(query: query),
                          );
                        }
                      },
                    ),
                  ),
                  
                  // Categories
                  if (state.searchQuery == null)
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        itemCount: state.categories.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildCategoryChip(
                              context,
                              'Tous',
                              null,
                              state.selectedCategoryId == null,
                            );
                          }
                          
                          final category = state.categories[index - 1];
                          return _buildCategoryChip(
                            context,
                            category.name,
                            category.id,
                            state.selectedCategoryId == category.id,
                          );
                        },
                      ),
                    ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // Resources list
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        context.read<ResourcesBloc>().add(
                          LoadResources(
                            categoryId: state.selectedCategoryId,
                            searchQuery: state.searchQuery,
                            refresh: true,
                          ),
                        );
                      },
                      child: ListView.builder(
                        padding: EdgeInsets.all(AppSpacing.md),
                        itemCount: state.resources.length + (state.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.resources.length) {
                            if (!state.isLoadingMore) {
                              context.read<ResourcesBloc>().add(LoadMoreResources());
                            }
                            return const Center(child: HIVLoader());
                          }
                          
                          final resource = state.resources[index];
                          return ResourceCard(
                            resource: resource,
                            onTap: () => context.push('/resources/${resource.id}'),
                            onFavoriteToggle: () {
                              context.read<ResourcesBloc>().add(
                                ToggleFavorite(resourceId: resource.id),
                              );
                            },
                          );
                        },
                      ),
                    ),
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

  Widget _buildCategoryChip(
    BuildContext context,
    String label,
    String? categoryId,
    bool isSelected,
  ) {
    return Padding(
      padding: EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primaryPurple,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.charcoal,
        ),
        onSelected: (selected) {
          if (selected) {
            context.read<ResourcesBloc>().add(
              SelectCategory(categoryId: categoryId),
            );
          }
        },
      ),
    );
  }
}