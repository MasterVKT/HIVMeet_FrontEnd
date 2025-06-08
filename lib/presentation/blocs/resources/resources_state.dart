// lib/presentation/blocs/resources/resources_state.dart

import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/resource.dart';

abstract class ResourcesState extends Equatable {
  const ResourcesState();

  @override
  List<Object?> get props => [];
}

class ResourcesInitial extends ResourcesState {}

class ResourcesLoading extends ResourcesState {}

class ResourcesLoaded extends ResourcesState {
  final List<ResourceCategory> categories;
  final List<Resource> resources;
  final String? selectedCategoryId;
  final bool hasMore;
  final bool isLoadingMore;
  final String? searchQuery;

  const ResourcesLoaded({
    required this.categories,
    required this.resources,
    this.selectedCategoryId,
    required this.hasMore,
    this.isLoadingMore = false,
    this.searchQuery,
  });

  ResourcesLoaded copyWith({
    List<ResourceCategory>? categories,
    List<Resource>? resources,
    String? selectedCategoryId,
    bool? hasMore,
    bool? isLoadingMore,
    String? searchQuery,
  }) {
    return ResourcesLoaded(
      categories: categories ?? this.categories,
      resources: resources ?? this.resources,
      selectedCategoryId: selectedCategoryId,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        categories,
        resources,
        selectedCategoryId,
        hasMore,
        isLoadingMore,
        searchQuery,
      ];
}

class ResourcesError extends ResourcesState {
  final String message;

  const ResourcesError({required this.message});

  @override
  List<Object> get props => [message];
}