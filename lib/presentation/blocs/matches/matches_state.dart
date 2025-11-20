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

  const MatchesLoaded({
    required this.matches,
    required this.allMatches,
    required this.hasMore,
    this.isLoadingMore = false,
    this.newMatchesCount = 0,
    this.likesReceivedCount = 0,
    this.currentFilter = MatchFilter.all,
    this.searchQuery = '',
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
      default:
        // Pas de filtre
        break;
    }

    // Appliquer la recherche
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((m) {
        final name = m.matchedUser?.name?.toLowerCase() ?? '';
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
      ];
}

class LikesReceivedLoading extends MatchesState {}

class LikesReceivedLoaded extends MatchesState {
  final List<DiscoveryProfile> profiles;
  final bool hasMore;

  const LikesReceivedLoaded({
    required this.profiles,
    required this.hasMore,
  });

  @override
  List<Object> get props => [profiles, hasMore];
}

class MatchesError extends MatchesState {
  final String message;

  const MatchesError({required this.message});

  @override
  List<Object> get props => [message];
}