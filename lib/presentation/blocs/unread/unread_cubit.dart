// lib/presentation/blocs/unread/unread_cubit.dart

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:hivmeet/core/kyc/kyc_access_controller.dart';
import 'package:hivmeet/core/realtime/realtime_event.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/usecases/message/get_unread_count.dart';

/// Compteur global de messages non lus, source unique de vérité pour le
/// badge de l'onglet Messages (visible depuis tous les écrans, contrairement
/// au `totalUnreadCount` de `ConversationsBloc` qui n'existe que le temps où
/// `ConversationsPage` est montée).
///
/// Se rafraîchit depuis le serveur (débouncé) sur tout événement temps réel
/// pertinent — nouveau message, conversation marquée lue, retour au premier
/// plan de l'app — plutôt que d'incrémenter/décrémenter localement, pour
/// rester en accord avec `unread_count_for_me` qui fait autorité côté
/// serveur.
class UnreadCubit extends Cubit<int> {
  UnreadCubit({
    required GetUnreadCount getUnreadCount,
    required RealtimeEventBus realtimeBus,
    KycAccessController? kycAccess,
  })  : _getUnreadCount = getUnreadCount,
        _realtimeBus = realtimeBus,
        _kycAccess = kycAccess,
        super(0) {
    _sub = _realtimeBus.events.listen(_onRealtimeEvent);
    _kycAccess?.addListener(_onKycAccessChanged);
  }

  final GetUnreadCount _getUnreadCount;
  final RealtimeEventBus _realtimeBus;
  final KycAccessController? _kycAccess;
  StreamSubscription<RealtimeEvent>? _sub;
  Timer? _debounce;
  int _refreshGeneration = 0;

  static const _debounceDelay = Duration(milliseconds: 800);
  bool get _canUseSocialData => _kycAccess?.hasActiveKyc ?? true;

  void _onKycAccessChanged() {
    if (_canUseSocialData) return;
    _debounce?.cancel();
    _refreshGeneration++;
    if (!isClosed && state != 0) emit(0);
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    if (!_canUseSocialData) return;
    switch (event.type) {
      case RealtimeEventType.newMessage:
      case RealtimeEventType.conversationRead:
      case RealtimeEventType.conversationRestored:
      case RealtimeEventType.appResumed:
        _scheduleRefresh();
      case RealtimeEventType.conversationHidden:
        final delta = event.unreadCountDelta ?? 0;
        if (delta != 0) {
          emit((state + delta).clamp(0, 1 << 31).toInt());
        }
        _scheduleRefresh();
      case RealtimeEventType.newMatch:
      case RealtimeEventType.matchRemoved:
      case RealtimeEventType.messageRead:
      case RealtimeEventType.messageReadAlert:
      case RealtimeEventType.messageDelivered:
      case RealtimeEventType.likeReceived:
      case RealtimeEventType.superLikeReceived:
      case RealtimeEventType.subscriptionExpiring:
      case RealtimeEventType.reportResolved:
      case RealtimeEventType.kycVerificationUpdated:
      case RealtimeEventType.subscriptionChanged:
        // Sans impact sur le compteur de messages non lus.
        break;
    }
  }

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, refresh);
  }

  /// Recharge le total exact depuis le serveur via l'endpoint dédié
  /// `GET /api/v1/conversations/unread-count/`, qui agrège côté serveur
  /// toutes les conversations actives non masquées — sans limitation de
  /// pagination (contrairement à une somme sur la première page de
  /// `getConversations` qui plafonnerait à 20 conversations).
  Future<void> refresh() async {
    if (!_canUseSocialData) {
      _onKycAccessChanged();
      return;
    }
    final generation = ++_refreshGeneration;
    final result = await _getUnreadCount(NoParams());
    if (generation != _refreshGeneration || isClosed) return;

    result.fold(
      (_) {
        // Échec silencieux : le badge garde sa dernière valeur connue.
      },
      (count) {
        if (!isClosed) emit(count);
      },
    );
  }

  void reset() {
    _debounce?.cancel();
    _refreshGeneration++;
    if (!isClosed && state != 0) emit(0);
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    _sub?.cancel();
    _kycAccess?.removeListener(_onKycAccessChanged);
    return super.close();
  }
}
