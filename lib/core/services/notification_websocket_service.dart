// lib/core/services/notification_websocket_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../realtime/realtime_event.dart';
import '../realtime/realtime_event_bus.dart';
import 'authentication_service.dart';

/// Service WebSocket dédié aux notifications utilisateur (`/ws/notifications/`).
///
/// À la différence de [ChatWebSocketService] (une connexion par conversation
/// ouverte), ce service maintient UNE connexion pour toute la durée de vie
/// de la session, alimentée par le groupe serveur `user_{id}`. Ce groupe
/// diffuse `new_match` / `like` / `super_like` ainsi que
/// `new_message` / `message_read` / `message_delivered` (et
/// `incoming_call` / `call_update`, non consommés pour l'instant). Les
/// événements publiés ici sont un sous-ensemble de [RealtimeEventBus] ;
/// le pont FCM (`NotificationService`) complète `newMessage` comme second
/// chemin de livraison.
///
/// Utilise `dart:io WebSocket` (pas `package:web_socket_channel`, qui n'est
/// qu'une dépendance transitive du projet) pour rester cohérent avec
/// [ChatWebSocketService] — au prix du support Flutter Web, déjà absent de
/// l'implémentation existante.
class NotificationWebSocketService {
  NotificationWebSocketService(
    this._authService,
    this._bus, {
    @visibleForTesting String? websocketUrl,
  }) : _websocketUrl = websocketUrl;

  final AuthenticationService _authService;
  final RealtimeEventBus _bus;
  final String? _websocketUrl;

  WebSocket? _socket;
  StreamSubscription? _socketSub;
  bool _intentionalClose = false;
  bool _isConnecting = false;
  bool _suspended = false;

  Timer? _reconnectTimer;
  Timer? _presenceHeartbeatTimer;
  int _reconnectAttempts = 0;
  static const _maxReconnectDelay = Duration(seconds: 30);
  static const _initialReconnectDelay = Duration(seconds: 1);

  bool get isConnected =>
      _socket != null && _socket!.readyState == WebSocket.open;
  bool get isConnecting => _isConnecting;

  /// Connecte au canal de notifications utilisateur.
  ///
  /// Récupère lui-même un token frais à chaque appel (y compris lors des
  /// reconnexions automatiques) via [AuthenticationService.getAccessToken],
  /// qui gère le refresh transparent — nécessaire car le JWT expire après
  /// 60 minutes et le socket n'a pas de refresh in-band.
  ///
  /// Idempotent : un appel alors qu'une connexion est déjà active ou en
  /// cours ne fait rien. C'est nécessaire car `main.dart` déclenche
  /// `connect()` depuis un `BlocListener<AuthBlocSimple>` qui peut
  /// re-émettre `Authenticated` plusieurs fois pour une même session.
  Future<void> connect() async {
    if (isConnected || _isConnecting) return;
    // Verrouille immédiatement, avant tout `await`, pour fermer la fenêtre
    // de course entre appelants concurrents (auth listener, `resume()`,
    // timer de reconnexion) qui liraient sinon tous `_isConnecting == false`
    // avant que le premier appel n'ait eu la main.
    _isConnecting = true;

    final token = await _authService.getAccessToken();
    if (token == null) {
      _isConnecting = false;
      if (kDebugMode) {
        debugPrint('[WS Notifications] No access token, skip connect');
      }
      return;
    }

    _intentionalClose = false;

    final baseWs = _websocketUrl ?? AppConfig.websocketUrl;
    final uri = '$baseWs/ws/notifications/?token=$token';

    if (kDebugMode) {
      debugPrint('[WS Notifications] Connecting to $baseWs/ws/notifications/');
    }

    try {
      final socket = await WebSocket.connect(uri);
      socket.pingInterval = const Duration(seconds: 30);
      _socket = socket;
      _isConnecting = false;
      _reconnectAttempts = 0;

      _socketSub = socket.listen(
        _onRawMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _startPresenceHeartbeat();
    } catch (e) {
      _isConnecting = false;
      if (kDebugMode) {
        debugPrint(
          '[WS Notifications] Connection failed (${e.runtimeType})',
        );
      }
      _scheduleReconnect();
    }
  }

  /// Ferme proprement la connexion et annule toute tentative de reconnexion.
  void disconnect() {
    _intentionalClose = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = null;
    _socketSub?.cancel();
    _socketSub = null;
    _socket?.close();
    _socket = null;
    _isConnecting = false;
  }

  /// Suspend la connexion sans réinitialiser le compteur de backoff ni
  /// marquer la fermeture comme intentionnelle — appelé quand l'app passe
  /// en arrière-plan. [resume] rouvre normalement.
  void suspend() {
    if (_suspended) return;
    _suspended = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = null;
    _socketSub?.cancel();
    _socketSub = null;
    _socket?.close();
    _socket = null;
  }

  /// Reconnecte après un [suspend] (retour au premier plan de l'app).
  Future<void> resume() async {
    if (!_suspended) return;
    _suspended = false;
    await connect();
  }

  void _startPresenceHeartbeat() {
    _presenceHeartbeatTimer?.cancel();
    _sendPresenceHeartbeat();
    _presenceHeartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _sendPresenceHeartbeat(),
    );
  }

  void _sendPresenceHeartbeat() {
    if (!isConnected) return;
    try {
      _socket!.add(jsonEncode({'type': 'presence.heartbeat'}));
    } catch (_) {
      // The socket lifecycle callback handles reconnects.
    }
  }

