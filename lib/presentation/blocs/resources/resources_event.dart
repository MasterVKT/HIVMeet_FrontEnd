// lib/presentation/blocs/resources/resources_event.dart

import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/resource.dart';

abstract class ResourcesEvent extends Equatable {
  const ResourcesEvent();

  @override
  List<Object?> get props => [];
}

class LoadCategories extends ResourcesEvent {}

class LoadResources extends ResourcesEvent {
  final String? categoryId;
  final String? searchQuery;
  final List<String>? tags;
  final ResourceType? type;
  final bool refresh;

  const LoadResources({
    this.categoryId,
    this.searchQuery,
    this.tags,
    this.type,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [categoryId, searchQuery, tags, type, refresh];
}

class LoadMoreResources extends ResourcesEvent {}

class SelectCategory extends ResourcesEvent {
  final String? categoryId;

  const SelectCategory({this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

class SearchResources extends ResourcesEvent {
  final String query;

  const SearchResources({required this.query});

  @override
  List<Object?> get props => [query];
}

class ToggleFavorite extends ResourcesEvent {
  final String resourceId;

  const ToggleFavorite({required this.resourceId});

  @override
  List<Object?> get props => [resourceId];
}