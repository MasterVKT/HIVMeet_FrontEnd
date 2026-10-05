// lib/presentation/blocs/matches/matches_state.dart

import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'matches_event.dart'; // Pour MatchFilter

abstract class MatchesState extends Equatable {
  const MatchesState();

  @override
  List<Object?> get props => [];
}

class MatchesInitial extends MatchesState {}

class MatchesLoading extends MatchesState {}

class MatchesLoaded extends MatchesState {
  final List<Match> matches;
  final List<Match> allMatches; // Tous les matches pour filtrage local
  final bool hasMore;
  final bool isLoadingMore;
  final int newMatchesCount;
  final int likesReceivedCount;
  final MatchFilter currentFilter;
  final String searchQuery;
  final String? deletingMatchId;
  final String? actionMessage;
  final bool actionSucceeded;
  final int actionSequence;

  const MatchesLoaded({
    required this.matches,
    required this.allMatches,
    required this.hasMore,
    this.isLoadingMore = false,
    this.newMatchesCount = 0,
    this.likesReceivedCount = 0,
    this.currentFilter = MatchFilter.all,
    this.searchQuery = '',
    this.deletingMatchId,
    this.actionMessage,
    this.actionSucceeded = false,
    this.actionSequence = 0,
  });

  /// Getter pour les matches filtrés selon le filtre et la recherche
  List<Match> get filteredMatches {
    var filtered = List<Match>.from(allMatches);

    // Appliquer le filtre
    switch (currentFilter) {
      case MatchFilter.newMatches:
        filtered = filtered.where((m) => m.isNew).toList();
        break;
      case MatchFilter.active:
        // Active = matches avec au moins un message
        filtered = filtered.where((m) => m.lastMessage != null).toList();
        break;
      case MatchFilter.all:
        // Pas de filtre
        break;
    }

    // Appliquer la recherche
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((m) {
        final name = m.profile.displayName.toLowerCase();
        final query = searchQuery.toLowerCase();
        return name.contains(query);
      }).toList();
    }

    return filtered;
  }

  MatchesLoaded copyWith({
    List<Match>? matches,
    List<Match>? allMatches,
    bool? hasMore,
    bool? isLoadingMore,
    int? newMatchesCount,
    int? likesReceivedCount,
    MatchFilter? currentFilter,
    String? searchQuery,
    String? deletingMatchId,
    String? actionMessage,
    bool? actionSucceeded,
    int? actionSequence,
    bool clearDeletingMatchId = false,
    bool clearActionMessage = false,
  }) {
    return MatchesLoaded(
      matches: matches ?? this.matches,
      allMatches: allMatches ?? this.allMatches,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      newMatchesCount: newMatchesCount ?? this.newMatchesCount,
      likesReceivedCount: likesReceivedCount ?? this.likesReceivedCount,
      currentFilter: currentFilter ?? this.currentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      deletingMatchId:
          clearDeletingMatchId ? null : deletingMatchId ?? this.deletingMatchId,
      actionMessage:
          clearActionMessage ? null : actionMessage ?? this.actionMessage,
      actionSucceeded: actionSucceeded ?? this.actionSucceeded,
      actionSequence: actionSequence ?? this.actionSequence,
    );
  }

  @override
  List<Object?> get props => [
        matches,
        allMatches,
        hasMore,
        isLoadingMore,
        newMatchesCount,
        likesReceivedCount,
        currentFilter,
        searchQuery,
        deletingMatchId,
        actionMessage,
        actionSucceeded,
        actionSequence,
      ];
}

class LikesReceivedLoading extends MatchesState {}

class LikesReceivedLoaded extends MatchesState {
  final List<DiscoveryProfile> profiles;
  final bool hasMore;
  final bool isFreeReveal;

  const LikesReceivedLoaded({
    required this.profiles,
    required this.hasMore,
    this.isFreeReveal = false,
  });

  @override
  List<Object> get props => [profiles, hasMore, isFreeReveal];
}

class MatchesError extends MatchesState {
  final String message;
  final String? code;

  const MatchesError({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}
