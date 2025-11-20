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

  /// Convertit l'entité User en Map pour la sérialisation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'isVerified': isVerified,
      'isPremium': isPremium,
      'premiumUntil': premiumUntil?.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'notificationSettings': notificationSettings.toJson(),
      'blockedUserIds': blockedUserIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Crée une entité User depuis un Map JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String? ??
          json['username'] as String? ??
          'Utilisateur',
      isVerified: json['isVerified'] as bool? ?? false,
      isPremium: json['isPremium'] as bool? ?? false,
      premiumUntil: json['premiumUntil'] != null
          ? DateTime.parse(json['premiumUntil'] as String)
          : null,
      lastActive: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'] as String)
          : DateTime.now(),
      isEmailVerified: json['isEmailVerified'] as bool? ??
          json['email_verified'] as bool? ??
          false,
      notificationSettings: json['notificationSettings'] != null
          ? NotificationSettings.fromJson(
              json['notificationSettings'] as Map<String, dynamic>)
          : const NotificationSettings(),
      blockedUserIds:
          (json['blockedUserIds'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
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
      newMatchNotifications:
          newMatchNotifications ?? this.newMatchNotifications,
      newMessageNotifications:
          newMessageNotifications ?? this.newMessageNotifications,
      profileLikeNotifications:
          profileLikeNotifications ?? this.profileLikeNotifications,
      appUpdateNotifications:
          appUpdateNotifications ?? this.appUpdateNotifications,
      promotionalNotifications:
          promotionalNotifications ?? this.promotionalNotifications,
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

  /// Convertit NotificationSettings en Map pour la sérialisation
  Map<String, dynamic> toJson() {
    return {
      'newMatchNotifications': newMatchNotifications,
      'newMessageNotifications': newMessageNotifications,
      'profileLikeNotifications': profileLikeNotifications,
      'appUpdateNotifications': appUpdateNotifications,
      'promotionalNotifications': promotionalNotifications,
      'doNotDisturbSettings': doNotDisturbSettings?.toJson(),
    };
  }

  /// Crée NotificationSettings depuis un Map JSON
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      newMatchNotifications: json['newMatchNotifications'] as bool? ?? true,
      newMessageNotifications: json['newMessageNotifications'] as bool? ?? true,
      profileLikeNotifications:
          json['profileLikeNotifications'] as bool? ?? true,
      appUpdateNotifications: json['appUpdateNotifications'] as bool? ?? true,
      promotionalNotifications:
          json['promotionalNotifications'] as bool? ?? false,
      doNotDisturbSettings: json['doNotDisturbSettings'] != null
          ? DoNotDisturbSettings.fromJson(
              json['doNotDisturbSettings'] as Map<String, dynamic>)
          : null,
    );
  }
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

  /// Convertit DoNotDisturbSettings en Map pour la sérialisation
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'startTimeUtc': startTimeUtc,
      'endTimeUtc': endTimeUtc,
    };
  }

  /// Crée DoNotDisturbSettings depuis un Map JSON
  factory DoNotDisturbSettings.fromJson(Map<String, dynamic> json) {
    return DoNotDisturbSettings(
      enabled: json['enabled'] as bool,
      startTimeUtc: json['startTimeUtc'] as String,
      endTimeUtc: json['endTimeUtc'] as String,
    );
  }
}
