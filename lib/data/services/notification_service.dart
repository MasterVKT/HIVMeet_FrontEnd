import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hivmeet/core/config/routes.dart';
import 'package:hivmeet/core/notifications/foreground_notification_policy.dart';
import 'package:hivmeet/core/notifications/read_receipt_notification_copy.dart';
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

/// Bounded exponential backoff shared by initial FCM token registration and
/// token-refresh registration. Attempts 1, 2 and 3 wait 2, 4 and 8 seconds.
Duration fcmTokenRegistrationRetryDelay(int attempt) {
  assert(attempt > 0);
  return Duration(seconds: (1 << attempt).clamp(2, 30));
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
    } catch (e) {
      // LOG-06 : retry borné avec backoff exponentiel au lieu d'un échec silencieux.
      // SERVICE_NOT_AVAILABLE ou une erreur transitoire ne doit pas être avalée
      // sans tentative de reprise. On ne logue jamais la valeur du token.
      _scheduleTokenRetry(sessionGeneration);
    }
  }

  /// LOG-06 : retry borné avec backoff exponentiel plafonné.
  /// Maximum 3 tentatives, délai exponentiel : 2s, 4s, 8s (plafond 30s).
  /// Annulable via sessionGeneration : si l'utilisateur se déconnecte
  /// pendant le retry, la tentative est abandonnée.
  int _tokenRetryCount = 0;
  static const int _maxTokenRetries = 3;

  void _scheduleTokenRetry(int sessionGeneration) {
    if (_tokenRetryCount >= _maxTokenRetries) return;
    if (!_sessionActive || sessionGeneration != _sessionGeneration) return;

    _tokenRetryCount++;
    final delay = fcmTokenRegistrationRetryDelay(_tokenRetryCount);

    Future.delayed(delay, () {
      if (!_sessionActive || sessionGeneration != _sessionGeneration) return;
      registerTokenWithBackend();
    });
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
        _tokenRetryCount = 0; // Reset retry counter on success
      }
    } catch (_) {
      // Do not register a failed token optimistically. Reuse the bounded,
      // session-aware retry path so a temporary backend/network failure does
      // not leave an otherwise valid device token unregistered.
      _scheduleTokenRetry(sessionGeneration);
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

    // Targeted local popup suppression:
    // only a new message in the exact open conversation is hidden.
    // Lists and every other screen remain eligible for a system alert.
    if (_shouldSuppressLocalNotification(message.data)) {
      return;
    }

    final isReadAlert = notification.type == AppNotificationType.messageRead;
    _showLocalNotification(
      title: isReadAlert
          ? notification.title
          : message.notification?.title ?? notification.title,
      body: isReadAlert
          ? notification.body
          : message.notification?.body ?? notification.body,
      payload: _payloadFromData(message.data),
    );
  }

  /// Supprime seulement l?alerte au premier plan de la conversation exacte ouverte.
  bool _shouldSuppressLocalNotification(Map<String, dynamic> data) {
    return ForegroundNotificationPolicy.shouldSuppress(
      data: data,
      activeConversationId: _realtimeBus.activeConversationId,
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
          senderName: data['sender_name'] as String?,
          preview: data['body'] as String?,
          messageId: data['message_id'] as String?,
          notificationId: data['notification_id'] as String?,
        ));
        break;
      case 'message_read':
        final notificationId = data['notification_id'] as String?;
        if (notificationId == null || notificationId.isEmpty) break;
        _realtimeBus.publish(RealtimeEvent(
          type: RealtimeEventType.messageReadAlert,
          source: RealtimeSource.fcm,
          conversationId: data['conversation_id'] as String?,
          fromUserId: data['reader_id'] as String?,
          readerName: data['reader_name'] as String?,
          messageId: data['representative_message_id'] as String?,
          messageCount: int.tryParse(data['message_count']?.toString() ?? ''),
          readAt: data['read_at'] as String?,
          notificationId: notificationId,
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
      case 'subscription_expiring':
        _realtimeBus.publish(RealtimeEvent(
          type: RealtimeEventType.subscriptionExpiring,
          source: RealtimeSource.fcm,
          notificationId: data['notification_id'] as String?,
          daysRemaining: int.tryParse(data['days_remaining'] as String? ?? ''),
          expiryDate: data['expiry_date'] as String?,
        ));
        break;
      case 'report_resolved':
        _realtimeBus.publish(RealtimeEvent(
          type: RealtimeEventType.reportResolved,
          source: RealtimeSource.fcm,
          notificationId: data['notification_id'] as String?,
          reportId: data['report_id'] as String?,
          reportStatus: data['status'] as String?,
          resolutionSummary: data['resolution_summary'] as String?,
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
    final title = type == AppNotificationType.messageRead
        ? ReadReceiptNotificationCopy.title()
        : message.notification?.title ??
            data['title'] as String? ??
            _localizedDefaultTitle(type);
    final body = type == AppNotificationType.messageRead
        ? ReadReceiptNotificationCopy.body(data)
        : message.notification?.body ?? data['body'] as String? ?? '';

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
      case 'message_read':
        return AppNotificationType.messageRead;
      case 'like':
        return AppNotificationType.like;
      case 'super_like':
        return AppNotificationType.superLike;
      case 'subscription_expiring':
        return AppNotificationType.subscriptionExpiring;
      case 'report_resolved':
        return AppNotificationType.reportResolved;
      default:
        return AppNotificationType.system;
    }
  }

  String _stableNotificationId(
    Map<String, dynamic> data,
    AppNotificationType type,
  ) {
    // L'UUID persistant du backend est prioritaire. Il permet aux actions
    // read/delete d'adresser exactement l'objet REST correspondant.
    final notificationId = data['notification_id'] as String?;
    if (notificationId != null && notificationId.isNotEmpty) {
      return notificationId;
    }

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
      case AppNotificationType.messageRead:
        return 'Message lu';
      case AppNotificationType.like:
        return 'Quelqu\'un vous a liké';
      case AppNotificationType.superLike:
        return 'Vous avez reçu un super like !';
      case AppNotificationType.subscriptionExpiring:
        return 'Votre abonnement expire bientôt';
      case AppNotificationType.reportResolved:
        return 'Votre signalement a été traité';
      case AppNotificationType.system:
        return 'HIVMeet';
    }
  }

  String _localizedDefaultTitle(AppNotificationType type) {
    final key = switch (type) {
      AppNotificationType.newMatch => 'notifications.new_match_title',
      AppNotificationType.newMessage => 'notifications.new_message_title',
      AppNotificationType.messageRead => 'notifications.message_read_title',
      AppNotificationType.like => 'notifications.new_like_title',
      AppNotificationType.superLike => 'notifications.new_super_like_title',
      AppNotificationType.subscriptionExpiring =>
        'notifications.subscription_expiring_title',
      AppNotificationType.reportResolved =>
        'notifications.report_resolved_title',
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
    final fromUserId =
        data['from_user_id'] as String? ?? data['reader_id'] as String? ?? '';
    final senderName = data['sender_name'] as String? ??
        data['reader_name'] as String? ??
        data['from_user_name'] as String? ??
        data['title'] as String? ??
        '';
    // Format: type|target|fromUserId|senderName (fromUserId et senderName
    // vides si non pertinents ou inconnus)
    return '$type|$target|$fromUserId|${Uri.encodeComponent(senderName)}';
  }

  void _navigateFromData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final conversationId = data['conversation_id'] as String?;
    _navigateFromType(
      type ?? '',
      conversationId ?? '',
      fromUserId:
          data['from_user_id'] as String? ?? data['reader_id'] as String? ?? '',
      senderName: data['sender_name'] as String? ??
          data['reader_name'] as String? ??
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
        // Aller à la conversation du match si disponible, sinon à la liste
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
          router.push('/matches');
        }
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
      case 'message_read':
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
        // Premium : fromUserId non vide → profil du liker
        // Non-premium : fromUserId vide → page d'upsell likes-received
        if (fromUserId.isNotEmpty) {
          router.push('/profile/$fromUserId');
        } else {
          router.push('/likes-received');
        }
        break;
      case 'subscription_expiring':
        router.push(AppRoutes.premium);
        break;
      case 'report_resolved':
        // Le frontend affiche la décision dans un dialog au tap —
        // pas besoin de navigation, la notification contient déjà les détails.
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
