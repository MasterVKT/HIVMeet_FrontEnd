// lib/presentation/blocs/interaction_history/interaction_history_event.dart

import 'package:equatable/equatable.dart';

abstract class InteractionHistoryEvent extends Equatable {
  const InteractionHistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Charger les likes
class LoadLikes extends InteractionHistoryEvent {
  final bool refresh;
  final bool includeMatched;

  const LoadLikes({
    this.refresh = false,
    this.includeMatched = false,
  });

  @override
  List<Object?> get props => [refresh, includeMatched];
}

/// Charger plus de likes (pagination)
class LoadMoreLikes extends InteractionHistoryEvent {}

/// Charger les profils passés
class LoadPasses extends InteractionHistoryEvent {
  final bool refresh;

  const LoadPasses({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}

/// Charger plus de passes (pagination)
class LoadMorePasses extends InteractionHistoryEvent {}

/// Révoquer une interaction
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

/// Charger les statistiques
class LoadStats extends InteractionHistoryEvent {}

/// Basculer le filtre "Inclure matchés"
class ToggleIncludeMatched extends InteractionHistoryEvent {}
