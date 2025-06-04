// lib/domain/entities/user.dart

import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final bool isVerified;
  final bool isPremium;
  final DateTime? premiumUntil;
  final DateTime lastActive;
  final bool isEmailVerified;
  final NotificationSettings notificationSettings;
  final List<String> blockedUserIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.isVerified,
    required this.isPremium,
    this.premiumUntil,
    required this.lastActive,
    required this.isEmailVerified,
    required this.notificationSettings,
    required this.blockedUserIds,
    required this.createdAt,
    required this.updatedAt,
  });

  // Propriétés calculées
  bool get isOnline {
    final difference = DateTime.now().difference(lastActive);
    return difference.inMinutes < 10;
  }

  bool get isPremiumActive {
    if (!isPremium) return false;
    if (premiumUntil == null) return false;
    return premiumUntil!.isAfter(DateTime.now());
  }

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    bool? isVerified,
    bool? isPremium,
    DateTime? premiumUntil,
    DateTime? lastActive,
    bool? isEmailVerified,
    NotificationSettings? notificationSettings,
    List<String>? blockedUserIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isVerified: isVerified ?? this.isVerified,
      isPremium: isPremium ?? this.isPremium,
      premiumUntil: premiumUntil ?? this.premiumUntil,
      lastActive: lastActive ?? this.lastActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        isVerified,
        isPremium,
        premiumUntil,
        lastActive,
        isEmailVerified,
        notificationSettings,
        blockedUserIds,
        createdAt,
        updatedAt,
      ];
}

class NotificationSettings extends Equatable {
  final bool newMatchNotifications;
  final bool newMessageNotifications;
  final bool profileLikeNotifications;
  final bool appUpdateNotifications;
  final bool promotionalNotifications;
  final DoNotDisturbSettings? doNotDisturbSettings;

  const NotificationSettings({
    this.newMatchNotifications = true,
    this.newMessageNotifications = true,
    this.profileLikeNotifications = true,
    this.appUpdateNotifications = true,
    this.promotionalNotifications = false,
    this.doNotDisturbSettings,
  });

  NotificationSettings copyWith({
    bool? newMatchNotifications,
    bool? newMessageNotifications,
    bool? profileLikeNotifications,
    bool? appUpdateNotifications,
    bool? promotionalNotifications,
    DoNotDisturbSettings? doNotDisturbSettings,
  }) {
    return NotificationSettings(
      newMatchNotifications: newMatchNotifications ?? this.newMatchNotifications,
      newMessageNotifications: newMessageNotifications ?? this.newMessageNotifications,
      profileLikeNotifications: profileLikeNotifications ?? this.profileLikeNotifications,
      appUpdateNotifications: appUpdateNotifications ?? this.appUpdateNotifications,
      promotionalNotifications: promotionalNotifications ?? this.promotionalNotifications,
      doNotDisturbSettings: doNotDisturbSettings ?? this.doNotDisturbSettings,
    );
  }

  @override
  List<Object?> get props => [
        newMatchNotifications,
        newMessageNotifications,
        profileLikeNotifications,
        appUpdateNotifications,
        promotionalNotifications,
        doNotDisturbSettings,
      ];
}

class DoNotDisturbSettings extends Equatable {
  final bool enabled;
  final String startTimeUtc; // Format: "HH:mm"
  final String endTimeUtc; // Format: "HH:mm"

  const DoNotDisturbSettings({
    required this.enabled,
    required this.startTimeUtc,
    required this.endTimeUtc,
  });

  @override
  List<Object> get props => [enabled, startTimeUtc, endTimeUtc];
}
