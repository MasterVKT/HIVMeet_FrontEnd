import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/domain/entities/message.dart';

void main() {
  group('Messaging contract mapping', () {
    test('Conversation.fromJson maps other_user metadata', () {
      final conversation = Conversation.fromJson({
        'conversation_id': 'conv-1',
        'other_user': {
          'user_id': 'user-2',
          'display_name': 'Jane',
          'main_photo_url': 'https://example.com/jane.jpg',
          'is_online': true,
          'last_active': '2026-05-21T14:00:00Z',
        },
        'unread_count_for_me': 2,
        'last_activity_at': '2026-05-21T14:05:00Z',
      });

      expect(conversation.id, 'conv-1');
      expect(conversation.participantIds, ['user-2']);
      expect(conversation.otherUserId, 'user-2');
      expect(conversation.otherUserName, 'Jane');
      expect(conversation.otherUserPhotoUrl, 'https://example.com/jane.jpg');
      expect(conversation.isOnline, isTrue);
      expect(conversation.lastActive, DateTime.parse('2026-05-21T14:00:00Z'));
      expect(conversation.unreadCount, 2);
    });

    test('Message.fromJson accepts content_preview for last message previews',
        () {
      final message = Message.fromJson({
        'message_id': 'msg-1',
        'conversation_id': 'conv-1',
        'sender_id': 'user-2',
        'content_preview': 'Hello preview',
        'message_type': 'text',
        'sent_at': '2026-05-21T14:00:00Z',
      });

      expect(message.id, 'msg-1');
      expect(message.content, 'Hello preview');
      expect(message.status, MessageStatus.sent);
    });

    test('Message.fromJson maps the server-authoritative edit timestamp', () {
      final message = Message.fromJson({
        'message_id': 'message-1',
        'conversation_id': 'conversation-1',
        'sender_id': 'user-1',
        'content': 'Edited text',
        'message_type': 'text',
        'sent_at': '2026-09-25T13:55:00Z',
        'edited_at': '2026-09-25T14:00:00Z',
      });

      expect(message.editedAt, DateTime.utc(2026, 9, 25, 14));
      expect(message.toJson()['edited_at'], '2026-09-25T14:00:00.000Z');
    });

    test('Message.fromJson preserves all realtime media fields and text nulls',
        () {
      final media = Message.fromJson({
        'message_id': 'media-1',
        'conversation_id': 'conv-1',
        'sender_id': 'user-2',
        'message_type': 'video',
        'sent_at': '2026-07-26T12:00:00Z',
        'media_url': 'https://example.com/video.mp4',
        'media_type': 'video/mp4',
        'media_thumbnail_url': 'https://example.com/video.jpg',
        'media_download_url':
            '/api/v1/conversations/conv-1/messages/media-1/media/',
        'media_mime_type': 'video/mp4',
        'media_size_bytes': 321,
        'media_file_name': 'video.mp4',
        'media_duration_ms': 1200,
      });
      final text = Message.fromJson({
        'message_id': 'text-1',
        'conversation_id': 'conv-1',
        'sender_id': 'user-2',
        'message_type': 'text',
        'content': 'Hello',
        'sent_at': '2026-07-26T12:00:00Z',
        'media_url': null,
        'media_type': null,
        'media_thumbnail_url': null,
      });

      expect(media.mediaUrl, 'https://example.com/video.mp4');
      expect(media.mediaType, 'video/mp4');
      expect(media.mediaThumbnailUrl, 'https://example.com/video.jpg');
      expect(media.mediaDownloadUrl,
          '/api/v1/conversations/conv-1/messages/media-1/media/');
      expect(media.mediaMimeType, 'video/mp4');
      expect(media.mediaSizeBytes, 321);
      expect(media.mediaFileName, 'video.mp4');
      expect(media.mediaDurationMs, 1200);
      expect(text.mediaUrl, isNull);
      expect(text.mediaType, isNull);
      expect(text.mediaThumbnailUrl, isNull);
    });
  });
}
