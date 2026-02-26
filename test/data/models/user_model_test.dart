// test/data/models/user_model_test.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivemeet/data/models/user_model.dart';
import 'package:hivemeet/domain/entities/user.dart';

void main() {
  group('UserModel', () {
    final testDateTime = DateTime(2024, 2, 24, 12, 0, 0);
    final premiumUntilDate = testDateTime.add(Duration(days: 30));

    final testJson = {
      'id': 'user123',
      'email': 'test@example.com',
      'displayName': 'John Doe',
      'isVerified': true,
      'isPremium': true,
      'premiumUntil': Timestamp.fromDate(premiumUntilDate),
      'lastActive': Timestamp.fromDate(testDateTime),
      'isEmailVerified': true,
      'notificationSettings': {
        'pushEnabled': true,
        'emailEnabled': true,
        'newMatchNotification': true,
        'newMessageNotification': true,
        'likeReceivedNotification': false,
      },
      'blockedUserIds': ['user456', 'user789'],
      'createdAt': Timestamp.fromDate(testDateTime),
      'updatedAt': Timestamp.fromDate(testDateTime),
    };

    test('fromJson should deserialize JSON correctly', () {
      final result = UserModel.fromJson(testJson);

      expect(result.id, 'user123');
      expect(result.email, 'test@example.com');
      expect(result.displayName, 'John Doe');
      expect(result.isVerified, true);
      expect(result.isPremium, true);
      expect(result.premiumUntil, isA<DateTime>());
      expect(result.lastActive, isA<DateTime>());
      expect(result.isEmailVerified, true);
      expect(result.notificationSettings, isA<NotificationSettingsModel>());
      expect(result.blockedUserIds.length, 2);
      expect(result.blockedUserIds, contains('user456'));
      expect(result.blockedUserIds, contains('user789'));
      expect(result.createdAt, isA<DateTime>());
      expect(result.updatedAt, isA<DateTime>());
    });

    test('fromJson should handle free user (not premium)', () {
      final json = Map<String, dynamic>.from(testJson);
      json['isPremium'] = false;
      json['premiumUntil'] = null;

      final result = UserModel.fromJson(json);

      expect(result.isPremium, false);
      expect(result.premiumUntil, null);
    });

    test('fromJson should handle empty blockedUserIds', () {
      final json = Map<String, dynamic>.from(testJson);
      json['blockedUserIds'] = <String>[];

      final result = UserModel.fromJson(json);

      expect(result.blockedUserIds, isEmpty);
    });

    test('fromJson should handle unverified user', () {
      final json = Map<String, dynamic>.from(testJson);
      json['isVerified'] = false;
      json['isEmailVerified'] = false;

      final result = UserModel.fromJson(json);

      expect(result.isVerified, false);
      expect(result.isEmailVerified, false);
    });

    test('toJson should serialize model correctly', () {
      final model = UserModel(
        id: 'user123',
        email: 'test@example.com',
        displayName: 'John Doe',
        isVerified: true,
        isPremium: true,
        premiumUntil: premiumUntilDate,
        lastActive: testDateTime,
        isEmailVerified: true,
        notificationSettings: NotificationSettingsModel(
          pushEnabled: true,
          emailEnabled: true,
          newMatchNotification: true,
          newMessageNotification: true,
          likeReceivedNotification: false,
        ),
        blockedUserIds: ['user456'],
        createdAt: testDateTime,
        updatedAt: testDateTime,
      );

      final result = model.toJson();

      expect(result['id'], 'user123');
      expect(result['email'], 'test@example.com');
      expect(result['displayName'], 'John Doe');
      expect(result['isVerified'], true);
      expect(result['isPremium'], true);
      expect(result['premiumUntil'], isA<Timestamp>());
      expect(result['isEmailVerified'], true);
      expect(result['notificationSettings'], isA<Map>());
      expect(result['blockedUserIds'], ['user456']);
    });

    test('fromJson and toJson should be reversible', () {
      final originalModel = UserModel.fromJson(testJson);
      final json = originalModel.toJson();
      final restored = UserModel.fromJson(json);

      expect(restored.id, originalModel.id);
      expect(restored.email, originalModel.email);
      expect(restored.displayName, originalModel.displayName);
      expect(restored.isVerified, originalModel.isVerified);
      expect(restored.isPremium, originalModel.isPremium);
      expect(restored.isEmailVerified, originalModel.isEmailVerified);
      expect(restored.blockedUserIds, originalModel.blockedUserIds);
    });

    test('toEntity should convert model to entity correctly', () {
      final model = UserModel(
        id: 'user123',
        email: 'test@example.com',
        displayName: 'John Doe',
        isVerified: true,
        isPremium: false,
        premiumUntil: null,
        lastActive: testDateTime,
        isEmailVerified: true,
        notificationSettings: NotificationSettingsModel(
          pushEnabled: true,
          emailEnabled: true,
          newMatchNotification: true,
          newMessageNotification: true,
          likeReceivedNotification: false,
        ),
        blockedUserIds: [],
        createdAt: testDateTime,
        updatedAt: testDateTime,
      );

      final entity = model.toEntity();

      expect(entity, isA<User>());
      expect(entity.id, model.id);
      expect(entity.email, model.email);
      expect(entity.displayName, model.displayName);
      expect(entity.isVerified, model.isVerified);
      expect(entity.isPremium, model.isPremium);
      expect(entity.premiumUntil, model.premiumUntil);
      expect(entity.isEmailVerified, model.isEmailVerified);
      expect(entity.blockedUserIds, model.blockedUserIds);
    });

    test('fromEntity should convert entity to model correctly', () {
      final entity = User(
        id: 'user123',
        email: 'test@example.com',
        displayName: 'John Doe',
        isVerified: true,
        isPremium: true,
        premiumUntil: premiumUntilDate,
        lastActive: testDateTime,
        isEmailVerified: true,
        notificationSettings: NotificationSettings(
          pushEnabled: true,
          emailEnabled: true,
          newMatchNotification: true,
          newMessageNotification: true,
          likeReceivedNotification: false,
        ),
        blockedUserIds: ['user456', 'user789'],
        createdAt: testDateTime,
        updatedAt: testDateTime,
      );

      final model = UserModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.email, entity.email);
      expect(model.displayName, entity.displayName);
      expect(model.isVerified, entity.isVerified);
      expect(model.isPremium, entity.isPremium);
      expect(model.blockedUserIds, entity.blockedUserIds);
    });

    test('toFirestore should exclude id from JSON', () {
      final model = UserModel(
        id: 'user123',
        email: 'test@example.com',
        displayName: 'John Doe',
        isVerified: false,
        isPremium: false,
        lastActive: testDateTime,
        isEmailVerified: false,
        notificationSettings: NotificationSettingsModel(
          pushEnabled: true,
          emailEnabled: true,
          newMatchNotification: true,
          newMessageNotification: true,
          likeReceivedNotification: false,
        ),
        blockedUserIds: [],
        createdAt: testDateTime,
        updatedAt: testDateTime,
      );

      final result = model.toFirestore();

      expect(result.containsKey('id'), false);
      expect(result.containsKey('email'), true);
      expect(result.containsKey('displayName'), true);
    });

    test('should handle email with different formats', () {
      final emails = [
        'test@example.com',
        'user.name+tag@example.co.uk',
        'test123@sub.domain.com',
      ];

      for (final email in emails) {
        final json = Map<String, dynamic>.from(testJson);
        json['email'] = email;

        final result = UserModel.fromJson(json);
        expect(result.email, email);
      }
    });

    test('should handle multiple blocked users', () {
      final blockedIds = List.generate(10, (i) => 'user$i');
      final json = Map<String, dynamic>.from(testJson);
      json['blockedUserIds'] = blockedIds;

      final result = UserModel.fromJson(json);

      expect(result.blockedUserIds.length, 10);
      expect(result.blockedUserIds, blockedIds);
    });

    test('should handle premium expiration edge case', () {
      final almostExpiredDate = DateTime.now().add(Duration(hours: 1));
      final json = Map<String, dynamic>.from(testJson);
      json['isPremium'] = true;
      json['premiumUntil'] = Timestamp.fromDate(almostExpiredDate);

      final result = UserModel.fromJson(json);

      expect(result.isPremium, true);
      expect(result.premiumUntil, isNotNull);
      expect(result.premiumUntil!.isAfter(DateTime.now()), true);
    });

    test('should handle special characters in displayName', () {
      final specialNames = [
        'François',
        'José María',
        'Müller',
        'O\'Brien',
        'Jean-Claude',
      ];

      for (final name in specialNames) {
        final json = Map<String, dynamic>.from(testJson);
        json['displayName'] = name;

        final result = UserModel.fromJson(json);
        expect(result.displayName, name);
      }
    });

    test('should preserve lastActive timestamp precision', () {
      final preciseDateTime = DateTime(2024, 2, 24, 12, 30, 45, 123);
      final json = Map<String, dynamic>.from(testJson);
      json['lastActive'] = Timestamp.fromDate(preciseDateTime);

      final result = UserModel.fromJson(json);

      expect(result.lastActive.year, preciseDateTime.year);
      expect(result.lastActive.month, preciseDateTime.month);
      expect(result.lastActive.day, preciseDateTime.day);
      expect(result.lastActive.hour, preciseDateTime.hour);
      expect(result.lastActive.minute, preciseDateTime.minute);
    });
  });

  group('NotificationSettingsModel', () {
    test('fromJson should deserialize JSON correctly', () {
      final json = {
        'pushEnabled': true,
        'emailEnabled': true,
        'newMatchNotification': true,
        'newMessageNotification': true,
        'likeReceivedNotification': false,
      };

      final result = NotificationSettingsModel.fromJson(json);

      expect(result.pushEnabled, true);
      expect(result.emailEnabled, true);
      expect(result.newMatchNotification, true);
      expect(result.newMessageNotification, true);
      expect(result.likeReceivedNotification, false);
    });

    test('fromJson should use default values when fields are missing', () {
      final json = <String, dynamic>{};

      final result = NotificationSettingsModel.fromJson(json);

      expect(result.pushEnabled, true);
      expect(result.emailEnabled, true);
      expect(result.newMatchNotification, true);
      expect(result.newMessageNotification, true);
      expect(result.likeReceivedNotification, true);
    });

    test('toJson should serialize model correctly', () {
      final model = NotificationSettingsModel(
        pushEnabled: false,
        emailEnabled: false,
        newMatchNotification: false,
        newMessageNotification: false,
        likeReceivedNotification: false,
      );

      final result = model.toJson();

      expect(result['pushEnabled'], false);
      expect(result['emailEnabled'], false);
      expect(result['newMatchNotification'], false);
      expect(result['newMessageNotification'], false);
      expect(result['likeReceivedNotification'], false);
    });

    test('toEntity should convert model to entity correctly', () {
      final model = NotificationSettingsModel(
        pushEnabled: true,
        emailEnabled: false,
        newMatchNotification: true,
        newMessageNotification: false,
        likeReceivedNotification: true,
      );

      final entity = model.toEntity();

      expect(entity, isA<NotificationSettings>());
      expect(entity.pushEnabled, model.pushEnabled);
      expect(entity.emailEnabled, model.emailEnabled);
      expect(entity.newMatchNotification, model.newMatchNotification);
      expect(entity.newMessageNotification, model.newMessageNotification);
      expect(entity.likeReceivedNotification, model.likeReceivedNotification);
    });

    test('fromEntity should convert entity to model correctly', () {
      final entity = NotificationSettings(
        pushEnabled: false,
        emailEnabled: true,
        newMatchNotification: false,
        newMessageNotification: true,
        likeReceivedNotification: false,
      );

      final model = NotificationSettingsModel.fromEntity(entity);

      expect(model.pushEnabled, entity.pushEnabled);
      expect(model.emailEnabled, entity.emailEnabled);
      expect(model.newMatchNotification, entity.newMatchNotification);
      expect(model.newMessageNotification, entity.newMessageNotification);
      expect(model.likeReceivedNotification, entity.likeReceivedNotification);
    });

    test('should handle all notifications disabled', () {
      final json = {
        'pushEnabled': false,
        'emailEnabled': false,
        'newMatchNotification': false,
        'newMessageNotification': false,
        'likeReceivedNotification': false,
      };

      final result = NotificationSettingsModel.fromJson(json);

      expect(result.pushEnabled, false);
      expect(result.emailEnabled, false);
      expect(result.newMatchNotification, false);
      expect(result.newMessageNotification, false);
      expect(result.likeReceivedNotification, false);
    });

    test('should handle all notifications enabled', () {
      final json = {
        'pushEnabled': true,
        'emailEnabled': true,
        'newMatchNotification': true,
        'newMessageNotification': true,
        'likeReceivedNotification': true,
      };

      final result = NotificationSettingsModel.fromJson(json);

      expect(result.pushEnabled, true);
      expect(result.emailEnabled, true);
      expect(result.newMatchNotification, true);
      expect(result.newMessageNotification, true);
      expect(result.likeReceivedNotification, true);
    });
  });
}
