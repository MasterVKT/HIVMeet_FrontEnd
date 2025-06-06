// lib/presentation/blocs/discovery/discovery_event.dart

import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/profile.dart';

abstract class DiscoveryEvent extends Equatable {
  const DiscoveryEvent();

  @override
  List<Object?> get props => [];
}

class LoadDiscoveryProfiles extends DiscoveryEvent {
  final int limit;

  const LoadDiscoveryProfiles({this.limit = 20});

  @override
  List<Object> get props => [limit];
}

class SwipeProfile extends DiscoveryEvent {
  final SwipeDirection direction;

  const SwipeProfile({required this.direction});

  @override
  List<Object> get props => [direction];
}

class RewindLastSwipe extends DiscoveryEvent {}

class UpdateFilters extends DiscoveryEvent {
  final SearchPreferences filters;

  const UpdateFilters({required this.filters});

  @override
  List<Object> get props => [filters];
}

class LoadDailyLimit extends DiscoveryEvent {}

enum SwipeDirection {
  left,
  right,
  up,
  down,
}