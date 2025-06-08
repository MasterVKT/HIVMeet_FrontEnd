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

class DeleteMatch extends MatchesEvent {
  final String matchId;

  const DeleteMatch({required this.matchId});

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