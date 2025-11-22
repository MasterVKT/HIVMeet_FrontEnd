// lib/presentation/blocs/matches/matches_event.dart

import 'package:equatable/equatable.dart';

abstract class MatchesEvent extends Equatable {
  const MatchesEvent();

  @override
  List<Object?> get props => [];
}

class LoadMatches extends MatchesEvent {
  final bool refresh;

  const LoadMatches({this.refresh = false});

  @override
  List<Object> get props => [refresh];
}

class LoadMoreMatches extends MatchesEvent {}

class DeleteMatchEvent extends MatchesEvent {
  final String matchId;

  const DeleteMatchEvent({required this.matchId});

  @override
  List<Object> get props => [matchId];
}

class LoadLikesReceived extends MatchesEvent {}

class MarkMatchAsSeen extends MatchesEvent {
  final String matchId;

  const MarkMatchAsSeen({required this.matchId});

  @override
  List<Object> get props => [matchId];
}

/// Filtre les matches par statut (all, new, active)
class FilterMatches extends MatchesEvent {
  final MatchFilter filter;

  const FilterMatches({required this.filter});

  @override
  List<Object> get props => [filter];
}

/// Recherche un match par nom
class SearchMatches extends MatchesEvent {
  final String query;

  const SearchMatches({required this.query});

  @override
  List<Object> get props => [query];
}

/// Enum pour les filtres de matches
enum MatchFilter {
  all,    // Tous les matches
  newMatches,  // Nouveaux matches uniquement
  active, // Matches avec conversations actives
}