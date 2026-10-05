import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/network/api_client.dart';
import 'package:hivmeet/data/datasources/remote/messaging_api.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient client;
  late MessagingApi api;

  setUp(() {
    client = MockApiClient();
    api = MessagingApi(client);
  });

  test('serializes the typed unread filter as the supported API status',
      () async {
    when(() => client.get<Map<String, dynamic>>(
          '/conversations/',
          queryParameters: {
            'page': 2,
            'page_size': 30,
            'status': 'unread',
          },
        )).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        data: const {'results': []},
        requestOptions: RequestOptions(path: '/conversations/'),
      ),
    );

    await api.getConversations(
      page: 2,
      pageSize: 30,
      filter: ConversationFilter.unread,
    );

    verify(() => client.get<Map<String, dynamic>>(
          '/conversations/',
          queryParameters: {
            'page': 2,
            'page_size': 30,
            'status': 'unread',
          },
        )).called(1);
  });

  test('deletes a conversation through its collection detail URL', () async {
    when(() => client.delete<void>('/conversations/conv_1/')).thenAnswer(
      (_) async => Response<void>(
        data: null,
        requestOptions: RequestOptions(path: '/conversations/conv_1/'),
        statusCode: 204,
      ),
    );

    await api.deleteConversation('conv_1');

    verify(() => client.delete<void>('/conversations/conv_1/')).called(1);
  });

  test('patches an eligible text message through its detail URL', () async {
    when(() => client.patch<Map<String, dynamic>>(
          '/conversations/conv_1/messages/msg_1/',
          data: const {'content': 'Edited'},
        )).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        data: const {'id': 'msg_1', 'content': 'Edited'},
        requestOptions: RequestOptions(
          path: '/conversations/conv_1/messages/msg_1/',
        ),
      ),
    );

    await api.editMessage(
      conversationId: 'conv_1',
      messageId: 'msg_1',
      content: 'Edited',
    );

    verify(() => client.patch<Map<String, dynamic>>(
          '/conversations/conv_1/messages/msg_1/',
          data: const {'content': 'Edited'},
        )).called(1);
  });

  test('restores a hidden conversation with the idempotent restore URL',
      () async {
    when(() => client.put<void>('/conversations/conv_1/restore/')).thenAnswer(
      (_) async => Response<void>(
        data: null,
        requestOptions: RequestOptions(path: '/conversations/conv_1/restore/'),
        statusCode: 204,
      ),
    );

    await api.restoreConversation('conv_1');

    verify(() => client.put<void>('/conversations/conv_1/restore/')).called(1);
  });

  test('sends the complete WebRTC offer contract for a Premium call', () async {
    when(() => client.post<Map<String, dynamic>>(
          '/conversations/calls/initiate-premium/',
          data: const {
            'target_user_id': 'callee-1',
            'call_type': 'video',
            'offer_sdp': 'offer-sdp',
          },
        )).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        data: const {'id': 'call-1'},
        requestOptions: RequestOptions(
          path: '/conversations/calls/initiate-premium/',
        ),
      ),
    );

    await api.initiatePremiumCall(
      targetUserId: 'callee-1',
      callType: 'video',
      offerSdp: 'offer-sdp',
    );

    verify(() => client.post<Map<String, dynamic>>(
          '/conversations/calls/initiate-premium/',
          data: const {
            'target_user_id': 'callee-1',
            'call_type': 'video',
            'offer_sdp': 'offer-sdp',
          },
        )).called(1);
  });

  test('sends answer SDP and an explicit terminal call reason', () async {
    when(() => client.post<Map<String, dynamic>>(
          '/calls/call-1/answer',
          data: const {'answer_sdp': 'answer-sdp'},
        )).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        data: const {'status': 'answered'},
        requestOptions: RequestOptions(path: '/calls/call-1/answer'),
      ),
    );
    when(() => client.post<Map<String, dynamic>>(
          '/calls/call-1/terminate',
          data: const {'reason': 'ended_by_caller'},
        )).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        data: const {'status': 'ended'},
        requestOptions: RequestOptions(path: '/calls/call-1/terminate'),
      ),
    );

    await api.answerCall(callId: 'call-1', answerSdp: 'answer-sdp');
    await api.endCall(callId: 'call-1', reason: 'ended_by_caller');

    verify(() => client.post<Map<String, dynamic>>(
          '/calls/call-1/answer',
          data: const {'answer_sdp': 'answer-sdp'},
        )).called(1);
    verify(() => client.post<Map<String, dynamic>>(
          '/calls/call-1/terminate',
          data: const {'reason': 'ended_by_caller'},
        )).called(1);
  });
}
