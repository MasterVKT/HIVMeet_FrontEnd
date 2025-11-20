// lib/presentation/blocs/matches/matches_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/usecases/match/get_matches.dart';
import 'package:hivmeet/domain/usecases/match/delete_match.dart';
import 'package:hivmeet/domain/usecases/match/get_likes_received.dart';
import 'package:hivmeet/domain/usecases/match/get_likes_received_count.dart';
import 'matches_event.dart';
import 'matches_state.dart';

/// BLoC pour la gestion des matches
///
/// Responsabilités:
/// - Chargement et pagination des matches
/// - Filtrage (all/new/active)
/// - Recherche par nom
/// - Suppression de matches
/// - Gestion des likes reçus (premium)
/// - Compteurs (nouveaux matches, likes reçus)
@injectable
class MatchesBloc extends Bloc<MatchesEvent, MatchesState> {
  final GetMatches _getMatches;
  final DeleteMatch _deleteMatch;
  final GetLikesReceived _getLikesReceived;
  final GetLikesReceivedCount _getLikesReceivedCount;

  // State management
  List<Match> _allMatches = [];
  String? _lastMatchId;
  bool _hasMore = true;

  MatchesBloc({
    required GetMatches getMatches,
    required DeleteMatch deleteMatch,
    required GetLikesReceived getLikesReceived,
    required GetLikesReceivedCount getLikesReceivedCount,
  })  : _getMatches = getMatches,
        _deleteMatch = deleteMatch,
        _getLikesReceived = getLikesReceived,
        _getLikesReceivedCount = getLikesReceivedCount,
        super(MatchesInitial()) {
    on<LoadMatches>(_onLoadMatches);
    on<LoadMoreMatches>(_onLoadMoreMatches);
    on<DeleteMatchEvent>(_onDeleteMatch);
    on<LoadLikesReceived>(_onLoadLikesReceived);
    on<MarkMatchAsSeen>(_onMarkMatchAsSeen);
    on<FilterMatches>(_onFilterMatches);
    on<SearchMatches>(_onSearchMatches);
  }

  /// Charge les matches initiaux
  Future<void> _onLoadMatches(
    LoadMatches event,
    Emitter<MatchesState> emit,
  ) async {
    emit(MatchesLoading());

    // Si refresh, réinitialiser la pagination
    if (event.refresh) {
      _allMatches = [];
      _lastMatchId = null;
      _hasMore = true;
    }

    // Charger les matches
    final matchesResult = await _getMatches(GetMatchesParams.initial());

    await matchesResult.fold(
      (failure) async {
        emit(MatchesError(message: failure.message));
      },
      (matches) async {
        _allMatches = matches;
        _lastMatchId = matches.isNotEmpty ? matches.last.id : null;
        _hasMore = matches.length >= 20;

        // Charger le compteur de likes reçus en parallèle
        final likesCountResult = await _getLikesReceivedCount(NoParams());
        final likesCount = likesCountResult.fold(
          (failure) => 0,
          (count) => count,
        );

        final newMatchesCount = matches.where((m) => m.isNew).length;

        emit(MatchesLoaded(
          matches: _allMatches,
          allMatches: _allMatches,
          hasMore: _hasMore,
          newMatchesCount: newMatchesCount,
          likesReceivedCount: likesCount,
        ));
      },
    );
  }

  /// Charge plus de matches (pagination)
  Future<void> _onLoadMoreMatches(
    LoadMoreMatches event,
    Emitter<MatchesState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MatchesLoaded) return;
    if (currentState.isLoadingMore || !_hasMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final params = GetMatchesParams(
      limit: 20,
      lastMatchId: _lastMatchId,
    );

    final result = await _getMatches(params);

    result.fold(
      (failure) {
        emit(currentState.copyWith(isLoadingMore: false));
        emit(MatchesError(message: failure.message));
      },
      (newMatches) {
        _allMatches.addAll(newMatches);
        _lastMatchId = newMatches.isNotEmpty ? newMatches.last.id : _lastMatchId;
        _hasMore = newMatches.length >= 20;

        emit(currentState.copyWith(
          matches: List.from(_allMatches),
          allMatches: List.from(_allMatches),
          hasMore: _hasMore,
          isLoadingMore: false,
        ));
      },
    );
  }

  /// Supprime un match (unmatch)
  Future<void> _onDeleteMatch(
    DeleteMatchEvent event,
    Emitter<MatchesState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MatchesLoaded) return;

    // Optimistic update: retirer immédiatement de l'UI
    final optimisticMatches = List<Match>.from(_allMatches)
      ..removeWhere((match) => match.id == event.matchId);

    emit(currentState.copyWith(
      matches: optimisticMatches,
      allMatches: optimisticMatches,
      newMatchesCount: optimisticMatches.where((m) => m.isNew).length,
    ));

    // Appeler le use case
    final params = DeleteMatchParams(matchId: event.matchId);
    final result = await _deleteMatch(params);

    result.fold(
      (failure) {
        // Rollback en cas d'erreur
        emit(currentState.copyWith(
          matches: List.from(_allMatches),
          allMatches: List.from(_allMatches),
        ));
        emit(MatchesError(message: failure.message));
      },
      (_) {
        // Succès: mettre à jour le state persistant
        _allMatches = optimisticMatches;
      },
    );
  }

  /// Charge les likes reçus (feature premium)
  Future<void> _onLoadLikesReceived(
    LoadLikesReceived event,
    Emitter<MatchesState> emit,
  ) async {
    emit(LikesReceivedLoading());

    final result = await _getLikesReceived(GetLikesReceivedParams.initial());

    result.fold(
      (failure) {
        emit(MatchesError(message: failure.message));
      },
      (profiles) {
        emit(LikesReceivedLoaded(
          profiles: profiles,
          hasMore: profiles.length >= 20,
        ));
      },
    );
  }

  /// Marque un match comme vu (remove badge "New")
  Future<void> _onMarkMatchAsSeen(
    MarkMatchAsSeen event,
    Emitter<MatchesState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MatchesLoaded) return;

    final matchIndex = _allMatches.indexWhere((m) => m.id == event.matchId);
    if (matchIndex == -1) return;

    // Mettre à jour isNew localement
    _allMatches[matchIndex] = _allMatches[matchIndex].copyWith(isNew: false);

    emit(currentState.copyWith(
      matches: List.from(_allMatches),
      allMatches: List.from(_allMatches),
      newMatchesCount: _allMatches.where((m) => m.isNew).length,
    ));
  }

  /// Filtre les matches par statut
  Future<void> _onFilterMatches(
    FilterMatches event,
    Emitter<MatchesState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MatchesLoaded) return;

    // Le filtrage est fait via le getter filteredMatches dans le state
    emit(currentState.copyWith(
      currentFilter: event.filter,
    ));
  }

  /// Recherche un match par nom
  Future<void> _onSearchMatches(
    SearchMatches event,
    Emitter<MatchesState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MatchesLoaded) return;

    // La recherche est faite via le getter filteredMatches dans le state
    emit(currentState.copyWith(
      searchQuery: event.query,
    ));
  }
}
