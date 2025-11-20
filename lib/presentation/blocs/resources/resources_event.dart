part of 'resources_bloc.dart';

abstract class ResourcesEvent extends Equatable {
  const ResourcesEvent();

  @override
  List<Object?> get props => [];
}

class LoadResources extends ResourcesEvent {
  final String? category;

  const LoadResources(this.category);

  @override
  List<Object?> get props => [category];
}

class SearchResources extends ResourcesEvent {
  final String query;

  const SearchResources(this.query);

  @override
  List<Object?> get props => [query];
}

class AddFavorite extends ResourcesEvent {
  final String resourceId;

  const AddFavorite(this.resourceId);

  @override
  List<Object?> get props => [resourceId];
}
