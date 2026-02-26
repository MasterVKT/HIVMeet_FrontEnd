// test/data/models/match_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hivemeet/data/models/match_model.dart';
import 'package:hivemeet/data/models/profile_model.dart';
import 'package:hivemeet/data/models/message_model.dart';
import 'package:hivemeet/domain/entities/match.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('MatchModel', () {
    final testDateTime = DateTime(2024, 2, 24, 12, 0, 0);

    final testProfileJson = {
      'id': 'profile123',
      'userId': 'user123',
      'displayName': 'John Doe',
      'birthDate': Timestamp.fromDate(DateTime(1990, 1, 1)),
      'bio': 'Test bio',
      'location': {
        'latitude': 48.8566,
        'longitude': 2.3522,
        'geohash': 'u09tvw0f6',
      },
      'city': 'Paris',
      'country': 'France',
      'interests': ['music'],
      'relationshipType': 'casual_dating',
      'photos': {
        'main': 'https://example.com/photo1.jpg',
        'others': <String>[],
        'private': <String>[],
      },
      'searchPreferences': {
        'minAge': 25,
        'maxAge': 35,
        'maxDistance': 50.0,
        'interestedIn': ['female'],
        'relationshipTypes': ['casual_dating'],
        'showVerifiedOnly': false,
        'showOnlineOnly': false,
      },
      'lastActive': Timestamp.fromDate(testDateTime),
      'isHidden': false,
      'verificationStatus': {
        'status': 'verified',
        'documents': <String, dynamic>{},
      },
      'privacySettings': {
        'profileVisibility': 'visible_to_all',
        'showOnlineStatus': true,
        'showDistance': true,
        'showExactLocation': false,
        'profileDiscoverable': true,
      },
      'createdAt': Timestamp.fromDate(testDateTime),
      'updatedAt': Timestamp.fromDate(testDateTime),
    };

    final testMessageJson = {
      'id': 'message123',
      'senderId': 'user123',
      'receiverId': 'user456',
      'content': 'Hello!',
      'type': 'text',
      'sentAt': testDateTime.toIso8601String(),
      'isRead': false,
    };

    final testJson = {
      'id': 'match123',
      'profile': testProfileJson,
      'matched_at': testDateTime.toIso8601String(),
      'last_message': testMessageJson,
      'is_new': true,
      'unread_counts': {'user456': 3},
    };

    test('fromJson should deserialize JSON correctly', () {
      final result = MatchModel.fromJson(testJson);

      expect(result.id, 'match123');
      expect(result.profile, isA<ProfileModel>());
      expect(result.profile.id, 'profile123');
      expect(result.matchedAt, isA<DateTime>());
      expect(result.lastMessage, isNotNull);
      expect(result.isNew, true);
      expect(result.unreadCounts['user456'], 3);
    });

    test('fromJson should handle null last_message', () {
      final jsonWithoutMessage = Map<String, dynamic>.from(testJson);
      jsonWithoutMessage['last_message'] = null;

      final result = MatchModel.fromJson(jsonWithoutMessage);

      expect(result.id, 'match123');
      expect(result.lastMessage, null);
    });

    test('fromJson should handle missing optional fields with defaults', () {
      final minimalJson = {
        'id': 'match123',
        'profile': testProfileJson,
        'matched_at': testDateTime.toIso8601String(),
      };

      final result = MatchModel.fromJson(minimalJson);

      expect(result.id, 'match123');
      expect(result.isNew, false);
      expect(result.unreadCounts, isEmpty);
      expect(result.lastMessage, null);
    });

    test('toJson should serialize model correctly', () {
      final model = MatchModel(
        id: 'match123',
        profile: ProfileModel.fromJson(testProfileJson),
        matchedAt: testDateTime,
        lastMessage: MessageModel.fromJson(testMessageJson),
        isNew: true,
        unreadCounts: {'user456': 3},
      );

      final result = model.toJson();

      expect(result['id'], 'match123');
      expect(result['profile'], isA<Map>());
      expect(result['matched_at'], isA<String>());
      expect(result['last_message'], isNotNull);
      expect(result['is_new'], true);
      expect(result['unread_counts'], {'user456': 3});
    });

    test('fromJson and toJson should be reversible', () {
      final originalModel = MatchModel.fromJson(testJson);
      final json = originalModel.toJson();
      final restored = MatchModel.fromJson(json);

      expect(restored.id, originalModel.id);
      expect(restored.profile.id, originalModel.profile.id);
      expect(restored.isNew, originalModel.isNew);
    });

    test('toEntity should convert model to entity correctly', () {
      final model = MatchModel(
        id: 'match123',
        profile: ProfileModel.fromJson(testProfileJson),
        matchedAt: testDateTime,
        lastMessage: null,
        isNew: false,
        unreadCounts: {},
      );

      final entity = model.toEntity();

      expect(entity, isA<Match>());
      expect(entity.id, model.id);
      expect(entity.profile.id, model.profile.id);
      expect(entity.matchedAt, model.matchedAt);
      expect(entity.isNew, model.isNew);
    });

    test('fromEntity should convert entity to model correctly', () {
      final profile = ProfileModel.fromJson(testProfileJson);
      final entity = Match(
        id: 'match123',
        profile: profile.toEntity(),
        matchedAt: testDateTime,
        lastMessage: null,
        isNew: true,
        unreadCounts: {'user456': 2},
      );

      final model = MatchModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.profile.id, entity.profile.id);
      expect(model.matchedAt, entity.matchedAt);
      expect(model.isNew, entity.isNew);
      expect(model.unreadCounts, entity.unreadCounts);
    });

    test('fromEntity should handle null lastMessage', () {
      final profile = ProfileModel.fromJson(testProfileJson);
      final entity = Match(
        id: 'match123',
        profile: profile.toEntity(),
        matchedAt: testDateTime,
        lastMessage: null,
        isNew: false,
        unreadCounts: {},
      );

      final model = MatchModel.fromEntity(entity);

      expect(model.lastMessage, null);
    });

    test('should handle empty unreadCounts', () {
      final json = {
        'id': 'match123',
        'profile': testProfileJson,
        'matched_at': testDateTime.toIso8601String(),
        'is_new': false,
        'unread_counts': <String, int>{},
      };

      final result = MatchModel.fromJson(json);

      expect(result.unreadCounts, isEmpty);
    });

    test('should handle multiple unread counts', () {
      final json = {
        'id': 'match123',
        'profile': testProfileJson,
        'matched_at': testDateTime.toIso8601String(),
        'is_new': true,
        'unread_counts': {
          'user456': 5,
          'user789': 2,
        },
      };

      final result = MatchModel.fromJson(json);

      expect(result.unreadCounts.length, 2);
      expect(result.unreadCounts['user456'], 5);
      expect(result.unreadCounts['user789'], 2);
    });
  });

  group('SwipeActionModel', () {
    final testDateTime = DateTime(2024, 2, 24, 12, 0, 0);

    final testJson = {
      'id': 'swipe123',
      'fromUserId': 'user123',
      'toUserId': 'user456',
      'type': 'like',
      'createdAt': Timestamp.fromDate(testDateTime),
    };

    test('fromJson should deserialize JSON correctly', () {
      final result = SwipeActionModel.fromJson(testJson);

      expect(result.id, 'swipe123');
      expect(result.fromUserId, 'user123');
      expect(result.toUserId, 'user456');
      expect(result.type, 'like');
      expect(result.createdAt, isA<DateTime>());
    });

    test('toJson should serialize model correctly', () {
      final model = SwipeActionModel(
        id: 'swipe123',
        fromUserId: 'user123',
        toUserId: 'user456',
        type: 'like',
        createdAt: testDateTime,
      );

      final result = model.toJson();

      expect(result['id'], 'swipe123');
      expect(result['fromUserId'], 'user123');
      expect(result['toUserId'], 'user456');
      expect(result['type'], 'like');
      expect(result['createdAt'], isA<Timestamp>());
    });

    test('fromJson and toJson should be reversible', () {
      final originalModel = SwipeActionModel.fromJson(testJson);
      final json = originalModel.toJson();
      final restored = SwipeActionModel.fromJson(json);

      expect(restored.id, originalModel.id);
      expect(restored.fromUserId, originalModel.fromUserId);
      expect(restored.toUserId, originalModel.toUserId);
      expect(restored.type, originalModel.type);
    });

    test('toEntity should convert model to entity correctly', () {
      final model = SwipeActionModel(
        id: 'swipe123',
        fromUserId: 'user123',
        toUserId: 'user456',
        type: 'like',
        createdAt: testDateTime,
      );

      final entity = model.toEntity();

      expect(entity, isA<SwipeAction>());
      expect(entity.id, model.id);
      expect(entity.fromUserId, model.fromUserId);
      expect(entity.toUserId, model.toUserId);
      expect(entity.type, isA<SwipeType>());
    });

    test('should parse different swipe types correctly', () {
      final swipeTypes = ['like', 'superLike', 'dislike'];

      for (final type in swipeTypes) {
        final json = {
          'id': 'swipe123',
          'fromUserId': 'user123',
          'toUserId': 'user456',
          'type': type,
          'createdAt': Timestamp.fromDate(testDateTime),
        };

        final model = SwipeActionModel.fromJson(json);
        expect(model.type, type);

        final entity = model.toEntity();
        expect(entity.type, isA<SwipeType>());
      }
    });

    test('should handle unknown swipe type as dislike', () {
      final json = {
        'id': 'swipe123',
        'fromUserId': 'user123',
        'toUserId': 'user456',
        'type': 'unknown_type',
        'createdAt': Timestamp.fromDate(testDateTime),
      };

      final model = SwipeActionModel.fromJson(json);
      final entity = model.toEntity();

      expect(entity.type, SwipeType.dislike);
    });

    test('should handle edge case with same user IDs', () {
      final json = {
        'id': 'swipe123',
        'fromUserId': 'user123',
        'toUserId': 'user123',
        'type': 'like',
        'createdAt': Timestamp.fromDate(testDateTime),
      };

      final model = SwipeActionModel.fromJson(json);

      expect(model.fromUserId, model.toUserId);
    });

    test('should preserve timestamp precision', () {
      final preciseDateTime = DateTime(2024, 2, 24, 12, 30, 45, 123);
      final json = {
        'id': 'swipe123',
        'fromUserId': 'user123',
        'toUserId': 'user456',
        'type': 'like',
        'createdAt': Timestamp.fromDate(preciseDateTime),
      };

      final model = SwipeActionModel.fromJson(json);
      final restoredJson = model.toJson();
      final restoredModel = SwipeActionModel.fromJson(restoredJson);

      expect(restoredModel.createdAt.year, preciseDateTime.year);
      expect(restoredModel.createdAt.month, preciseDateTime.month);
      expect(restoredModel.createdAt.day, preciseDateTime.day);
      expect(restoredModel.createdAt.hour, preciseDateTime.hour);
      expect(restoredModel.createdAt.minute, preciseDateTime.minute);
    });
  });
}
