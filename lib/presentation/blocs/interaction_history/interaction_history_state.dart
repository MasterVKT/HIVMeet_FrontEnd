import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/interaction_history.dart';

abstract class InteractionHistoryState extends Equatable {
  const InteractionHistoryState();

  @override
  List<Object?> get props => [];
}

class InteractionHistoryInitial extends InteractionHistoryState {}

class LikesLoading extends InteractionHistoryState {}

class LikesLoaded extends InteractionHistoryState {
  final List<InteractionHistory> likes;
  final bool hasMore;
  final bool isLoadingMore;
  final int totalCount;
  final int selectableCount;
  final String query;
  final InteractionMatchFilter matchFilter;
  final Set<String> selectedIds;
  final bool selectAllResults;
  final bool isBulkRevoking;
  final String? actionMessage;
  final int actionSequence;

  const LikesLoaded({
    required this.likes,
    required this.hasMore,
    required this.totalCount,
    required this.selectableCount,
    this.isLoadingMore = false,
    this.query = '',
    this.matchFilter = InteractionMatchFilter.all,
    this.selectedIds = const {},
    this.selectAllResults = false,
    this.isBulkRevoking = false,
    this.actionMessage,
    this.actionSequence = 0,
  });

  int get selectedCount =>
      selectAllResults ? selectableCount : selectedIds.length;

  LikesLoaded copyWith({
    List<InteractionHistory>? likes,
    bool? hasMore,
    bool? isLoadingMore,
    int? totalCount,
    int? selectableCount,
    String? query,
    InteractionMatchFilter? matchFilter,
    Set<String>? selectedIds,
    bool? selectAllResults,
    bool? isBulkRevoking,
    String? actionMessage,
    int? actionSequence,
    bool clearActionMessage = false,
  }) =>
      LikesLoaded(
        likes: likes ?? this.likes,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        totalCount: totalCount ?? this.totalCount,
        selectableCount: selectableCount ?? this.selectableCount,
        query: query ?? this.query,
        matchFilter: matchFilter ?? this.matchFilter,
        selectedIds: selectedIds ?? this.selectedIds,
        selectAllResults: selectAllResults ?? this.selectAllResults,
        isBulkRevoking: isBulkRevoking ?? this.isBulkRevoking,
        actionMessage:
            clearActionMessage ? null : actionMessage ?? this.actionMessage,
        actionSequence: actionSequence ?? this.actionSequence,
      );

  @override
  List<Object?> get props => [
        likes,
        hasMore,
        isLoadingMore,
        totalCount,
        selectableCount,
        query,
        matchFilter,
        selectedIds,
        selectAllResults,
        isBulkRevoking,
        actionMessage,
        actionSequence,
      ];
}

class PassesLoading extends InteractionHistoryState {}

class PassesLoaded extends InteractionHistoryState {
  final List<InteractionHistory> passes;
  final bool hasMore;
  final bool isLoadingMore;
  final int totalCount;
  final int selectableCount;
  final String query;
  final InteractionMatchFilter matchFilter;
  final Set<String> selectedIds;
  final bool selectAllResults;
  final bool isBulkRevoking;
  final String? actionMessage;
  final int actionSequence;

  const PassesLoaded({
    required this.passes,
    required this.hasMore,
    required this.totalCount,
    required this.selectableCount,
    this.isLoadingMore = false,
    this.query = '',
    this.matchFilter = InteractionMatchFilter.all,
    this.selectedIds = const {},
    this.selectAllResults = false,
    this.isBulkRevoking = false,
    this.actionMessage,
    this.actionSequence = 0,
  });

  int get selectedCount =>
      selectAllResults ? selectableCount : selectedIds.length;

  PassesLoaded copyWith({
    List<InteractionHistory>? passes,
    bool? hasMore,
    bool? isLoadingMore,
    int? totalCount,
    int? selectableCount,
    String? query,
    InteractionMatchFilter? matchFilter,
    Set<String>? selectedIds,
    bool? selectAllResults,
    bool? isBulkRevoking,
    String? actionMessage,
    int? actionSequence,
    bool clearActionMessage = false,
  }) =>
      PassesLoaded(
        passes: passes ?? this.passes,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        totalCount: totalCount ?? this.totalCount,
        selectableCount: selectableCount ?? this.selectableCount,
        query: query ?? this.query,
        matchFilter: matchFilter ?? this.matchFilter,
        selectedIds: selectedIds ?? this.selectedIds,
        selectAllResults: selectAllResults ?? this.selectAllResults,
        isBulkRevoking: isBulkRevoking ?? this.isBulkRevoking,
        actionMessage:
            clearActionMessage ? null : actionMessage ?? this.actionMessage,
        actionSequence: actionSequence ?? this.actionSequence,
      );

  @override
  List<Object?> get props => [
        passes,
        hasMore,
        isLoadingMore,
        totalCount,
        selectableCount,
        query,
        matchFilter,
        selectedIds,
        selectAllResults,
        isBulkRevoking,
        actionMessage,
        actionSequence,
      ];
}

class StatsLoading extends InteractionHistoryState {}

class StatsLoaded extends InteractionHistoryState {
  final InteractionStats stats;

  const StatsLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

class InteractionHistoryError extends InteractionHistoryState {
  final String message;

  const InteractionHistoryError({required this.message});

  @override
  List<Object?> get props => [message];
}
