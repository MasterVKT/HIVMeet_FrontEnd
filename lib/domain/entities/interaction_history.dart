// lib/domain/entities/interaction_history.dart

import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/match.dart';

/// Entité représentant une interaction historique avec un profil
class InteractionHistory extends Equatable {
  /// ID unique de l'interaction
  final String id;

  /// Profil avec lequel l'interaction a eu lieu
  final DiscoveryProfile profile;

  /// Type d'interaction
  final InteractionType type;

  /// Date et heure de l'interaction
  final DateTime timestamp;

  /// Si l'interaction a abouti à un match
  final bool isMatched;

  /// ID du match si applicable
  final String? matchId;

  /// Si l'interaction peut être révoquée
  final bool canRevoke;

  const InteractionHistory({
    required this.id,
    required this.profile,
    required this.type,
    required this.timestamp,
    this.isMatched = false,
    this.matchId,
    this.canRevoke = true,
  });

  @override
  List<Object?> get props => [
        id,
        profile,
        type,
        timestamp,
        isMatched,
        matchId,
        canRevoke,
      ];

  InteractionHistory copyWith({
    String? id,
    DiscoveryProfile? profile,
    InteractionType? type,
    DateTime? timestamp,
    bool? isMatched,
    String? matchId,
    bool? canRevoke,
  }) {
    return InteractionHistory(
      id: id ?? this.id,
      profile: profile ?? this.profile,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isMatched: isMatched ?? this.isMatched,
      matchId: matchId ?? this.matchId,
      canRevoke: canRevoke ?? this.canRevoke,
    );
  }
}

/// Explicit backend filter. `all` never changes meaning when matches exist.
enum InteractionMatchFilter { all, matched, unmatched }

extension InteractionMatchFilterApi on InteractionMatchFilter {
  String get apiValue => switch (this) {
        InteractionMatchFilter.all => 'all',
        InteractionMatchFilter.matched => 'matched',
        InteractionMatchFilter.unmatched => 'unmatched',
      };
}

/// A server-paginated history page. The total is used for the "all results"
/// selection, which must include rows that have not been loaded yet.
class InteractionHistoryPage extends Equatable {
  final List<InteractionHistory> interactions;
  final int totalCount;
  final int selectableCount;
  final bool hasNextPage;

  const InteractionHistoryPage({
    required this.interactions,
    required this.totalCount,
    required this.selectableCount,
    required this.hasNextPage,
  });

  @override
  List<Object?> get props =>
      [interactions, totalCount, selectableCount, hasNextPage];
}

enum InteractionHistoryType { likes, passes }

extension InteractionHistoryTypeApi on InteractionHistoryType {
  String get apiValue => switch (this) {
        InteractionHistoryType.likes => 'likes',
        InteractionHistoryType.passes => 'passes',
      };
}

class BulkRevokeRequest extends Equatable {
  final InteractionHistoryType historyType;
  final List<String> interactionIds;
  final bool selectAll;
  final String query;
  final InteractionMatchFilter matchFilter;

  const BulkRevokeRequest({
    required this.historyType,
    this.interactionIds = const [],
    this.selectAll = false,
    this.query = '',
    this.matchFilter = InteractionMatchFilter.all,
  });

  @override
  List<Object?> get props => [
        historyType,
        interactionIds,
        selectAll,
        query,
        matchFilter,
      ];
}

class BulkRevokeResult extends Equatable {
  final int revokedCount;
  final List<String> revokedInteractionIds;

  const BulkRevokeResult({
    required this.revokedCount,
    required this.revokedInteractionIds,
  });

  @override
  List<Object?> get props => [revokedCount, revokedInteractionIds];
}

/// Type d'interaction utilisateur
enum InteractionType {
  like,
  superLike,
  dislike;

  String get displayName {
    switch (this) {
      case InteractionType.like:
        return 'Like';
      case InteractionType.superLike:
        return 'Super Like';
      case InteractionType.dislike:
        return 'Passé';
    }
  }

  String get iconName {
    switch (this) {
      case InteractionType.like:
        return 'favorite';
      case InteractionType.superLike:
        return 'star';
      case InteractionType.dislike:
        return 'close';
    }
  }
}

/// Statistiques des interactions utilisateur
class InteractionStats extends Equatable {
  final int totalLikes;
  final int totalSuperLikes;
  final int totalDislikes;
  final int totalMatches;
  final double likeToMatchRatio;
  final int totalInteractionsToday;
  final int? totalInteractionsWeek;
  final int dailyLimit;
  final int remainingToday;

  const InteractionStats({
    required this.totalLikes,
    required this.totalSuperLikes,
    required this.totalDislikes,
    required this.totalMatches,
    required this.likeToMatchRatio,
    required this.totalInteractionsToday,
    this.totalInteractionsWeek,
    required this.dailyLimit,
    required this.remainingToday,
  });

  int get totalAllLikes => totalLikes + totalSuperLikes;

  // Getters pour compatibilité avec l'UI
  int get totalInteractions => totalAllLikes + totalDislikes;
  double get matchRate =>
      totalAllLikes > 0 ? (totalMatches / totalAllLikes) * 100 : 0.0;
  int get todayInteractions => totalInteractionsToday;
  int? get weekInteractions => totalInteractionsWeek;

  @override
  List<Object?> get props => [
        totalLikes,
        totalSuperLikes,
        totalDislikes,
        totalMatches,
        likeToMatchRatio,
        totalInteractionsToday,
        totalInteractionsWeek,
        dailyLimit,
        remainingToday,
      ];
}
