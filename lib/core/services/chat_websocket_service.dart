// lib/core/services/chat_websocket_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hivmeet/core/config/app_config.dart';

/// Événements reçus depuis le serveur WebSocket.
enum WsEventType {
  messageCreated,
  messageRead,
  messageDelivered,
  typingIndicator,
  presenceUpdate,
  pong,
  error,
  unknown,

  /// Événement synthétique local (jamais envoyé par le serveur) émis après
  /// une reconnexion automatique réussie, pour signaler au BLoC qu'il doit
  /// resynchroniser son état (messages potentiellement manqués pendant la
  /// coupure).
  reconnected,

  /// Événement synthétique local émis quand la connexion est perdue de
  /// façon non intentionnelle, avant qu'une tentative de reconnexion soit
  /// planifiée.
  disconnected,
}

/// Payload normalisé d'un événement WebSocket entrant.
class WsEvent {
  final WsEventType type;
  final Map<String, dynamic> data;

  const WsEvent({required this.type, required this.data});
}

/// Service WebSocket pour le chat en temps réel.
///
/// Gère la connexion à `{wsBaseUrl}/ws/conversations/{id}/?token={token}`.
/// Expose [events] comme un [Stream] broadcast.
///
/// Cycle de vie :
/// ```dart
/// await service.connect(conversationId: id, token: token);
/// service.events.listen((event) { ... });
/// service.sendTyping(true);
/// service.disconnect();
/// ```
class ChatWebSocketService {
  ChatWebSocketService({@visibleForTesting String? websocketUrl})
      : _websocketUrl = websocketUrl;

  WebSocket? _socket;
  final String? _websocketUrl;
  final _controller = StreamController<WsEvent>.broadcast();

  bool _intentionalClose = false;
  String? _conversationId;

  /// Fournit un token frais à la (re)connexion. Réglé par [connect].
  /// Nécessaire car le JWT expire après 60 min et une reconnexion
  /// automatique après coupure doit repartir avec un token valide plutôt
  /// que de rejouer celui, potentiellement expiré, du premier appel.
  Future<String?> Function()? _tokenProvider;

  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _hadSuccessfulConnection = false;
  static const _maxReconnectDelay = Duration(seconds: 30);
  static const _initialReconnectDelay = Duration(seconds: 1);

  /// Stream des événements entrants (broadcast).
  Stream<WsEvent> get events => _controller.stream;

  bool get isConnected =>
      _socket != null && _socket!.readyState == WebSocket.open;

  /// Connecte à la conversation [conversationId].
  ///
  /// [token] : JWT access token de l'utilisateur courant, utilisé pour
  /// cette tentative de connexion.
  /// [onNeedFreshToken] : callback optionnel invoqué pour obtenir un token
  /// à jour lors des reconnexions automatiques après coupure (le [token]
  /// initial n'est réutilisé que si ce callback est omis, pour compatibilité
  /// avec les appelants existants). Utilise le fallback query-string
  /// `?token=` car les headers WS ne sont pas supportés par tous les
  /// clients Flutter/mobile.
  Future<void> connect({
    required String conversationId,
    required String token,
    Future<String?> Function()? onNeedFreshToken,
  }) async {
    _intentionalClose = false;
    _conversationId = conversationId;
    _tokenProvider = onNeedFreshToken;
    await _connectWith(token);
  }

