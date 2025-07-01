// lib/presentation/blocs/resource_detail/resource_detail_state.dart

import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/resource.dart';

abstract class ResourceDetailState extends Equatable {
  const ResourceDetailState();

  @override
  List<Object?> get props => [];
}

class ResourceDetailInitial extends ResourceDetailState {}

class ResourceDetailLoading extends ResourceDetailState {}

class ResourceDetailLoaded extends ResourceDetailState {
  final Resource resource;
  final bool userHasPremium;

  const ResourceDetailLoaded({
    required this.resource,
    required this.userHasPremium,
  });

  ResourceDetailLoaded copyWith({
    Resource? resource,
    bool? userHasPremium,
  }) {
    return ResourceDetailLoaded(
      resource: resource ?? this.resource,
      userHasPremium: userHasPremium ?? this.userHasPremium,
    );
  }

  @override
  List<Object> get props => [resource, userHasPremium];
}

class ResourceDetailError extends ResourceDetailState {
  final String message;

  const ResourceDetailError({required this.message});

  @override
  List<Object> get props => [message];
}
