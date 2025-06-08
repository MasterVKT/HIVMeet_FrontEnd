// lib/presentation/blocs/matches/matches_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';
import 'matches_event.dart';
import 'matches_state.dart';

@injectable
class MatchesBloc extends Bloc<MatchesEvent, MatchesState> {
  final MatchRepository _matchRepository;
  
  List<Match> _matches = [];
  String? _lastMatchId;
  bool _hasMore = true;

  MatchesBloc({
    required MatchRepository matchRepository,
  })  : _matchRepository = matchRepository,
        super(MatchesInitial()) {
    on<LoadMatches>(_onLoadMatches);
    on<LoadMoreMatches>(_onLoadMoreMatches);
    on<DeleteMatch>(_onDeleteMatch);
    on<LoadLikesReceived>(_onLoadLikesReceived);
    on<MarkMatchAsSeen>(_onMarkMatchAsSeen);
  }

  Future<void> _onLoadMatches(
    LoadMatches event,
    Emitter<MatchesState> emit,
  ) async {
    emit(MatchesLoading());
    
    final result = await _matchRepository.getMatches(limit: 20);
    
    result.fold(
      (failure) => emit(MatchesError(message: failure.message)),
      (matches) async {
        _matches = matches;
        _lastMatchId = matches.isNotEmpty ? matches.last.id : null;
        _hasMore = matches.length >= 20;
        
        // Get counts
        final likesCountResult = await _matchRepository.getLikesReceivedCount();
        final likesCount = likesCountResult.fold(
          (failure) => 0,
          (count) => count,
        );
        
        final newMatchesCount = matches.where((m) => m.isNew).length;
        
        emit(MatchesLoaded(
          matches: _matches,
          hasMore: _hasMore,
          newMatchesCount: newMatchesCount,
          likesReceivedCount: likesCount,
        ));
      },
    );
  }

  Future<void> _onLoadMoreMatches(
    LoadMoreMatches event,
    Emitter<MatchesState> emit,
  ) async {
    final currentState = state;
    if (currentState is MatchesLoaded && !currentState.isLoadingMore && _hasMore) {
      emit(currentState.copyWith(isLoadingMore: true));
      
      final result = await _matchRepository.getMatches(
        limit: 20,
        lastMatchId: _lastMatchId,
      );
      
      result.fold(
        (failure) => emit(MatchesError(message: failure.message)),
        (newMatches) {
          _matches.addAll(newMatches);
          _lastMatchId = newMatches.isNotEmpty ? newMatches.last.id : _lastMatchId;
          _hasMore = newMatches.length >= 20;
          
          emit(currentState.copyWith(
            matches: List.from(_matches),
            hasMore: _hasMore,
            isLoadingMore: false,
          ));
        },
      );
    }
  }

  Future<void> _onDeleteMatch(
    DeleteMatch event,
    Emitter<MatchesState> emit,
  ) async {
    final currentState = state;
    if (currentState is MatchesLoaded) {
      final result = await _matchRepository.deleteMatch(event.matchId);
      
      result.fold(
        (failure) => emit(MatchesError(message: failure.message)),
        (_) {
          _matches.removeWhere((match) => match.id == event.matchId);
          emit(currentState.copyWith(
            matches: List.from(_matches),
            newMatchesCount: _matches.where((m) => m.isNew).length,
          ));
        },
      );
    }
  }

  Future<void> _onLoadLikesReceived(
    LoadLikesReceived event,
    Emitter<MatchesState> emit,
  ) async {
    emit(LikesReceivedLoading());
    
    final result = await _matchRepository.getLikesReceived(limit: 20);
    
    result.fold(
      (failure) => emit(MatchesError(message: failure.message)),
      (profiles) {
        emit(LikesReceivedLoaded(
          profiles: profiles,
          hasMore: profiles.length >= 20,
        ));
      },
    );
  }

  Future<void> _onMarkMatchAsSeen(
    MarkMatchAsSeen event,
    Emitter<MatchesState> emit,
  ) async {
    final currentState = state;
    if (currentState is MatchesLoaded) {
      final matchIndex = _matches.indexWhere((m) => m.id == event.matchId);
      if (matchIndex != -1) {
        _matches[matchIndex] = _matches[matchIndex].copyWith(isNew: false);
        
        emit(currentState.copyWith(
          matches: List.from(_matches),
          newMatchesCount: _matches.where((m) => m.isNew).length,
        ));
      }
    }
  }
}