// lib/presentation/blocs/discovery/discovery_event.dart

import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/entities/search_filters.dart';

abstract class DiscoveryEvent extends Equatable {
  const DiscoveryEvent();

  @override
  List<Object?> get props => [];
}

class LoadDiscoveryProfiles extends DiscoveryEvent {
  final int limit;
  final bool forceRefresh;

  const LoadDiscoveryProfiles({
    this.limit = 20,
    this.forceRefresh = false,
  });

  @override
  List<Object> get props => [limit, forceRefresh];
}

class SwipeProfile extends DiscoveryEvent {
  final SwipeDirection direction;

  const SwipeProfile({required this.direction});

  @override
  List<Object> get props => [direction];
}

class RewindLastSwipe extends DiscoveryEvent {}

class UpdateFilters extends DiscoveryEvent {
  final SearchFilters filters;

  const UpdateFilters({required this.filters});

  @override
  List<Object> get props => [filters];
}

class LoadDailyLimit extends DiscoveryEvent {}

class LoadMoreProfiles extends DiscoveryEvent {
  final int limit;

  const LoadMoreProfiles({this.limit = 20});

  @override
  List<Object> get props => [limit];
}

class DismissError extends DiscoveryEvent {
  const DismissError();
}
