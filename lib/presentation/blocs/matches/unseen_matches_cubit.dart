import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:hivmeet/core/kyc/kyc_access_controller.dart';
import 'package:hivmeet/core/realtime/realtime_event.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/usecases/match/get_unseen_match_count.dart';
import 'package:hivmeet/domain/usecases/match/mark_matches_seen.dart';

/// Server-backed badge for matches not yet consulted by this participant.
class UnseenMatchesCubit extends Cubit<int> {
  UnseenMatchesCubit({
    required GetUnseenMatchCount getUnseenMatchCount,
    required MarkMatchesSeen markMatchesSeen,
    required RealtimeEventBus realtimeBus,
    KycAccessController? kycAccess,
  })  : _getUnseenMatchCount = getUnseenMatchCount,
        _markMatchesSeen = markMatchesSeen,
        _realtimeBus = realtimeBus,
        _kycAccess = kycAccess,
        super(0) {
    _subscription = _realtimeBus.events.listen(_onRealtimeEvent);
    _kycAccess?.addListener(_onKycAccessChanged);
  }

  final GetUnseenMatchCount _getUnseenMatchCount;
  final MarkMatchesSeen _markMatchesSeen;
  final RealtimeEventBus _realtimeBus;
  final KycAccessController? _kycAccess;
  StreamSubscription<RealtimeEvent>? _subscription;
  Timer? _debounce;
  int _refreshGeneration = 0;
  bool get _canUseSocialData => _kycAccess?.hasActiveKyc ?? true;

  void _onKycAccessChanged() {
    if (_canUseSocialData) return;
    reset();
    _refreshGeneration++;
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    if (!_canUseSocialData) return;
    switch (event.type) {
      case RealtimeEventType.newMatch:
        // Immediate local signal keeps the tab responsive; the server refresh
        // below remains authoritative if duplicate realtime delivery occurs.
        emit(state + 1);
        _scheduleRefresh();
      case RealtimeEventType.matchRemoved:
      case RealtimeEventType.appResumed:
        _scheduleRefresh();
      case RealtimeEventType.newMessage:
      case RealtimeEventType.conversationRead:
      case RealtimeEventType.conversationHidden:
      case RealtimeEventType.conversationRestored:
      case RealtimeEventType.messageRead:
      case RealtimeEventType.messageReadAlert:
      case RealtimeEventType.messageDelivered:
      case RealtimeEventType.likeReceived:
      case RealtimeEventType.superLikeReceived:
      case RealtimeEventType.subscriptionExpiring:
      case RealtimeEventType.reportResolved:
      case RealtimeEventType.kycVerificationUpdated:
      case RealtimeEventType.subscriptionChanged:
        break;
    }
  }

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), refresh);
  }

  Future<void> refresh() async {
    if (!_canUseSocialData) {
      _onKycAccessChanged();
      return;
    }
    final generation = ++_refreshGeneration;
    final result = await _getUnseenMatchCount(NoParams());
    if (isClosed || generation != _refreshGeneration) return;
    result.fold((_) {}, emit);
  }

  /// Optimistically clears this page's new-match badge, then reconciles with
  /// the response returned by `PUT /matches/seen/`.
  Future<void> markSeen(List<String> matchIds, int localUnseenCount) async {
    if (!_canUseSocialData) {
      _onKycAccessChanged();
      return;
    }
    if (matchIds.isEmpty) return;
    emit((state - localUnseenCount).clamp(0, state).toInt());
    final result = await _markMatchesSeen(MarkMatchesSeenParams(matchIds));
    if (isClosed) return;
    result.fold((_) => refresh(), emit);
  }

  void reset() {
    _debounce?.cancel();
    emit(0);
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    _subscription?.cancel();
    _kycAccess?.removeListener(_onKycAccessChanged);
    return super.close();
  }
}
