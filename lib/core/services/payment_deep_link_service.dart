import 'dart:async';

import 'package:app_links/app_links.dart';

enum PaymentReturnKind { success, cancelled, failed }

class PaymentReturnEvent {
  final PaymentReturnKind kind;
  final int sequence;

  const PaymentReturnEvent({required this.kind, required this.sequence});
}

/// Accepts only the static return URI registered for the MyCoolPay flow.
///
/// The signal is deliberately UX-only: payment confirmation still comes from
/// the authenticated Django status endpoint.
class PaymentDeepLinkService {
  final AppLinks _appLinks;
  final StreamController<PaymentReturnEvent> _controller =
      StreamController<PaymentReturnEvent>.broadcast();

  StreamSubscription<Uri>? _subscription;
  PaymentReturnEvent? _latest;
  String? _lastAcceptedUri;
  DateTime? _lastAcceptedAt;
  int _sequence = 0;

  PaymentDeepLinkService(this._appLinks);

  Stream<PaymentReturnEvent> get events => _controller.stream;

  Future<void> initialize() async {
    if (_subscription != null) return;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _accept(initial);
    } catch (_) {
      // Platform deep-link support may be unavailable in unit/desktop runs.
    }

    _subscription = _appLinks.uriLinkStream.listen(
      _accept,
      onError: (_) {
        // A malformed external URI must not disturb the authenticated session.
      },
    );
  }

  PaymentReturnEvent? takeLatest() {
    final value = _latest;
    _latest = null;
    return value;
  }

  void markHandled(PaymentReturnEvent event) {
    if (_latest?.sequence == event.sequence) _latest = null;
  }

  void _accept(Uri uri) {
    final kind = parse(uri);
    if (kind == null) return;

    final now = DateTime.now();
    final uriText = uri.toString();
    if (_lastAcceptedUri == uriText &&
        _lastAcceptedAt != null &&
        now.difference(_lastAcceptedAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastAcceptedUri = uriText;
    _lastAcceptedAt = now;

    final event = PaymentReturnEvent(kind: kind, sequence: ++_sequence);
    _latest = event;
    if (!_controller.isClosed) _controller.add(event);
  }

  static PaymentReturnKind? parse(Uri uri) {
    if (uri.scheme.toLowerCase() != 'hivmeet' ||
        uri.host.toLowerCase() != 'payment' ||
        uri.path != '/result' ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        uri.queryParametersAll.length != 1 ||
        !uri.queryParametersAll.containsKey('status') ||
        uri.queryParametersAll['status']?.length != 1) {
      return null;
    }

    switch (uri.queryParameters['status']?.toLowerCase()) {
      case 'success':
        return PaymentReturnKind.success;
      case 'cancelled':
        return PaymentReturnKind.cancelled;
      case 'failed':
        return PaymentReturnKind.failed;
      default:
        return null;
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}
