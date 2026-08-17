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
}
