import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hivmeet/domain/entities/app_notification.dart';

class NotificationsLocalStore {
  static const String _key = 'app_notifications_v1';
  static const int _maxStored = 100;
  Future<void> _pendingWrite = Future.value();

  Future<List<AppNotification>> load() async {
    await _pendingWrite;
    return _loadUnlocked();
  }

  Future<List<AppNotification>> _loadUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> add(AppNotification notification) async {
    await upsertAll([notification]);
  }

  /// Persiste un lot atomiquement afin que deux événements temps réel rapprochés
  /// ne puissent pas s'écraser mutuellement dans SharedPreferences.
  Future<void> upsertAll(Iterable<AppNotification> notifications) {
    final entries = notifications.toList(growable: false);
    if (entries.isEmpty) return Future.value();

    return _serialize(() async {
      final current = await _loadUnlocked();
      final byId = <String, AppNotification>{
        for (final notification in current) notification.id: notification,
      };
      for (final notification in entries) {
        final existing = byId[notification.id];
        // Un doublon reçu plus tard par un second canal (FCM après WS ou
        // inversement) ne doit jamais faire réapparaître un badge déjà soldé.
        byId[notification.id] = existing?.isRead == true && !notification.isRead
            ? notification.copyWith(isRead: true)
            : notification;
      }
      final updated = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _save(updated.take(_maxStored));
    });
  }

  Future<void> markRead(String id) async {
    return _serialize(() async {
      final current = await _loadUnlocked();
      await _save(
        current.map((n) => n.id == id ? n.copyWith(isRead: true) : n),
      );
    });
  }

  Future<void> markAllRead() async {
    return _serialize(() async {
      final current = await _loadUnlocked();
      await _save(current.map((n) => n.copyWith(isRead: true)));
    });
  }

  Future<int> unreadCount() async {
    final items = await load();
    return items.where((n) => !n.isRead).length;
  }

  Future<void> clear() async {
    return _serialize(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    });
  }

  Future<void> _save(Iterable<AppNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(notifications.map((n) => n.toJson()).toList()),
    );
  }

  Future<T> _serialize<T>(Future<T> Function() action) {
    final result = _pendingWrite.then((_) => action());
    _pendingWrite = result.then<void>(
      (_) {},
      onError: (_, __) {},
    );
    return result;
  }
}
