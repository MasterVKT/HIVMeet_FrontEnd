// lib/presentation/blocs/interaction_history/interaction_history_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/entities/interaction_history.dart';
import 'package:hivmeet/domain/usecases/interaction_history/get_my_likes.dart';
import 'package:hivmeet/domain/usecases/interaction_history/get_my_passes.dart';
import 'package:hivmeet/domain/usecases/interaction_history/revoke_interaction.dart';
import 'package:hivmeet/domain/usecases/interaction_history/get_interaction_stats.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/core/events/app_events.dart';
import 'interaction_history_event.dart';
import 'interaction_history_state.dart';

@injectable
class InteractionHistoryBloc
    extends Bloc<InteractionHistoryEvent, InteractionHistoryState> {
  final GetMyLikes _getMyLikes;
  final GetMyPasses _getMyPasses;
  final RevokeInteraction _revokeInteraction;
  final GetInteractionStats _getInteractionStats;

  // State pour pagination
  List<InteractionHistory> _allLikes = [];
  List<InteractionHistory> _allPasses = [];
  int _likesPage = 1;
  int _passesPage = 1;
  bool _hasMoreLikes = true;
  bool _hasMorePasses = true;
  bool _includeMatched = false;

  InteractionHistoryBloc({
    required GetMyLikes getMyLikes,
    required GetMyPasses getMyPasses,
    required RevokeInteraction revokeInteraction,
    required GetInteractionStats getInteractionStats,
  })  : _getMyLikes = getMyLikes,
        _getMyPasses = getMyPasses,
        _revokeInteraction = revokeInteraction,
        _getInteractionStats = getInteractionStats,
        super(InteractionHistoryInitial()) {
    on<LoadLikes>(_onLoadLikes);
    on<LoadMoreLikes>(_onLoadMoreLikes);
    on<LoadPasses>(_onLoadPasses);
    on<LoadMorePasses>(_onLoadMorePasses);
    on<RevokeInteractionEvent>(_onRevokeInteraction);
    on<LoadStats>(_onLoadStats);
    on<ToggleIncludeMatched>(_onToggleIncludeMatched);
  }

  Future<void> _onLoadLikes(
    LoadLikes event,
    Emitter<InteractionHistoryState> emit,
  ) async {
    if (event.refresh) {
      _allLikes = [];
      _likesPage = 1;
      _hasMoreLikes = true;
      _includeMatched = event.includeMatched;
    }

    emit(LikesLoading());

    final params = GetMyLikesParams(
      page: _likesPage,
      includeMatched: _includeMatched,
    );

    final result = await _getMyLikes(params);

    result.fold(
      (failure) => emit(InteractionHistoryError(message: failure.message)),
      (likes) {
        _allLikes.addAll(likes);
        _hasMoreLikes = likes.length >= 20;

        emit(LikesLoaded(
          likes: _allLikes,
          hasMore: _hasMoreLikes,
          includeMatched: _includeMatched,
        ));
      },
    );
  }

  Future<void> _onLoadMoreLikes(
    LoadMoreLikes event,
    Emitter<InteractionHistoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LikesLoaded) return;
    if (currentState.isLoadingMore || !_hasMoreLikes) return;

    emit(currentState.copyWith(isLoadingMore: true));

    _likesPage++;
    final params = GetMyLikesParams(
      page: _likesPage,
      includeMatched: _includeMatched,
    );

    final result = await _getMyLikes(params);

    result.fold(
      (failure) {
        emit(currentState.copyWith(isLoadingMore: false));
        emit(InteractionHistoryError(message: failure.message));
      },
      (likes) {
        _allLikes.addAll(likes);
        _hasMoreLikes = likes.length >= 20;

        emit(LikesLoaded(
          likes: _allLikes,
          hasMore: _hasMoreLikes,
          includeMatched: _includeMatched,
        ));
      },
    );
  }

  Future<void> _onLoadPasses(
    LoadPasses event,
    Emitter<InteractionHistoryState> emit,
  ) async {
    if (event.refresh) {
      _allPasses = [];
      _passesPage = 1;
      _hasMorePasses = true;
    }

    emit(PassesLoading());

    final params = GetMyPassesParams(page: _passesPage);
    final result = await _getMyPasses(params);

    result.fold(
      (failure) => emit(InteractionHistoryError(message: failure.message)),
      (passes) {
        _allPasses.addAll(passes);
        _hasMorePasses = passes.length >= 20;

        emit(PassesLoaded(
          passes: _allPasses,
          hasMore: _hasMorePasses,
        ));
      },
    );
  }

  Future<void> _onLoadMorePasses(
    LoadMorePasses event,
    Emitter<InteractionHistoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PassesLoaded) return;
    if (currentState.isLoadingMore || !_hasMorePasses) return;

    emit(currentState.copyWith(isLoadingMore: true));

    _passesPage++;
    final params = GetMyPassesParams(page: _passesPage);
    final result = await _getMyPasses(params);

    result.fold(
      (failure) {
        emit(currentState.copyWith(isLoadingMore: false));
        emit(InteractionHistoryError(message: failure.message));
      },
      (passes) {
        _allPasses.addAll(passes);
        _hasMorePasses = passes.length >= 20;

        emit(PassesLoaded(
          passes: _allPasses,
          hasMore: _hasMorePasses,
        ));
      },
    );
  }

  Future<void> _onRevokeInteraction(
    RevokeInteractionEvent event,
    Emitter<InteractionHistoryState> emit,
  ) async {
    final params = RevokeInteractionParams(interactionId: event.interactionId);
    final result = await _revokeInteraction(params);

    result.fold(
      (failure) => emit(InteractionHistoryError(message: failure.message)),
      (_) {
        // Récupérer l'ID du profil avant de le retirer
        String? profileId;
        if (event.isLike) {
          final interaction = _allLikes.firstWhere(
            (l) => l.id == event.interactionId,
            orElse: () => _allLikes.first,
          );
          profileId = interaction.profile.id;
          // ✅ FIX: Créer une NOUVELLE liste au lieu de modifier l'ancienne
          // Cela force Flutter à détecter le changement et à rebuild l'UI
          _allLikes =
              _allLikes.where((l) => l.id != event.interactionId).toList();
          print(
              '🔄 InteractionHistoryBloc: Liste likes mise à jour - ${_allLikes.length} restants');
          emit(LikesLoaded(
            likes: _allLikes,
            hasMore: _hasMoreLikes,
            includeMatched: _includeMatched,
          ));
        } else {
          final interaction = _allPasses.firstWhere(
            (p) => p.id == event.interactionId,
            orElse: () => _allPasses.first,
          );
          profileId = interaction.profile.id;
          // ✅ FIX: Créer une NOUVELLE liste au lieu de modifier l'ancienne
          // Cela force Flutter à détecter le changement et à rebuild l'UI
          _allPasses =
              _allPasses.where((p) => p.id != event.interactionId).toList();
          print(
              '🔄 InteractionHistoryBloc: Liste passes mise à jour - ${_allPasses.length} restants');
          emit(PassesLoaded(
            passes: _allPasses,
            hasMore: _hasMorePasses,
          ));
        }

        // Notifier que le profil doit réapparaître dans Discovery
        print(
            '📢 InteractionHistoryBloc: Notification révocation profil $profileId');
        AppEvents().notifyInteractionRevoked(profileId);
      },
    );
  }

  Future<void> _onLoadStats(
    LoadStats event,
    Emitter<InteractionHistoryState> emit,
  ) async {
    emit(StatsLoading());

    final result = await _getInteractionStats(NoParams());

    result.fold(
      (failure) => emit(InteractionHistoryError(message: failure.message)),
      (stats) => emit(StatsLoaded(stats: stats)),
    );
  }

  Future<void> _onToggleIncludeMatched(
    ToggleIncludeMatched event,
    Emitter<InteractionHistoryState> emit,
  ) async {
    _includeMatched = !_includeMatched;
    add(LoadLikes(refresh: true, includeMatched: _includeMatched));
  }
}
