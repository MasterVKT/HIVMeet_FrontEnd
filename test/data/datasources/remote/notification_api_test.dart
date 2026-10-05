import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/network/api_client.dart';
import 'package:hivmeet/data/datasources/remote/notification_api.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  test('does not send legacy synthetic IDs to UUID REST routes', () async {
    final client = MockApiClient();
    final api = NotificationApi(client);

    await api.markAsRead('like_legacy-user');
    await api.deleteNotification('super_like_legacy-user');

    verifyNever(() => client.put<dynamic>(any()));
    verifyNever(() => client.delete<dynamic>(any()));
  });

  test('uses the canonical backend UUID for read and delete', () async {
    const id = '8b1a9953-c461-4f36-9c2b-2a2f9c379f10';
    final client = MockApiClient();
    final api = NotificationApi(client);
    when(() => client.put<dynamic>('notifications/$id/read/'))
        .thenAnswer((_) async => Response<dynamic>(
              requestOptions: RequestOptions(path: 'notifications/$id/read/'),
            ));
    when(() => client.delete<dynamic>('notifications/$id/delete/'))
        .thenAnswer((_) async => Response<dynamic>(
              requestOptions: RequestOptions(path: 'notifications/$id/delete/'),
            ));

    await api.markAsRead(id);
    await api.deleteNotification(id);

    verify(() => client.put<dynamic>('notifications/$id/read/')).called(1);
    verify(() => client.delete<dynamic>('notifications/$id/delete/')).called(1);
  });
}
