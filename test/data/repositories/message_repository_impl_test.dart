// test/data/repositories/message_repository_impl_test.dart

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/data/datasources/remote/messaging_api.dart';
import 'package:hivmeet/data/repositories/message_repository_impl.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:mocktail/mocktail.dart';

class MockMessagingApi extends Mock implements MessagingApi {}

Response<Map<String, dynamic>> _response(Map<String, dynamic> data) {
  return Response<Map<String, dynamic>>(
    data: data,
    requestOptions: RequestOptions(path: '/test'),
    statusCode: 200,
  );
}

DioException _dioError({required int statusCode, Map<String, dynamic>? data}) {
  final requestOptions = RequestOptions(path: '/test');
  return DioException(
    requestOptions: requestOptions,
    response: Response<Map<String, dynamic>>(
      requestOptions: requestOptions,
      statusCode: statusCode,
      data: data,
    ),
  );
}

void main() {
  late MockMessagingApi mockApi;
  late MessageRepositoryImpl repository;

  setUp(() {
    mockApi = MockMessagingApi();
    repository = MessageRepositoryImpl(mockApi);
  });

  group('getConversations', () {
    test('passes the requested page and derives hasMore from DRF next',
        () async {
      when(() => mockApi.getConversations(
            page: 2,
            pageSize: 20,
            filter: ConversationFilter.unread,
          )).thenAnswer(
        (_) async => _response({
          'results': [
            {
              'conversation_id': 'conv_1',
              'other_user': {'user_id': 'user_2', 'display_name': 'Bob'},
              'unread_count_for_me': 0,
              'last_activity_at': '2024-01-20T15:30:00Z',
            },
          ],
          'next': 'https://api.hivmeet.com/api/v1/conversations/?page=3',
          'previous': null,
        }),
      );

      final result = await repository.getConversations(
        limit: 20,
        page: 2,
        filter: ConversationFilter.unread,
      );

      expect(result.isRight(), true);
      result.fold((_) => fail('expected Right'), (page) {
        expect(page.conversations.length, 1);
        expect(page.conversations.first.otherUserName, 'Bob');
        expect(page.hasMore, true); // 'next' non-null
      });
      verify(() => mockApi.getConversations(
            page: 2,
            pageSize: 20,
            filter: ConversationFilter.unread,
          )).called(1);
    });

    test('hasMore is false when DRF next is null (last page)', () async {
      when(() => mockApi.getConversations(
            page: 1,
            pageSize: 20,
            filter: ConversationFilter.all,
          )).thenAnswer(
        (_) async => _response({'results': [], 'next': null}),
      );

      final result = await repository.getConversations(limit: 20, page: 1);

      result.fold((_) => fail('expected Right'), (page) {
        expect(page.hasMore, false);
      });
    });

    test('maps 401 to AuthFailure', () async {
      when(() => mockApi.getConversations(
            page: 1,
            pageSize: 20,
            filter: ConversationFilter.all,
          )).thenThrow(_dioError(statusCode: 401));

      final result = await repository.getConversations();

      expect(result.isLeft(), true);
      result.fold((failure) => expect(failure, isA<AuthFailure>()),
          (_) => fail('expected Left'));
    });

    test('unexpected (non-Dio) exceptions never leak raw message to the UI',
        () async {
      // Régression: catch (e) => ServerFailure(message: e.toString())
      // exposait le detail brut de l'exception Dart (potentiellement du
      // texte technique ou du contenu sensible) directement dans l'UI.
      when(() => mockApi.getConversations(
            page: 1,
            pageSize: 20,
            filter: ConversationFilter.all,
          )).thenThrow(const FormatException('unexpected raw internal detail'));

      final result = await repository.getConversations();

      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(
            failure.message.contains('unexpected raw internal detail'), false);
      }, (_) => fail('expected Left'));
    });
  });

  group('getMessages', () {
    test('maps a page of messages with hasMore/showPremiumPrompt', () async {
      when(() => mockApi.getConversationMessages(
            conversationId: 'conv_1',
            page: 1,
            pageSize: 50,
            beforeMessageId: null,
          )).thenAnswer(
        (_) async => _response({
          'results': [
            {
              'message_id': 'msg_1',
              'conversation_id': 'conv_1',
              'sender_id': 'user_2',
              'content': 'Hello',
              'message_type': 'text',
              'created_at': '2024-01-20T15:30:00Z',
              'status': 'sent',
            },
          ],
          'has_more': true,
          'show_premium_prompt': true,
        }),
      );

      final result = await repository.getMessages(conversationId: 'conv_1');

      result.fold((_) => fail('expected Right'), (page) {
        expect(page.messages.length, 1);
        expect(page.messages.first.content, 'Hello');
        expect(page.hasMore, true);
        expect(page.showPremiumPrompt, true);
      });
    });

    test('forwards beforeMessageId for cursor pagination', () async {
      when(() => mockApi.getConversationMessages(
            conversationId: 'conv_1',
            page: 1,
            pageSize: 50,
            beforeMessageId: 'msg_5',
          )).thenAnswer((_) async => _response({'results': []}));

      await repository.getMessages(
          conversationId: 'conv_1', beforeMessageId: 'msg_5');

      verify(() => mockApi.getConversationMessages(
            conversationId: 'conv_1',
            page: 1,
            pageSize: 50,
            beforeMessageId: 'msg_5',
          )).called(1);
    });
  });

  group('sendMessage', () {
    test('text message calls sendTextMessage with a client_message_id',
        () async {
      when(() => mockApi.sendTextMessage(
            conversationId: any(named: 'conversationId'),
            content: any(named: 'content'),
            clientMessageId: any(named: 'clientMessageId'),
          )).thenAnswer(
        (_) async => _response({
          'message_id': 'msg_new',
          'conversation_id': 'conv_1',
          'sender_id': 'user_1',
          'content': 'Hi',
          'message_type': 'text',
          'created_at': '2024-01-20T15:30:00Z',
          'status': 'sent',
        }),
      );

      final result = await repository.sendMessage(
        conversationId: 'conv_1',
        content: 'Hi',
      );

      expect(result.isRight(), true);
      final captured = verify(() => mockApi.sendTextMessage(
            conversationId: 'conv_1',
            content: 'Hi',
            clientMessageId: captureAny(named: 'clientMessageId'),
          )).captured;
      expect((captured.single as String).isNotEmpty, true);
    });

    test(
        'media message uses the multipart flow (Option A), not the signed-URL flow',
        () async {
      // Le flux média passe exclusivement par sendMediaMessage multipart.
      final tempFile = File(
          '${Directory.systemTemp.path}/hivmeet_test_image_${DateTime.now().microsecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(List.filled(1024, 0));
      addTearDown(() async {
        if (await tempFile.exists()) await tempFile.delete();
      });

      when(() => mockApi.sendMediaMessage(
            conversationId: any(named: 'conversationId'),
            mediaFilePath: any(named: 'mediaFilePath'),
            mediaType: any(named: 'mediaType'),
            clientMessageId: any(named: 'clientMessageId'),
            text: any(named: 'text'),
          )).thenAnswer(
        (_) async => _response({
          'message_id': 'msg_media',
          'conversation_id': 'conv_1',
          'sender_id': 'user_1',
          'content': '',
          'message_type': 'image',
          'media_url': 'https://cdn.hivmeet.com/messages/conv_1/photo.jpg',
          'created_at': '2024-01-20T15:30:00Z',
          'status': 'sent',
        }),
      );

      final result = await repository.sendMessage(
        conversationId: 'conv_1',
        content: '',
        type: MessageType.image,
        mediaFile: tempFile,
      );

      expect(result.isRight(), true);
      verify(() => mockApi.sendMediaMessage(
            conversationId: 'conv_1',
            mediaFilePath: tempFile.path,
            mediaType: 'image',
            clientMessageId: any(named: 'clientMessageId'),
            text: any(named: 'text'),
          )).called(1);
    });

    test('rejects a media file above the 10MB server limit before uploading',
        () async {
      final bigFile = File(
          '${Directory.systemTemp.path}/hivmeet_test_big_${DateTime.now().microsecondsSinceEpoch}.jpg');
      // 10MB + 1 byte: juste au-dessus de la limite serveur réelle
      // (SendMediaMessageView / SendMediaMessageSerializer).
      await bigFile.writeAsBytes(List.filled(10 * 1024 * 1024 + 1, 0));
      addTearDown(() async {
        if (await bigFile.exists()) await bigFile.delete();
      });

      final result = await repository.sendMessage(
        conversationId: 'conv_1',
        content: '',
        type: MessageType.image,
        mediaFile: bigFile,
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('expected Left'),
      );
      verifyNever(() => mockApi.sendMediaMessage(
            conversationId: any(named: 'conversationId'),
            mediaFilePath: any(named: 'mediaFilePath'),
            mediaType: any(named: 'mediaType'),
            clientMessageId: any(named: 'clientMessageId'),
            text: any(named: 'text'),
          ));
    });
  });

  group('error mapping', () {
    test('maps 403 with error=premium_required to PremiumFailure', () async {
      when(() => mockApi.deleteMessage(
            conversationId: any(named: 'conversationId'),
            messageId: any(named: 'messageId'),
          )).thenThrow(_dioError(
        statusCode: 403,
        data: {'error': 'premium_required', 'message': 'Nope'},
      ));

      final result = await repository.deleteMessage(
          conversationId: 'conv_1', messageId: 'msg_1');

      result.fold((failure) => expect(failure, isA<PremiumFailure>()),
          (_) => fail('expected Left'));
    });

    test(
        'maps a generic 403 (no premium_required) to PermissionFailure, '
        'not PremiumFailure', () async {
      // Régression: auparavant TOUT 403 était mappé sur PremiumFailure,
      // affichant "passez Premium" pour de simples interdictions d'accès
      // (ex: suppression d'un message qui n'est pas le sien).
      when(() => mockApi.deleteMessage(
            conversationId: any(named: 'conversationId'),
            messageId: any(named: 'messageId'),
          )).thenThrow(_dioError(
        statusCode: 403,
        data: {'message': 'You do not have permission to delete this message.'},
      ));

      final result = await repository.deleteMessage(
          conversationId: 'conv_1', messageId: 'msg_1');

      result.fold((failure) => expect(failure, isA<PermissionFailure>()),
          (_) => fail('expected Left'));
    });

    test('maps 402 to PremiumFailure', () async {
      when(() => mockApi.deleteMessage(
            conversationId: any(named: 'conversationId'),
            messageId: any(named: 'messageId'),
          )).thenThrow(_dioError(statusCode: 402));

      final result = await repository.deleteMessage(
          conversationId: 'conv_1', messageId: 'msg_1');

      result.fold((failure) => expect(failure, isA<PremiumFailure>()),
          (_) => fail('expected Left'));
    });

    test('maps connection timeout to NetworkFailure', () async {
      final requestOptions = RequestOptions(path: '/test');
      when(() => mockApi.deleteMessage(
            conversationId: any(named: 'conversationId'),
            messageId: any(named: 'messageId'),
          )).thenThrow(
        DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionTimeout,
        ),
      );

      final result = await repository.deleteMessage(
          conversationId: 'conv_1', messageId: 'msg_1');

      result.fold((failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('expected Left'));
    });
  });

  group('markAsRead', () {
    test('delegates to markMessageAsRead with last_read_message_id', () async {
      when(() => mockApi.markMessageAsRead(
            conversationId: any(named: 'conversationId'),
            lastReadMessageId: any(named: 'lastReadMessageId'),
          )).thenAnswer((_) async => _response({
            'messages_marked': 1,
            'unread_count_for_me': 2,
            'read_at': '2026-07-26T12:00:00Z',
          }));

      final result = await repository.markAsRead(
          conversationId: 'conv_1', messageId: 'msg_1');

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('expected Right'),
        (value) {
          expect(value.messagesMarked, 1);
          expect(value.unreadCountForMe, 2);
          expect(value.readAt, DateTime.utc(2026, 7, 26, 12));
        },
      );
      verify(() => mockApi.markMessageAsRead(
            conversationId: 'conv_1',
            lastReadMessageId: 'msg_1',
          )).called(1);
    });

    test('treats a 204 conversation deletion as success', () async {
      when(() => mockApi.deleteConversation('conv_1')).thenAnswer(
        (_) async => Response<void>(
          data: null,
          requestOptions: RequestOptions(path: '/conversations/conv_1/'),
          statusCode: 204,
        ),
      );

      final result = await repository.deleteConversation('conv_1');

      expect(result.isRight(), isTrue);
      verify(() => mockApi.deleteConversation('conv_1')).called(1);
    });
  });
}