  void _onRawMessage(dynamic raw) {
    if (raw is! String) return;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final type = data['type'] as String?;
    if (kDebugMode) {
      debugPrint('[WS Notifications] Received: $type');
    }

    // Payload à clés plates (voir docs/MESSAGES_BACKEND_WEBSOCKET_FRONTEND.md
    // et notifications/consumers.py) — pas de wrapper data['data'].
    switch (type) {
      case 'new_match':
        _bus.publish(RealtimeEvent(
          type: RealtimeEventType.newMatch,
          source: RealtimeSource.websocket,
          matchId: data['match_id'] as String?,
          fromUserId: data['matched_user_id'] as String?,
          notificationId: data['notification_id'] as String?,
        ));
        break;
      case 'match_removed':
        _bus.publish(RealtimeEvent(
          type: RealtimeEventType.matchRemoved,
          source: RealtimeSource.websocket,
          matchId: data['match_id'] as String?,
        ));
        break;
      case 'like':
        _bus.publish(RealtimeEvent(
          type: RealtimeEventType.likeReceived,
          source: RealtimeSource.websocket,
          fromUserId: data['from_user_id'] as String?,
          notificationId: data['notification_id'] as String?,
        ));
        break;
      case 'super_like':
        _bus.publish(RealtimeEvent(
          type: RealtimeEventType.superLikeReceived,
          source: RealtimeSource.websocket,
          fromUserId: data['from_user_id'] as String?,
          notificationId: data['notification_id'] as String?,
        ));
        break;
      case 'new_message':
        _bus.publish(RealtimeEvent(
          type: RealtimeEventType.newMessage,
          source: RealtimeSource.websocket,
          conversationId: data['conversation_id'] as String?,
          fromUserId: data['from_user_id'] as String?,
          senderName: data['sender_name'] as String?,
          preview: data['preview'] as String?,
          messageId: data['message_id'] as String?,
          notificationId: data['notification_id'] as String?,
        ));
        break;
      case 'message_read':
        final notificationId = data['notification_id'] as String?;
        if (notificationId != null && notificationId.isNotEmpty) {
          _bus.publish(RealtimeEvent(
            type: RealtimeEventType.messageReadAlert,
            source: RealtimeSource.websocket,
            conversationId: data['conversation_id'] as String?,
            fromUserId: data['reader_id'] as String?,
            readerName: data['reader_name'] as String?,
            messageId: data['representative_message_id'] as String?,
            messageCount: int.tryParse(data['message_count']?.toString() ?? ''),
            readAt: data['read_at'] as String?,
            notificationId: notificationId,
          ));
          break;
        }
        _bus.publish(RealtimeEvent(
          type: RealtimeEventType.messageRead,
          source: RealtimeSource.websocket,
          conversationId: data['conversation_id'] as String?,
          fromUserId: data['reader_id'] as String?,
        ));
        break;
      case 'message_delivered':
        _bus.publish(RealtimeEvent(
          type: RealtimeEventType.messageDelivered,
          source: RealtimeSource.websocket,
          conversationId: data['conversation_id'] as String?,
        ));
        break;
      case 'subscription_expiring':
        _bus.publish(RealtimeEvent(
          type: RealtimeEventType.subscriptionExpiring,
          source: RealtimeSource.websocket,
          notificationId: data['notification_id'] as String?,
          daysRemaining: int.tryParse(data['days_remaining'] as String? ?? ''),
          expiryDate: data['expiry_date'] as String?,
        ));
        break;
      case 'report_resolved':
        _bus.publish(RealtimeEvent(
          type: RealtimeEventType.reportResolved,
          source: RealtimeSource.websocket,
          notificationId: data['notification_id'] as String?,
          reportId: data['report_id'] as String?,
          reportStatus: data['status'] as String?,
          resolutionSummary: data['resolution_summary'] as String?,
        ));
        break;
      case null:
      default:
        // Type inconnu ou absent — ignoré silencieusement.
        break;
    }
  }

  void _onError(Object error) {
    if (kDebugMode) {
      debugPrint('[WS Notifications] Error (${error.runtimeType})');
    }
  }

  void _onDone() {
    if (kDebugMode) {
      debugPrint(
          '[WS Notifications] Connection closed (intentional: $_intentionalClose)');
    }
    _socket = null;
    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = null;
    if (!_intentionalClose && !_suspended) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_intentionalClose || _suspended) return;
    _reconnectTimer?.cancel();

    // `_reconnectAttempts` n'est pas borné (utile pour les logs), mais ne
    // doit jamais servir tel quel d'exposant de décalage binaire : au-delà
    // du décalage 63 `1 << n` déborde silencieusement en Dart et redevient
    // 0, ce qui fait retomber le délai à `Duration.zero` et déclenche une
    // boucle de reconnexion serrée. Un exposant plafonné à 10 (1024x le
    // délai initial) dépasse déjà largement le plafond de 30 s ci-dessous.
    final exponent = _reconnectAttempts.clamp(0, 10);
    final delay = _initialReconnectDelay * (1 << exponent);
    final cappedDelay = delay > _maxReconnectDelay ? _maxReconnectDelay : delay;
    _reconnectAttempts++;

    if (kDebugMode) {
      debugPrint(
          '[WS Notifications] Reconnecting in ${cappedDelay.inSeconds}s (attempt $_reconnectAttempts)');
    }

    _reconnectTimer = Timer(cappedDelay, () {
      if (!_intentionalClose && !_suspended) connect();
    });
  }

  void dispose() {
    disconnect();
  }
}
