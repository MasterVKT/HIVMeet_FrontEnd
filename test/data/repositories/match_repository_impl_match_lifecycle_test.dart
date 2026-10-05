import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/data/datasources/remote/matching_api.dart';
import 'package:hivmeet/data/repositories/match_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockMatchingApi extends Mock implements MatchingApi {}

void main() {
  late MockMatchingApi api;
  late MatchRepositoryImpl repository;

  setUp(() {
    api = MockMatchingApi();
    repository = MatchRepositoryImpl(api);
  });

  test('deleteMatch calls the backend endpoint and accepts its 204 response',
      () async {
    when(() => api.deleteMatch('match-1')).thenAnswer(
      (_) async => Response<void>(
        requestOptions: RequestOptions(path: '/matches/match-1'),
        statusCode: 204,
      ),
    );

    final result = await repository.deleteMatch('match-1');

    expect(result.isRight(), isTrue);
    verify(() => api.deleteMatch('match-1')).called(1);
  });

  test('unseen-match endpoints retain the authoritative server count',
      () async {
    when(() => api.getUnseenMatchCount()).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/matches/unseen-count/'),
        statusCode: 200,
        data: const {'unseen_count': 2},
      ),
    );
    when(() => api.markMatchesSeen(['match-1'])).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/matches/seen/'),
        statusCode: 200,
        data: const {'seen_count': 1, 'unseen_count': 1},
      ),
    );

    final initial = await repository.getUnseenMatchCount();
    final remaining = await repository.markMatchesSeen(['match-1']);

    expect(initial.getOrElse(() => -1), 2);
    expect(remaining.getOrElse(() => -1), 1);
    verify(() => api.getUnseenMatchCount()).called(1);
    verify(() => api.markMatchesSeen(['match-1'])).called(1);
  });

  test('rewind exposes the backend domain code instead of a raw Dio error',
      () async {
    final response = Response<Map<String, dynamic>>(
      requestOptions:
          RequestOptions(path: '/discovery/interactions/interaction-1/rewind/'),
      statusCode: 409,
      data: const {
        'code': 'match_exists_use_unmatch',
        'message': 'Remove the match first.',
      },
    );
    when(() => api.rewindInteraction('interaction-1')).thenThrow(
      DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      ),
    );

    final result = await repository.rewindInteraction('interaction-1');

    final failure = result.swap().getOrElse(
          () => const ServerFailure(message: 'expected failure'),
        );
    expect(failure.code, 'match_exists_use_unmatch');
    expect(failure.message, 'Remove the match first.');
  });

  test('match mapping keeps the public profile id and the account id distinct',
      () async {
    when(() => api.getMatches(
        page: any(named: 'page'), pageSize: any(named: 'pageSize'))).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/matches/'),
        statusCode: 200,
        data: const {
          'results': [
            {
              'id': 'match-1',
              'created_at': '2026-09-22T10:00:00Z',
              'is_new': true,
              'matched_user': {
                'id': 'profile-1',
                'user_id': 'user-1',
                'display_name': 'Marie',
                'age': 30,
                'photos': [],
              },
            }
          ],
        },
      ),
    );

    final result = await repository.getMatches();

    final match =
        result.getOrElse(() => throw StateError('expected match')).single;
    expect(match.profile.id, 'profile-1');
    expect(match.profile.userId, 'user-1');
    expect(match.isNew, isTrue);
  });

  test('match mapping retains the server-side Free access permissions',
      () async {
    when(() => api.getMatches(
        page: any(named: 'page'), pageSize: any(named: 'pageSize'))).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/matches/'),
        statusCode: 200,
        data: const {
          'results': [
            {
              'id': 'match-locked',
              'created_at': '2026-09-22T10:00:00Z',
              'access_level': 'locked',
              'can_view_profile': false,
              'can_send_messages': false,
              'free_messages_remaining': 0,
              'access_locked_reason': 'monthly_token_unavailable',
              'matched_user': {
                'id': 'profile-locked',
                'user_id': 'user-locked',
                'display_name': 'Locked match',
                'age': 0,
                'photos': [],
              },
            }
          ],
        },
      ),
    );

    final result = await repository.getMatches();

    final match =
        result.getOrElse(() => throw StateError('expected match')).single;
    expect(match.isLocked, isTrue);
    expect(match.canViewProfile, isFalse);
    expect(match.canSendMessages, isFalse);
    expect(match.freeMessagesRemaining, 0);
    expect(match.accessLockedReason, 'monthly_token_unavailable');
  });
}
