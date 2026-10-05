import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/interaction_history.dart';

abstract class InteractionHistoryEvent extends Equatable {
  const InteractionHistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadLikes extends InteractionHistoryEvent {
  final bool refresh;
  final String query;
  final InteractionMatchFilter matchFilter;

  const LoadLikes({
    this.refresh = false,
    this.query = '',
    this.matchFilter = InteractionMatchFilter.all,
  });

  @override
  List<Object?> get props => [refresh, query, matchFilter];
}

class LoadMoreLikes extends InteractionHistoryEvent {}

class LoadPasses extends InteractionHistoryEvent {
  final bool refresh;
  final String query;
  final InteractionMatchFilter matchFilter;

  const LoadPasses({
    this.refresh = false,
    this.query = '',
    this.matchFilter = InteractionMatchFilter.all,
  });

  @override
  List<Object?> get props => [refresh, query, matchFilter];
}

class LoadMorePasses extends InteractionHistoryEvent {}

/// Compatibility event for the existing single-action affordance.
class RevokeInteractionEvent extends InteractionHistoryEvent {
  final String interactionId;
  final bool isLike;

  const RevokeInteractionEvent({
    required this.interactionId,
    required this.isLike,
  });

  @override
  List<Object?> get props => [interactionId, isLike];
}

class ToggleInteractionSelection extends InteractionHistoryEvent {
  final bool isLike;
  final String interactionId;
  final bool selected;

  const ToggleInteractionSelection({
    required this.isLike,
    required this.interactionId,
    required this.selected,
  });

  @override
  List<Object?> get props => [isLike, interactionId, selected];
}

class SelectHistoryPage extends InteractionHistoryEvent {
  final bool isLike;
  final bool selected;

  const SelectHistoryPage({required this.isLike, required this.selected});

  @override
  List<Object?> get props => [isLike, selected];
}

class SelectAllHistoryResults extends InteractionHistoryEvent {
  final bool isLike;

  const SelectAllHistoryResults({required this.isLike});

  @override
  List<Object?> get props => [isLike];
}

class ClearHistorySelection extends InteractionHistoryEvent {
  final bool isLike;

  const ClearHistorySelection({required this.isLike});

  @override
  List<Object?> get props => [isLike];
}

class RevokeSelectedInteractions extends InteractionHistoryEvent {
  final bool isLike;

  const RevokeSelectedInteractions({required this.isLike});

  @override
  List<Object?> get props => [isLike];
}

class LoadStats extends InteractionHistoryEvent {}