  Future<void> _connectWith(String token) async {
    final conversationId = _conversationId;
    if (conversationId == null) return;

    final baseWs = _websocketUrl ?? AppConfig.websocketUrl;
    final uri = '$baseWs/ws/conversations/$conversationId/?token=$token';

    if (kDebugMode) {
      debugPrint(
          '[WS] Connecting to $baseWs/ws/conversations/$conversationId/');
    }

    try {
      final socket = await WebSocket.connect(uri);
      socket.pingInterval = const Duration(seconds: 30);
      _socket = socket;

      final wasReconnect = _hadSuccessfulConnection;
      _hadSuccessfulConnection = true;
      _reconnectAttempts = 0;

      _socket!.listen(
        _onRawMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      // Ping initial pour valider la connexion
      _sendRaw({'type': 'ping'});

      if (wasReconnect && !_controller.isClosed) {
        _controller.add(const WsEvent(type: WsEventType.reconnected, data: {}));
      }
    } catch (e) {
      if (!_controller.isClosed) {
        _controller.add(WsEvent(
          type: WsEventType.error,
          data: {
            'message': 'Connection failed: $e',
            'code': 'CONNECTION_FAILED'
          },
        ));
      }
      _scheduleReconnect();
    }
  }

  /// Ferme proprement la connexion WebSocket et annule toute reconnexion
  /// planifiée.
  void disconnect() {
    _intentionalClose = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    _hadSuccessfulConnection = false;
    _socket?.close();
    _socket = null;
  }

  /// Envoie un message texte via WebSocket.
  ///
  /// [clientMessageId] est recommandé pour la déduplication côté serveur.
  void sendTextMessage({
    required String content,
    required String clientMessageId,
  }) {
    _sendRaw({
      'type': 'message.send',
      'content': content,
      'client_message_id': clientMessageId,
    });
  }

  /// Met à jour l'indicateur de frappe.
  void sendTyping(bool isTyping) {
    _sendRaw({'type': isTyping ? 'typing.start' : 'typing.stop'});
  }

  /// Envoie un ping pour maintenir la connexion.
  void sendPing() {
    _sendRaw({'type': 'ping'});
  }

  // ─── Internal ────────────────────────────────────────────────────────────

  void _sendRaw(Map<String, dynamic> payload) {
    if (!isConnected) return;
    try {
      _socket!.add(jsonEncode(payload));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WS] Send error: $e');
      }
    }
  }

  void _onRawMessage(dynamic raw) {
    if (raw is! String) return;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return; // JSON invalide ignoré
    }

    final type = _parseEventType(data['type'] as String? ?? '');
    if (!_controller.isClosed) {
      _controller.add(WsEvent(type: type, data: data));
    }
  }

  void _onError(Object error) {
    if (kDebugMode) {
      debugPrint('[WS] Error: $error');
    }
    if (!_controller.isClosed) {
      _controller.add(WsEvent(
        type: WsEventType.error,
        data: {'message': error.toString(), 'code': 'SOCKET_ERROR'},
      ));
    }
  }

  void _onDone() {
    if (kDebugMode) {
      debugPrint('[WS] Connection closed (intentional: $_intentionalClose)');
    }
    _socket = null;
    if (!_intentionalClose) {
      if (!_controller.isClosed) {
        _controller
            .add(const WsEvent(type: WsEventType.disconnected, data: {}));
      }
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_intentionalClose || _conversationId == null) return;
    _reconnectTimer?.cancel();

    final delay = _initialReconnectDelay * (1 << _reconnectAttempts);
    final cappedDelay = delay > _maxReconnectDelay ? _maxReconnectDelay : delay;
    _reconnectAttempts++;

    if (kDebugMode) {
      debugPrint(
          '[WS] Reconnecting in ${cappedDelay.inSeconds}s (attempt $_reconnectAttempts)');
    }

    _reconnectTimer = Timer(cappedDelay, () async {
      if (_intentionalClose || _conversationId == null) return;
      final provider = _tokenProvider;
      final freshToken = provider != null ? await provider() : null;
      if (_intentionalClose || _conversationId == null) return;
      if (freshToken == null) {
        // Pas de token disponible (utilisateur déconnecté entre-temps) —
        // retente plus tard plutôt que d'abandonner silencieusement.
        _scheduleReconnect();
        return;
      }
      await _connectWith(freshToken);
    });
  }

  WsEventType _parseEventType(String raw) {
    switch (raw) {
      case 'message.created':
        return WsEventType.messageCreated;
      case 'message.read':
        return WsEventType.messageRead;
      case 'message.delivered':
        return WsEventType.messageDelivered;
      case 'typing.indicator':
        return WsEventType.typingIndicator;
      case 'presence.update':
        return WsEventType.presenceUpdate;
      case 'pong':
        return WsEventType.pong;
      case 'error':
        return WsEventType.error;
      default:
        return WsEventType.unknown;
    }
  }

  /// Libère les ressources. Appeler dans `dispose()` du BLoC.
  void dispose() {
    _intentionalClose = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _socket?.close();
    _socket = null;
    _controller.close();
  }
}
