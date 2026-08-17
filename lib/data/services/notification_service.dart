import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hivmeet/core/config/routes.dart';
import 'package:hivmeet/core/realtime/realtime_event.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/data/datasources/remote/auth_api.dart';
import 'package:hivmeet/data/services/notifications_local_store.dart';
import 'package:hivmeet/domain/entities/app_notification.dart';
import 'package:hivmeet/domain/entities/message.dart';

// Top-level background message handler (separate isolate — no DI access)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are stored when the app resumes via onMessageOpenedApp.
  // Nothing to do in the isolate itself.
}

class NotificationService {
  final FirebaseMessaging _messaging;
  final AuthApi _authApi;
  final NotificationsLocalStore _store;
  final RealtimeEventBus _realtimeBus;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _sessionActive = false;
  int _sessionGeneration = 0;
  String? _currentToken;
  String? _registeredToken;
  Future<void>? _tokenRegistrationInFlight;

  NotificationService(
    this._messaging,
    this._authApi,
    this._store,
    this._realtimeBus,
  );

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Register the background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission
    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // iOS foreground notification options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Local notifications setup
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Get + register FCM token
    await registerTokenWithBackend();

    // Token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _currentToken = newToken;
      if (_sessionActive) {
        _registerToken(newToken, sessionGeneration: _sessionGeneration);
      }
    });

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background/terminated → app opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // App launched from terminated state via notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      await _handleBackgroundMessage(initial);
    }
  }

  /// Active ou désactive la réception des notifications pour la session
  /// authentifiée courante. Une livraison FCM peut arriver juste après un
  /// logout : elle ne doit ni être persistée, ni réafficher un badge pour
  /// l'utilisateur qui vient de quitter l'application.
  void setSessionActive(bool active) {
    if (_sessionActive == active) return;
    _sessionActive = active;
    _sessionGeneration++;
    if (!active) _registeredToken = null;
  }

  Future<void> registerTokenWithBackend() async {
    final sessionGeneration = _sessionGeneration;
    if (!_sessionActive) return;
    try {
      final token = await _messaging.getToken();
      if (token == null ||
          !_sessionActive ||
          sessionGeneration != _sessionGeneration) {
        return;
      }
      _currentToken = token;
      await _registerToken(token, sessionGeneration: sessionGeneration);
    } catch (_) {
      // Not fatal — app works without push
    }
  }

  Future<void> removeTokenFromBackend() async {
    final token = _currentToken;
    if (token == null) return;
    try {
      await _authApi.removeFCMToken(fcmToken: token);
      _currentToken = null;
    } catch (_) {}
  }

  Future<void> _registerToken(
    String token, {
    required int sessionGeneration,
  }) async {
    if (!_sessionActive || sessionGeneration != _sessionGeneration) return;
    if (_registeredToken == token) return;
    final inFlight = _tokenRegistrationInFlight;
    if (inFlight != null) return inFlight;
    _tokenRegistrationInFlight = _sendTokenRegistration(
      token,
      sessionGeneration,
    );
    try {
      await _tokenRegistrationInFlight;
    } finally {
      _tokenRegistrationInFlight = null;
    }
  }

  Future<void> _sendTokenRegistration(
    String token,
    int sessionGeneration,
  ) async {
    if (!_sessionActive || sessionGeneration != _sessionGeneration) return;
    try {
      final platform = _platformName();
      await _authApi.registerFCMToken(
        fcmToken: token,
        deviceType: platform,
      );
      if (_sessionActive && sessionGeneration == _sessionGeneration) {
        _registeredToken = token;
      }
    } catch (_) {
      // Not fatal; a later registration or token refresh may retry.
    }
  }

  String _platformName() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final sessionGeneration = _sessionGeneration;
    if (!_sessionActive) return;
    final notification = _buildAppNotification(message);
    await _store.add(notification);
    if (!_sessionActive || sessionGeneration != _sessionGeneration) return;
    _publishRealtimeEvent(message.data);

    _showLocalNotification(
      title: message.notification?.title ?? notification.title,
      body: message.notification?.body ?? notification.body,
      payload: _payloadFromData(message.data),
    );
  }

  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    final sessionGeneration = _sessionGeneration;
    if (!_sessionActive) return;
    final notification = _buildAppNotification(message);
    await _store.add(notification);
    if (!_sessionActive || sessionGeneration != _sessionGeneration) return;
    _publishRealtimeEvent(message.data);
    _navigateFromData(message.data);
  }

  /// Relaie un push FCM sur [RealtimeEventBus], selon le même contrat de
  /// clés que `notifications/payloads.py` côté backend (`type`,
  /// `conversation_id`, `message_id`, `from_user_id`, `body` comme aperçu).
  ///
  /// `new_message` arrive désormais par ce canal FCM ET par le WebSocket
  /// `/ws/notifications/` — le bus déduplique les seuls types qui portent un
  /// `conversationId` (`new_message`), les autres sont simplement reçus
  /// deux fois sans effet indésirable (`ConversationsBloc` les traite tous
  /// comme un simple déclencheur de réconciliation idempotente).
  void _publishRealtimeEvent(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'new_message':
        _realtimeBus.publish(RealtimeEvent(
          type: RealtimeEventType.newMessage,
          source: RealtimeSource.fcm,
          conversationId: data['conversation_id'] as String?,
          fromUserId: data['from_user_id'] as String?,
          preview: data['body'] as String?,
          messageId: data['message_id'] as String?,
          notificationId: data['notification_id'] as String?,
        ));
        break;
      case 'new_match':
        _realtimeBus.publish(RealtimeEvent(
          type: RealtimeEventType.newMatch,
          source: RealtimeSource.fcm,
          matchId: data['match_id'] as String?,
          fromUserId: data['from_user_id'] as String?,
          notificationId: data['notification_id'] as String?,
        ));
        break;
      case 'like':
        _realtimeBus.publish(RealtimeEvent(
          type: RealtimeEventType.likeReceived,
          source: RealtimeSource.fcm,
          fromUserId: data['from_user_id'] as String?,
          notificationId: data['notification_id'] as String?,
        ));
        break;
      case 'super_like':
        _realtimeBus.publish(RealtimeEvent(
          type: RealtimeEventType.superLikeReceived,
          source: RealtimeSource.fcm,
          fromUserId: data['from_user_id'] as String?,
          notificationId: data['notification_id'] as String?,
        ));
        break;
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    final parts = payload.split('|');
    final type = parts.isNotEmpty ? parts[0] : '';
    final conversationId = parts.length > 1 ? parts[1] : '';
    final fromUserId = parts.length > 2 ? parts[2] : '';
    final senderName = parts.length > 3 ? Uri.decodeComponent(parts[3]) : '';
    _navigateFromType(
      type,
      conversationId,
      fromUserId: fromUserId,
      senderName: senderName,
    );
  }

  AppNotification _buildAppNotification(RemoteMessage message) {
    final data = message.data;
    final type = _typeFromData(data);
    final id = _stableNotificationId(data, type);
    final title = message.notification?.title ??
        data['title'] as String? ??
        _localizedDefaultTitle(type);
    final body = message.notification?.body ?? data['body'] as String? ?? '';

    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      data: Map<String, dynamic>.from(data),
      createdAt: DateTime.now(),
    );
  }

  AppNotificationType _typeFromData(Map<String, dynamic> data) {
    switch (data['type'] as String?) {
      case 'new_match':
        return AppNotificationType.newMatch;
      case 'new_message':
        return AppNotificationType.newMessage;
      case 'like':
        return AppNotificationType.like;
      case 'super_like':
        return AppNotificationType.superLike;
      default:
        return AppNotificationType.system;
    }
  }

  String _stableNotificationId(
    Map<String, dynamic> data,
    AppNotificationType type,
  ) {
    final messageId = data['message_id'] as String?;
    if (type == AppNotificationType.newMessage &&
        messageId != null &&
        messageId.isNotEmpty) {
      return 'message_$messageId';
    }

    final matchId = data['match_id'] as String?;
    if (type == AppNotificationType.newMatch &&
        matchId != null &&
        matchId.isNotEmpty) {
      return 'match_$matchId';
    }

    final fromUserId = data['from_user_id'] as String?;
    if ((type == AppNotificationType.like ||
            type == AppNotificationType.superLike) &&
        fromUserId != null &&
        fromUserId.isNotEmpty) {
      final prefix =
          type == AppNotificationType.superLike ? 'super_like' : 'like';
      return '${prefix}_$fromUserId';
    }

    final notificationId = data['notification_id'] as String?;
    if (notificationId != null && notificationId.isNotEmpty) {
      return notificationId;
    }

    final conversationId = data['conversation_id'] as String?;
    if (type == AppNotificationType.newMessage &&
        conversationId != null &&
        conversationId.isNotEmpty) {
      return 'message_$conversationId';
    }

    return '${type.name}_${DateTime.now().microsecondsSinceEpoch}';
  }

  String _defaultTitle(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.newMatch:
        return 'Nouveau match !';
      case AppNotificationType.newMessage:
        return 'Nouveau message';
      case AppNotificationType.like:
        return 'Quelqu\'un vous a liké';
      case AppNotificationType.superLike:
        return 'Vous avez reçu un super like !';
      case AppNotificationType.system:
        return 'HIVMeet';
    }
  }

  String _localizedDefaultTitle(AppNotificationType type) {
    final key = switch (type) {
      AppNotificationType.newMatch => 'notifications.new_match_title',
      AppNotificationType.newMessage => 'notifications.new_message_title',
      AppNotificationType.like => 'notifications.new_like_title',
      AppNotificationType.superLike => 'notifications.new_super_like_title',
      AppNotificationType.system => 'notifications.app_name',
    };
    final translated = LocalizationService.translate(key);
    return translated == key ? _defaultTitle(type) : translated;
  }

  String _payloadFromData(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'system';
    final conversationId = data['conversation_id'] as String? ?? '';
    final matchId = data['match_id'] as String? ?? '';
    final target = conversationId.isNotEmpty ? conversationId : matchId;
    if (type != 'new_message') return '$type|$target';
    final fromUserId = data['from_user_id'] as String? ?? '';
    final senderName = data['sender_name'] as String? ??
        data['from_user_name'] as String? ??
        data['title'] as String? ??
        '';
    return '$type|$target|$fromUserId|${Uri.encodeComponent(senderName)}';
  }

  void _navigateFromData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final conversationId = data['conversation_id'] as String?;
    _navigateFromType(
      type ?? '',
      conversationId ?? '',
      fromUserId: data['from_user_id'] as String? ?? '',
      senderName: data['sender_name'] as String? ??
          data['from_user_name'] as String? ??
          data['title'] as String? ??
          '',
    );
  }

  void _navigateFromType(
    String type,
    String extra, {
    String fromUserId = '',
    String senderName = '',
  }) {
    final router = AppRouter.router;
    switch (type) {
      case 'new_match':
        router.push('/matches');
        break;
      case 'new_message':
        if (extra.isNotEmpty) {
          final conversation = fromUserId.isEmpty
              ? null
              : Conversation(
                  id: extra,
                  participantIds: [fromUserId],
                  otherUserId: fromUserId,
                  otherUserName: senderName.isEmpty ? null : senderName,
                  updatedAt: DateTime.now(),
                );
          router.push('/chat/$extra', extra: conversation);
        } else {
          router.push('/conversations');
        }
        break;
      case 'like':
      case 'super_like':
        router.push('/notifications');
        break;
      default:
        router.push('/notifications');
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'hivmeet_channel',
      'HIVMeet Notifications',
      channelDescription: 'Notifications HIVMeet',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  NotificationsLocalStore get store => _store;
}
