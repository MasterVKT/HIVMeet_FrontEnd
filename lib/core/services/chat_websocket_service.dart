// lib/core/services/chat_websocket_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hivmeet/core/config/app_config.dart';

/// Événements reçus depuis le serveur WebSocket.
enum WsEventType {
  messageCreated,
  typingIndicator,
  presenceUpdate,
  pong,
  error,
  unknown,
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
  WebSocket? _socket;
  final _controller = StreamController<WsEvent>.broadcast();

  bool _intentionalClose = false;

  /// Stream des événements entrants (broadcast).
  Stream<WsEvent> get events => _controller.stream;

  bool get isConnected =>
      _socket != null && _socket!.readyState == WebSocket.open;

  /// Connecte à la conversation [conversationId].
  ///
  /// [token] : JWT access token de l'utilisateur courant.
  /// Utilise le fallback query-string `?token=` car les headers WS
  /// ne sont pas supportés par tous les clients Flutter/mobile.
  Future<void> connect({
    required String conversationId,
    required String token,
  }) async {
    _intentionalClose = false;

    final baseWs = AppConfig.websocketUrl;
    final uri = '$baseWs/ws/conversations/$conversationId/?token=$token';

    if (kDebugMode) {
      debugPrint(
          '[WS] Connecting to $baseWs/ws/conversations/$conversationId/');
    }

    try {
      _socket = await WebSocket.connect(uri);
      _socket!.listen(
        _onRawMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      // Ping initial pour valider la connexion
      _sendRaw({'type': 'ping'});
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
    }
  }

  /// Ferme proprement la connexion WebSocket.
  void disconnect() {
    _intentionalClose = true;
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
  }

  WsEventType _parseEventType(String raw) {
    switch (raw) {
      case 'message.created':
        return WsEventType.messageCreated;
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
    _socket?.close();
    _socket = null;
    _controller.close();
  }
}
