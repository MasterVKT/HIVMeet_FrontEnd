part of 'resources_bloc.dart';

abstract class ResourcesState extends Equatable {
  const ResourcesState();

  @override
  List<Object?> get props => [];
}

class ResourcesInitial extends ResourcesState {}

class ResourcesLoading extends ResourcesState {}

class ResourcesLoaded extends ResourcesState {
  final List<Resource> resources;

  const ResourcesLoaded({required this.resources});

  @override
  List<Object?> get props => [resources];
}

class ResourcesError extends ResourcesState {
  final String message;

  const ResourcesError({required this.message});

  @override
  List<Object?> get props => [message];
}
