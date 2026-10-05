import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/events/app_events.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/entities/interaction_history.dart';
import 'package:hivmeet/domain/usecases/interaction_history/get_interaction_stats.dart';
import 'package:hivmeet/domain/usecases/interaction_history/get_my_likes.dart';
import 'package:hivmeet/domain/usecases/interaction_history/get_my_passes.dart';
import 'package:hivmeet/domain/usecases/interaction_history/revoke_interactions.dart';

import 'interaction_history_event.dart';
import 'interaction_history_state.dart';

@injectable
class InteractionHistoryBloc
    extends Bloc<InteractionHistoryEvent, InteractionHistoryState> {
  final GetMyLikes _getMyLikes;
  final GetMyPasses _getMyPasses;
  final RevokeInteractions _revokeInteractions;
  final GetInteractionStats _getInteractionStats;

  List<InteractionHistory> _allLikes = const [];
  List<InteractionHistory> _allPasses = const [];
  int _likesPage = 1;
  int _passesPage = 1;
  bool _hasMoreLikes = true;
  bool _hasMorePasses = true;
  int _likesTotal = 0;
  int _passesTotal = 0;
  int _likesSelectable = 0;
  int _passesSelectable = 0;
  String _likesQuery = '';
  String _passesQuery = '';
  InteractionMatchFilter _likesFilter = InteractionMatchFilter.all;
  InteractionMatchFilter _passesFilter = InteractionMatchFilter.all;
  Set<String> _likesSelected = <String>{};
  Set<String> _passesSelected = <String>{};
  bool _likesSelectAll = false;
  bool _passesSelectAll = false;
  int _actionSequence = 0;

  InteractionHistoryBloc({
    required GetMyLikes getMyLikes,
    required GetMyPasses getMyPasses,
    required RevokeInteractions revokeInteractions,
    required GetInteractionStats getInteractionStats,
  })  : _getMyLikes = getMyLikes,
        _getMyPasses = getMyPasses,
        _revokeInteractions = revokeInteractions,
        _getInteractionStats = getInteractionStats,
        super(InteractionHistoryInitial()) {
    on<LoadLikes>(_onLoadLikes);
    on<LoadMoreLikes>(_onLoadMoreLikes);
    on<LoadPasses>(_onLoadPasses);
    on<LoadMorePasses>(_onLoadMorePasses);
    on<RevokeInteractionEvent>(_onSingleRevoke);
    on<ToggleInteractionSelection>(_onToggleSelection);
    on<SelectHistoryPage>(_onSelectPage);
    on<SelectAllHistoryResults>(_onSelectAll);
    on<ClearHistorySelection>(_onClearSelection);
    on<RevokeSelectedInteractions>(_onBulkRevoke);
    on<LoadStats>(_onLoadStats);
  }

  Future<void> _onLoadLikes(
    LoadLikes event,
    Emitter<InteractionHistoryState> emit,
  ) async {
    final previous = state;
    if (event.refresh || previous is! LikesLoaded) {
      _allLikes = const [];
      _likesPage = 1;
      _hasMoreLikes = true;
      _likesTotal = 0;
      _likesSelectable = 0;
      _likesQuery = event.query;
      _likesFilter = event.matchFilter;
      _likesSelected = <String>{};
      _likesSelectAll = false;
    }
    if (previous is! LikesLoaded) emit(LikesLoading());

    final result = await _getMyLikes(GetMyLikesParams(
      page: _likesPage,
      query: _likesQuery,
      matchFilter: _likesFilter,
    ));
    result.fold(
      (failure) {
        if (previous is LikesLoaded) {
          emit(previous.copyWith(
            actionMessage: failure.message,
            actionSequence: ++_actionSequence,
          ));
        } else {
          emit(InteractionHistoryError(message: failure.message));
        }
      },
      (page) {
        _allLikes = page.interactions;
        _likesTotal = page.totalCount;
        _likesSelectable = page.selectableCount;
        _hasMoreLikes = page.hasNextPage;
        emit(_likesState());
      },
    );
  }

  Future<void> _onLoadMoreLikes(
    LoadMoreLikes event,
    Emitter<InteractionHistoryState> emit,
  ) async {
    final current = state;
    if (current is! LikesLoaded || current.isLoadingMore || !_hasMoreLikes) {
      return;
    }
    emit(current.copyWith(isLoadingMore: true));
    final result = await _getMyLikes(GetMyLikesParams(
      page: _likesPage + 1,
      query: _likesQuery,
      matchFilter: _likesFilter,
    ));
    result.fold(
      (failure) => emit(current.copyWith(
        isLoadingMore: false,
        actionMessage: failure.message,
        actionSequence: ++_actionSequence,
      )),
      (page) {
        _likesPage++;
        _allLikes = [..._allLikes, ...page.interactions];
        _likesTotal = page.totalCount;
        _likesSelectable = page.selectableCount;
        _hasMoreLikes = page.hasNextPage;
        emit(_likesState());
      },
    );
  }

  Future<void> _onLoadPasses(
    LoadPasses event,
    Emitter<InteractionHistoryState> emit,
  ) async {
    final previous = state;
    if (event.refresh || previous is! PassesLoaded) {
      _allPasses = const [];
      _passesPage = 1;
      _hasMorePasses = true;
      _passesTotal = 0;
      _passesSelectable = 0;
      _passesQuery = event.query;
      _passesFilter = event.matchFilter;
      _passesSelected = <String>{};
      _passesSelectAll = false;
    }
    if (previous is! PassesLoaded) emit(PassesLoading());

    final result = await _getMyPasses(GetMyPassesParams(
      page: _passesPage,
      query: _passesQuery,
      matchFilter: _passesFilter,
    ));
    result.fold(
      (failure) {
        if (previous is PassesLoaded) {
          emit(previous.copyWith(
            actionMessage: failure.message,
            actionSequence: ++_actionSequence,
          ));
        } else {
          emit(InteractionHistoryError(message: failure.message));
        }
      },
      (page) {
        _allPasses = page.interactions;
        _passesTotal = page.totalCount;
        _passesSelectable = page.selectableCount;
        _hasMorePasses = page.hasNextPage;
        emit(_passesState());
      },
    );
  }

  Future<void> _onLoadMorePasses(
    LoadMorePasses event,
    Emitter<InteractionHistoryState> emit,
  ) async {
    final current = state;
    if (current is! PassesLoaded || current.isLoadingMore || !_hasMorePasses) {
      return;
    }
    emit(current.copyWith(isLoadingMore: true));
    final result = await _getMyPasses(GetMyPassesParams(
      page: _passesPage + 1,
      query: _passesQuery,
      matchFilter: _passesFilter,
    ));
    result.fold(
      (failure) => emit(current.copyWith(
        isLoadingMore: false,
        actionMessage: failure.message,
        actionSequence: ++_actionSequence,
      )),
      (page) {
        _passesPage++;
        _allPasses = [..._allPasses, ...page.interactions];
        _passesTotal = page.totalCount;
        _passesSelectable = page.selectableCount;
        _hasMorePasses = page.hasNextPage;
        emit(_passesState());
      },
    );
  }

  Future<void> _onSingleRevoke(
    RevokeInteractionEvent event,
    Emitter<InteractionHistoryState> emit,
  ) async {
    if (event.isLike) {
      _likesSelected = {event.interactionId};
      _likesSelectAll = false;
    } else {
      _passesSelected = {event.interactionId};
      _passesSelectAll = false;
    }
    await _revoke(event.isLike, emit);
  }

  Future<void> _onToggleSelection(
    ToggleInteractionSelection event,
    Emitter<InteractionHistoryState> emit,
  ) async {
    final selected =
        Set<String>.from(event.isLike ? _likesSelected : _passesSelected);
    if (event.selected) {
      selected.add(event.interactionId);
    } else {
      selected.remove(event.interactionId);
    }
    if (event.isLike) {
      _likesSelected = selected;
      _likesSelectAll = false;
      emit(_likesState());
    } else {
      _passesSelected = selected;
      _passesSelectAll = false;
      emit(_passesState());
    }
  }

  Future<void> _onSelectPage(
    SelectHistoryPage event,
    Emitter<InteractionHistoryState> emit,
  ) async {
    final selectable = (event.isLike ? _allLikes : _allPasses)
        .where((interaction) => interaction.canRevoke)
        .map((interaction) => interaction.id)
        .toSet();
    if (event.isLike) {
      _likesSelected = event.selected ? selectable : <String>{};
      _likesSelectAll = false;
      emit(_likesState());
    } else {
      _passesSelected = event.selected ? selectable : <String>{};
      _passesSelectAll = false;
      emit(_passesState());
    }
  }

  Future<void> _onSelectAll(
    SelectAllHistoryResults event,
    Emitter<InteractionHistoryState> emit,
  ) async {
    if (event.isLike) {
      _likesSelected = <String>{};
      _likesSelectAll = true;
      emit(_likesState());
    } else {
      _passesSelected = <String>{};
      _passesSelectAll = true;
      emit(_passesState());
    }
  }

  Future<void> _onClearSelection(
    ClearHistorySelection event,
    Emitter<InteractionHistoryState> emit,
  ) async {
    if (event.isLike) {
      _likesSelected = <String>{};
      _likesSelectAll = false;
      emit(_likesState());
    } else {
      _passesSelected = <String>{};
      _passesSelectAll = false;
      emit(_passesState());
    }
  }

  Future<void> _onBulkRevoke(
    RevokeSelectedInteractions event,
    Emitter<InteractionHistoryState> emit,
  ) =>
      _revoke(event.isLike, emit);

  Future<void> _revoke(
      bool isLike, Emitter<InteractionHistoryState> emit) async {
    final current = state;
    final validState =
        isLike ? current is LikesLoaded : current is PassesLoaded;
    if (!validState) return;
    final ids = isLike ? _likesSelected : _passesSelected;
    final selectAll = isLike ? _likesSelectAll : _passesSelectAll;
    if (!selectAll && ids.isEmpty) return;

    if (isLike) {
      emit(_likesState(isBulkRevoking: true));
    } else {
      emit(_passesState(isBulkRevoking: true));
    }

    final result = await _revokeInteractions(BulkRevokeRequest(
      historyType:
          isLike ? InteractionHistoryType.likes : InteractionHistoryType.passes,
      interactionIds: ids.toList(growable: false),
      selectAll: selectAll,
      query: isLike ? _likesQuery : _passesQuery,
      matchFilter: isLike ? _likesFilter : _passesFilter,
    ));
    result.fold(
      (failure) {
        if (isLike) {
          emit(_likesState(
            isBulkRevoking: false,
            actionMessage: failure.message,
            actionSequence: ++_actionSequence,
          ));
        } else {
          emit(_passesState(
            isBulkRevoking: false,
            actionMessage: failure.message,
            actionSequence: ++_actionSequence,
          ));
        }
      },
      (outcome) {
        final revokedIds = outcome.revokedInteractionIds.toSet();
        if (isLike) {
          for (final interaction
              in _allLikes.where((item) => revokedIds.contains(item.id))) {
            AppEvents().notifyInteractionRevoked(interaction.profile.id);
          }
          _allLikes =
              _allLikes.where((item) => !revokedIds.contains(item.id)).toList();
          _likesTotal = (_likesTotal - outcome.revokedCount)
              .clamp(0, _likesTotal)
              .toInt();
          _likesSelectable = (_likesSelectable - outcome.revokedCount)
              .clamp(0, _likesSelectable)
              .toInt();
          _likesSelected = <String>{};
          _likesSelectAll = false;
          emit(_likesState(
            actionMessage:
                LocalizationService.translate('history.revoke_success'),
            actionSequence: ++_actionSequence,
          ));
        } else {
          for (final interaction
              in _allPasses.where((item) => revokedIds.contains(item.id))) {
            AppEvents().notifyInteractionRevoked(interaction.profile.id);
          }
          _allPasses = _allPasses
              .where((item) => !revokedIds.contains(item.id))
              .toList();
          _passesTotal = (_passesTotal - outcome.revokedCount)
              .clamp(0, _passesTotal)
              .toInt();
          _passesSelectable = (_passesSelectable - outcome.revokedCount)
              .clamp(0, _passesSelectable)
              .toInt();
          _passesSelected = <String>{};
          _passesSelectAll = false;
          emit(_passesState(
            actionMessage:
                LocalizationService.translate('history.revoke_success'),
            actionSequence: ++_actionSequence,
          ));
        }
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

  LikesLoaded _likesState({
    bool isBulkRevoking = false,
    String? actionMessage,
    int? actionSequence,
  }) =>
      LikesLoaded(
        likes: _allLikes,
        hasMore: _hasMoreLikes,
        totalCount: _likesTotal,
        selectableCount: _likesSelectable,
        query: _likesQuery,
        matchFilter: _likesFilter,
        selectedIds: Set.unmodifiable(_likesSelected),
        selectAllResults: _likesSelectAll,
        isBulkRevoking: isBulkRevoking,
        actionMessage: actionMessage,
        actionSequence: actionSequence ?? _actionSequence,
      );

  PassesLoaded _passesState({
    bool isBulkRevoking = false,
    String? actionMessage,
    int? actionSequence,
  }) =>
      PassesLoaded(
        passes: _allPasses,
        hasMore: _hasMorePasses,
        totalCount: _passesTotal,
        selectableCount: _passesSelectable,
        query: _passesQuery,
        matchFilter: _passesFilter,
        selectedIds: Set.unmodifiable(_passesSelected),
        selectAllResults: _passesSelectAll,
        isBulkRevoking: isBulkRevoking,
        actionMessage: actionMessage,
        actionSequence: actionSequence ?? _actionSequence,
      );
}
