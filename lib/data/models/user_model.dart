// lib/data/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:hivmeet/domain/entities/user.dart';

part 'user_model.g.dart';

@JsonSerializable(explicitToJson: true)
class UserModel {
  final String id;
  final String email;
  final String displayName;
  final bool isVerified;
  final bool isPremium;
  @JsonKey(toJson: _dateTimeToTimestamp, fromJson: _timestampToDateTime)
  final DateTime? premiumUntil;
  @JsonKey(toJson: _dateTimeToTimestamp, fromJson: _timestampToDateTimeNonNull)
  final DateTime lastActive;
  final bool isEmailVerified;
  final NotificationSettingsModel notificationSettings;
  final List<String> blockedUserIds;
  @JsonKey(toJson: _dateTimeToTimestamp, fromJson: _timestampToDateTimeNonNull)
  final DateTime createdAt;
  @JsonKey(toJson: _dateTimeToTimestamp, fromJson: _timestampToDateTimeNonNull)
  final DateTime updatedAt;

  UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    return json;
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      isVerified: user.isVerified,
      isPremium: user.isPremium,
      premiumUntil: user.premiumUntil,
      lastActive: user.lastActive,
      isEmailVerified: user.isEmailVerified,
      notificationSettings:
          NotificationSettingsModel.fromEntity(user.notificationSettings),
      blockedUserIds: user.blockedUserIds,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      isVerified: isVerified,
      isPremium: isPremium,
      premiumUntil: premiumUntil,
      lastActive: lastActive,
      isEmailVerified: isEmailVerified,
      notificationSettings: notificationSettings.toEntity(),
      blockedUserIds: blockedUserIds,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static Timestamp? _dateTimeToTimestamp(DateTime? dateTime) {
    return dateTime != null ? Timestamp.fromDate(dateTime) : null;
  }

  static DateTime _timestampToDateTimeNonNull(Timestamp timestamp) {
    return timestamp.toDate();
  }

  static DateTime? _timestampToDateTime(Timestamp? timestamp) {
    return timestamp?.toDate();
  }
}

@JsonSerializable()
class NotificationSettingsModel {
  final bool newMatchNotifications;
  final bool newMessageNotifications;
  final bool profileLikeNotifications;
  final bool appUpdateNotifications;
  final bool promotionalNotifications;
  final DoNotDisturbSettingsModel? doNotDisturbSettings;

  NotificationSettingsModel({
    this.newMatchNotifications = true,
    this.newMessageNotifications = true,
    this.profileLikeNotifications = true,
    this.appUpdateNotifications = true,
    this.promotionalNotifications = false,
    this.doNotDisturbSettings,
  });

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsModelFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationSettingsModelToJson(this);

  factory NotificationSettingsModel.fromEntity(NotificationSettings settings) {
    return NotificationSettingsModel(
      newMatchNotifications: settings.newMatchNotifications,
      newMessageNotifications: settings.newMessageNotifications,
      profileLikeNotifications: settings.profileLikeNotifications,
      appUpdateNotifications: settings.appUpdateNotifications,
      promotionalNotifications: settings.promotionalNotifications,
      doNotDisturbSettings: settings.doNotDisturbSettings != null
          ? DoNotDisturbSettingsModel.fromEntity(settings.doNotDisturbSettings!)
          : null,
    );
  }

  NotificationSettings toEntity() {
    return NotificationSettings(
      newMatchNotifications: newMatchNotifications,
      newMessageNotifications: newMessageNotifications,
      profileLikeNotifications: profileLikeNotifications,
      appUpdateNotifications: appUpdateNotifications,
      promotionalNotifications: promotionalNotifications,
      doNotDisturbSettings: doNotDisturbSettings?.toEntity(),
    );
  }
}

@JsonSerializable()
class DoNotDisturbSettingsModel {
  final bool enabled;
  final String startTimeUtc;
  final String endTimeUtc;

  DoNotDisturbSettingsModel({
    required this.enabled,
    required this.startTimeUtc,
    required this.endTimeUtc,
  });

  factory DoNotDisturbSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$DoNotDisturbSettingsModelFromJson(json);
  Map<String, dynamic> toJson() => _$DoNotDisturbSettingsModelToJson(this);

  factory DoNotDisturbSettingsModel.fromEntity(DoNotDisturbSettings settings) {
    return DoNotDisturbSettingsModel(
      enabled: settings.enabled,
      startTimeUtc: settings.startTimeUtc,
      endTimeUtc: settings.endTimeUtc,
    );
  }

  DoNotDisturbSettings toEntity() {
    return DoNotDisturbSettings(
      enabled: enabled,
      startTimeUtc: startTimeUtc,
      endTimeUtc: endTimeUtc,
    );
  }
}
