// lib/presentation/blocs/resource_detail/resource_detail_event.dart

import 'package:equatable/equatable.dart';

abstract class ResourceDetailEvent extends Equatable {
  const ResourceDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadResourceDetail extends ResourceDetailEvent {
  final String resourceId;

  const LoadResourceDetail({required this.resourceId});

  @override
  List<Object> get props => [resourceId];
}

class ToggleResourceFavorite extends ResourceDetailEvent {
  final String resourceId;

  const ToggleResourceFavorite({required this.resourceId});

  @override
  List<Object> get props => [resourceId];
}
