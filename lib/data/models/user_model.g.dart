// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      isVerified: json['isVerified'] as bool,
      isPremium: json['isPremium'] as bool,
      premiumUntil:
          UserModel._timestampToDateTime(json['premiumUntil'] as Timestamp?),
      lastActive: UserModel._timestampToDateTimeNonNull(
          json['lastActive'] as Timestamp),
      isEmailVerified: json['isEmailVerified'] as bool,
      notificationSettings: NotificationSettingsModel.fromJson(
          json['notificationSettings'] as Map<String, dynamic>),
      blockedUserIds: (json['blockedUserIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      createdAt:
          UserModel._timestampToDateTimeNonNull(json['createdAt'] as Timestamp),
      updatedAt:
          UserModel._timestampToDateTimeNonNull(json['updatedAt'] as Timestamp),
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'displayName': instance.displayName,
      'isVerified': instance.isVerified,
      'isPremium': instance.isPremium,
      'premiumUntil': UserModel._dateTimeToTimestamp(instance.premiumUntil),
      'lastActive': UserModel._dateTimeToTimestamp(instance.lastActive),
      'isEmailVerified': instance.isEmailVerified,
      'notificationSettings': instance.notificationSettings.toJson(),
      'blockedUserIds': instance.blockedUserIds,
      'createdAt': UserModel._dateTimeToTimestamp(instance.createdAt),
      'updatedAt': UserModel._dateTimeToTimestamp(instance.updatedAt),
    };

NotificationSettingsModel _$NotificationSettingsModelFromJson(
        Map<String, dynamic> json) =>
    NotificationSettingsModel(
      newMatchNotifications: json['newMatchNotifications'] as bool? ?? true,
      newMessageNotifications: json['newMessageNotifications'] as bool? ?? true,
      profileLikeNotifications:
          json['profileLikeNotifications'] as bool? ?? true,
      appUpdateNotifications: json['appUpdateNotifications'] as bool? ?? true,
      promotionalNotifications:
          json['promotionalNotifications'] as bool? ?? false,
      doNotDisturbSettings: json['doNotDisturbSettings'] == null
          ? null
          : DoNotDisturbSettingsModel.fromJson(
              json['doNotDisturbSettings'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$NotificationSettingsModelToJson(
        NotificationSettingsModel instance) =>
    <String, dynamic>{
      'newMatchNotifications': instance.newMatchNotifications,
      'newMessageNotifications': instance.newMessageNotifications,
      'profileLikeNotifications': instance.profileLikeNotifications,
      'appUpdateNotifications': instance.appUpdateNotifications,
      'promotionalNotifications': instance.promotionalNotifications,
      'doNotDisturbSettings': instance.doNotDisturbSettings,
    };

DoNotDisturbSettingsModel _$DoNotDisturbSettingsModelFromJson(
        Map<String, dynamic> json) =>
    DoNotDisturbSettingsModel(
      enabled: json['enabled'] as bool,
      startTimeUtc: json['startTimeUtc'] as String,
      endTimeUtc: json['endTimeUtc'] as String,
    );

Map<String, dynamic> _$DoNotDisturbSettingsModelToJson(
        DoNotDisturbSettingsModel instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'startTimeUtc': instance.startTimeUtc,
      'endTimeUtc': instance.endTimeUtc,
    };
