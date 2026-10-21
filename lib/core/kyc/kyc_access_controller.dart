import 'dart:async';

import 'package:flutter/foundation.dart';

enum KycAccessState { unknown, active, restricted }

abstract class KycMediaCacheCleaner {
  Future<void> clearPrivateMedia();
}

/// Global, non-sensitive access signal consumed by the navigation guard.
/// It deliberately stores no document, reason, identifier or challenge.
class KycAccessController extends ChangeNotifier {
  final KycMediaCacheCleaner _mediaCacheCleaner;
  KycAccessState _state = KycAccessState.unknown;

  KycAccessController(this._mediaCacheCleaner);

  KycAccessState get state => _state;
  bool get hasActiveKyc => _state == KycAccessState.active;

  void markActive(bool active) {
    final next = active ? KycAccessState.active : KycAccessState.restricted;
    _set(next);
  }

  void requireVerification() => _set(KycAccessState.restricted);

  void reset() => _set(KycAccessState.unknown);

  void _set(KycAccessState next) {
    if (_state == next) return;
    final wasActive = _state == KycAccessState.active;
    _state = next;
    if (wasActive && next != KycAccessState.active) {
      unawaited(_mediaCacheCleaner.clearPrivateMedia());
    }
    notifyListeners();
  }
}
