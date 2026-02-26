// test/data/models/message_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hivemeet/data/models/message_model.dart';
import 'package:hivemeet/domain/entities/message.dart';

void main() {
  group('MessageModel', () {
    final testDateTime = DateTime(2024, 2, 24, 12, 0, 0);

    final testJson = {
      'id': 'message123',
      'conversation_id': 'conv123',
      'sender_id': 'user123',
      'content': 'Hello, how are you?',
      'message_type': 'text',
      'media_url': null,
      'created_at': testDateTime.toIso8601String(),
      'is_read': false,
      'reactions': <String, String>{},
      'status': 'sent',
    };

    test('fromJson should deserialize JSON correctly', () {
      final result = MessageModel.fromJson(testJson);

      expect(result.id, 'message123');
      expect(result.conversationId, 'conv123');
      expect(result.senderId, 'user123');
      expect(result.content, 'Hello, how are you?');
      expect(result.type, MessageType.text);
      expect(result.mediaUrl, null);
      expect(result.createdAt, isA<DateTime>());
      expect(result.isRead, false);
      expect(result.reactions, isEmpty);
      expect(result.status, MessageStatus.sent);
    });

    test('fromJson should handle different message types', () {
      final messageTypes = [
        {'message_type': 'text', 'expected': MessageType.text},
        {'message_type': 'image', 'expected': MessageType.image},
        {'message_type': 'video', 'expected': MessageType.video},
        {'message_type': 'audio', 'expected': MessageType.audio},
      ];

      for (final typeTest in messageTypes) {
        final json = Map<String, dynamic>.from(testJson);
        json['message_type'] = typeTest['message_type'];
        final result = MessageModel.fromJson(json);
        expect(result.type, typeTest['expected']);
      }
    });

    test('fromJson should handle different message statuses', () {
      final statuses = [
        {'status': 'sent', 'expected': MessageStatus.sent},
        {'status': 'delivered', 'expected': MessageStatus.delivered},
        {'status': 'read', 'expected': MessageStatus.read},
        {'status': 'failed', 'expected': MessageStatus.failed},
      ];

      for (final statusTest in statuses) {
        final json = Map<String, dynamic>.from(testJson);
        json['status'] = statusTest['status'];
        final result = MessageModel.fromJson(json);
        expect(result.status, statusTest['expected']);
      }
    });

    test('fromJson should handle media messages', () {
      final json = {
        'id': 'message123',
        'conversation_id': 'conv123',
        'sender_id': 'user123',
        'content': '',
        'message_type': 'image',
        'media_url': 'https://example.com/image.jpg',
        'created_at': testDateTime.toIso8601String(),
        'is_read': false,
        'reactions': <String, String>{},
        'status': 'sent',
      };

      final result = MessageModel.fromJson(json);

      expect(result.type, MessageType.image);
      expect(result.mediaUrl, 'https://example.com/image.jpg');
      expect(result.content, '');
    });

    test('fromJson should handle reactions map', () {
      final json = Map<String, dynamic>.from(testJson);
      json['reactions'] = {
        'user456': '❤️',
        'user789': '👍',
      };

      final result = MessageModel.fromJson(json);

      expect(result.reactions.length, 2);
      expect(result.reactions['user456'], '❤️');
      expect(result.reactions['user789'], '👍');
    });

    test('fromJson should handle empty reactions when field is missing', () {
      final json = Map<String, dynamic>.from(testJson);
      json.remove('reactions');

      final result = MessageModel.fromJson(json);

      expect(result.reactions, isEmpty);
    });

    test('toJson should serialize model correctly', () {
      final model = MessageModel(
        id: 'message123',
        conversationId: 'conv123',
        senderId: 'user123',
        content: 'Hello',
        type: MessageType.text,
        mediaUrl: null,
        createdAt: testDateTime,
        isRead: false,
        reactions: {},
        status: MessageStatus.sent,
      );

      final result = model.toJson();

      expect(result['id'], 'message123');
      expect(result['conversation_id'], 'conv123');
      expect(result['sender_id'], 'user123');
      expect(result['content'], 'Hello');
      expect(result['message_type'], 'text');
      expect(result['media_url'], null);
      expect(result['created_at'], isA<String>());
      expect(result['is_read'], false);
      expect(result['status'], 'sent');
    });

    test('fromJson and toJson should be reversible', () {
      final originalModel = MessageModel.fromJson(testJson);
      final json = originalModel.toJson();
      final restored = MessageModel.fromJson(json);

      expect(restored.id, originalModel.id);
      expect(restored.conversationId, originalModel.conversationId);
      expect(restored.senderId, originalModel.senderId);
      expect(restored.content, originalModel.content);
      expect(restored.type, originalModel.type);
      expect(restored.isRead, originalModel.isRead);
      expect(restored.status, originalModel.status);
    });

    test('toEntity should convert model to entity correctly', () {
      final model = MessageModel(
        id: 'message123',
        conversationId: 'conv123',
        senderId: 'user123',
        content: 'Hello',
        type: MessageType.text,
        mediaUrl: null,
        createdAt: testDateTime,
        isRead: false,
        reactions: {'user456': '❤️'},
        status: MessageStatus.sent,
      );

      final entity = model.toEntity();

      expect(entity, isA<Message>());
      expect(entity.id, model.id);
      expect(entity.conversationId, model.conversationId);
      expect(entity.senderId, model.senderId);
      expect(entity.content, model.content);
      expect(entity.type, model.type);
      expect(entity.mediaUrl, model.mediaUrl);
      expect(entity.isRead, model.isRead);
      expect(entity.reactions, model.reactions);
      expect(entity.status, model.status);
    });

    test('fromEntity should convert entity to model correctly', () {
      final entity = Message(
        id: 'message123',
        conversationId: 'conv123',
        senderId: 'user123',
        content: 'Hello',
        type: MessageType.text,
        mediaUrl: null,
        createdAt: testDateTime,
        isRead: true,
        reactions: {},
        status: MessageStatus.delivered,
      );

      final model = MessageModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.conversationId, entity.conversationId);
      expect(model.senderId, entity.senderId);
      expect(model.content, entity.content);
      expect(model.type, entity.type);
      expect(model.isRead, entity.isRead);
      expect(model.status, entity.status);
    });

    test('should handle long message content', () {
      final longContent = 'A' * 10000;
      final json = Map<String, dynamic>.from(testJson);
      json['content'] = longContent;

      final result = MessageModel.fromJson(json);

      expect(result.content.length, 10000);
      expect(result.content, longContent);
    });

    test('should handle empty message content', () {
      final json = Map<String, dynamic>.from(testJson);
      json['content'] = '';

      final result = MessageModel.fromJson(json);

      expect(result.content, '');
    });

    test('should handle special characters in content', () {
      final specialContent = '😀 Hello! @user #hashtag https://example.com';
      final json = Map<String, dynamic>.from(testJson);
      json['content'] = specialContent;

      final result = MessageModel.fromJson(json);

      expect(result.content, specialContent);
    });

    test('should handle different datetime formats', () {
      final dateFormats = [
        testDateTime.toIso8601String(),
        testDateTime.toString(),
      ];

      for (final dateStr in dateFormats) {
        final json = Map<String, dynamic>.from(testJson);
        json['created_at'] = dateStr;

        final result = MessageModel.fromJson(json);
        expect(result.createdAt, isA<DateTime>());
      }
    });

    test('should handle media URLs with different protocols', () {
      final mediaUrls = [
        'https://example.com/image.jpg',
        'http://example.com/video.mp4',
        'file:///local/audio.mp3',
      ];

      for (final url in mediaUrls) {
        final json = Map<String, dynamic>.from(testJson);
        json['media_url'] = url;

        final result = MessageModel.fromJson(json);
        expect(result.mediaUrl, url);
      }
    });

    test('should preserve reactions when converting to entity and back', () {
      final reactions = {
        'user1': '❤️',
        'user2': '😂',
        'user3': '👍',
      };

      final model = MessageModel(
        id: 'message123',
        conversationId: 'conv123',
        senderId: 'user123',
        content: 'Test',
        type: MessageType.text,
        createdAt: testDateTime,
        isRead: false,
        reactions: reactions,
        status: MessageStatus.sent,
      );

      final entity = model.toEntity();
      final restoredModel = MessageModel.fromEntity(entity);

      expect(restoredModel.reactions, reactions);
      expect(restoredModel.reactions.length, 3);
    });
  });
}
