// test/domain/usecases/chat/mark_message_as_read_test.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';
import 'package:hivmeet/domain/usecases/chat/mark_message_as_read.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

void main() {
  late MarkMessageAsRead usecase;
  late MockMessageRepository mockRepository;

  setUp(() {
    mockRepository = MockMessageRepository();
    usecase = MarkMessageAsRead(mockRepository);
  });

  const tConversationId = 'conv_1';
  const tMessageId = 'msg_123';
  const tParams = MarkMessageAsReadParams(
    conversationId: tConversationId,
    messageId: tMessageId,
  );

  group('MarkMessageAsRead', () {
    test('should mark message as read successfully', () async {
      // arrange
      when(() => mockRepository.markAsRead(
            conversationId: any(named: 'conversationId'),
            messageId: any(named: 'messageId'),
          )).thenAnswer((_) async => const Right(null));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Right(null));
      verify(() => mockRepository.markAsRead(
            conversationId: tConversationId,
            messageId: tMessageId,
          )).called(1);
    });

    test('should return ServerFailure when repository fails', () async {
      // arrange
      const tFailure = ServerFailure(message: 'Failed to mark as read');

      when(() => mockRepository.markAsRead(
            conversationId: any(named: 'conversationId'),
            messageId: any(named: 'messageId'),
          )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockRepository.markAsRead(
            conversationId: tConversationId,
            messageId: tMessageId,
          )).called(1);
    });

    test('should return NetworkFailure when no internet connection', () async {
      // arrange
      const tFailure = NetworkFailure(message: 'No internet connection');

      when(() => mockRepository.markAsRead(
            conversationId: any(named: 'conversationId'),
            messageId: any(named: 'messageId'),
          )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockRepository.markAsRead(
            conversationId: tConversationId,
            messageId: tMessageId,
          )).called(1);
    });

    test('should return Unauthorized when user is not authenticated', () async {
      // arrange
      const tFailure = Unauthorized(message: 'User not authenticated');

      when(() => mockRepository.markAsRead(
            conversationId: any(named: 'conversationId'),
            messageId: any(named: 'messageId'),
          )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockRepository.markAsRead(
            conversationId: tConversationId,
            messageId: tMessageId,
          )).called(1);
    });

    test('should handle multiple rapid calls to same message', () async {
      // arrange
      when(() => mockRepository.markAsRead(
            conversationId: any(named: 'conversationId'),
            messageId: any(named: 'messageId'),
          )).thenAnswer((_) async => const Right(null));

      // act
      final result1 = await usecase(tParams);
      final result2 = await usecase(tParams);
      final result3 = await usecase(tParams);

      // assert
      expect(result1, const Right(null));
      expect(result2, const Right(null));
      expect(result3, const Right(null));
      verify(() => mockRepository.markAsRead(
            conversationId: tConversationId,
            messageId: tMessageId,
          )).called(3);
    });

    test('should mark different messages in same conversation', () async {
      // arrange
      const tParams1 = MarkMessageAsReadParams(
        conversationId: 'conv_1',
        messageId: 'msg_1',
      );
      const tParams2 = MarkMessageAsReadParams(
        conversationId: 'conv_1',
        messageId: 'msg_2',
      );

      when(() => mockRepository.markAsRead(
            conversationId: any(named: 'conversationId'),
            messageId: any(named: 'messageId'),
          )).thenAnswer((_) async => const Right(null));

      // act
      final result1 = await usecase(tParams1);
      final result2 = await usecase(tParams2);

      // assert
      expect(result1, const Right(null));
      expect(result2, const Right(null));
      verify(() => mockRepository.markAsRead(
            conversationId: 'conv_1',
            messageId: 'msg_1',
          )).called(1);
      verify(() => mockRepository.markAsRead(
            conversationId: 'conv_1',
            messageId: 'msg_2',
          )).called(1);
    });

    test('params should be equatable with same values', () {
      // arrange
      const params1 = MarkMessageAsReadParams(
        conversationId: 'conv_1',
        messageId: 'msg_1',
      );
      const params2 = MarkMessageAsReadParams(
        conversationId: 'conv_1',
        messageId: 'msg_1',
      );

      // assert
      expect(params1, params2);
      expect(params1.hashCode, params2.hashCode);
    });

    test('params should not be equal with different values', () {
      // arrange
      const params1 = MarkMessageAsReadParams(
        conversationId: 'conv_1',
        messageId: 'msg_1',
      );
      const params2 = MarkMessageAsReadParams(
        conversationId: 'conv_1',
        messageId: 'msg_2',
      );

      // assert
      expect(params1, isNot(params2));
    });
  });
}
