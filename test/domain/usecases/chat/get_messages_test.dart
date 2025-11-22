// test/domain/usecases/chat/get_messages_test.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';
import 'package:hivmeet/domain/usecases/chat/get_messages.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

void main() {
  late GetMessages usecase;
  late MockMessageRepository mockRepository;

  setUp(() {
    mockRepository = MockMessageRepository();
    usecase = GetMessages(mockRepository);
  });

  final tMessages = [
    Message(
      id: 'msg_1',
      conversationId: 'conv_1',
      senderId: 'user_1',
      content: 'Hello!',
      type: MessageType.text,
      createdAt: DateTime(2024, 1, 20, 15, 30),
      isRead: true,
      reactions: const {},
      status: MessageStatus.sent,
    ),
    Message(
      id: 'msg_2',
      conversationId: 'conv_1',
      senderId: 'user_2',
      content: 'Hi there!',
      type: MessageType.text,
      createdAt: DateTime(2024, 1, 20, 15, 31),
      isRead: false,
      reactions: const {},
      status: MessageStatus.sent,
    ),
  ];

  group('GetMessages', () {
    test('should get initial messages with default limit (50)', () async {
      // arrange
      when(() => mockRepository.getMessages(
            conversationId: any(named: 'conversationId'),
            limit: any(named: 'limit'),
            beforeMessageId: any(named: 'beforeMessageId'),
          )).thenAnswer((_) async => Right(tMessages));

      // act
      final result = await usecase(GetMessagesParams.initial('conv_1'));

      // assert
      expect(result, Right(tMessages));
      verify(() => mockRepository.getMessages(
            conversationId: 'conv_1',
            limit: 50,
            beforeMessageId: null,
          )).called(1);
    });

    test('should get messages with custom limit', () async {
      // arrange
      when(() => mockRepository.getMessages(
            conversationId: any(named: 'conversationId'),
            limit: any(named: 'limit'),
            beforeMessageId: any(named: 'beforeMessageId'),
          )).thenAnswer((_) async => Right(tMessages));

      // act
      final result = await usecase(
        GetMessagesParams.initial('conv_1', limit: 100),
      );

      // assert
      expect(result, Right(tMessages));
      verify(() => mockRepository.getMessages(
            conversationId: 'conv_1',
            limit: 100,
            beforeMessageId: null,
          )).called(1);
    });

    test('should get messages with pagination cursor (beforeMessageId)',
        () async {
      // arrange
      when(() => mockRepository.getMessages(
            conversationId: any(named: 'conversationId'),
            limit: any(named: 'limit'),
            beforeMessageId: any(named: 'beforeMessageId'),
          )).thenAnswer((_) async => Right(tMessages));

      // act
      final result = await usecase(
        const GetMessagesParams(
          conversationId: 'conv_1',
          limit: 50,
          beforeMessageId: 'msg_50',
        ),
      );

      // assert
      expect(result, Right(tMessages));
      verify(() => mockRepository.getMessages(
            conversationId: 'conv_1',
            limit: 50,
            beforeMessageId: 'msg_50',
          )).called(1);
    });

    test('should return empty list when no more messages', () async {
      // arrange
      when(() => mockRepository.getMessages(
            conversationId: any(named: 'conversationId'),
            limit: any(named: 'limit'),
            beforeMessageId: any(named: 'beforeMessageId'),
          )).thenAnswer((_) async => const Right([]));

      // act
      final result = await usecase(GetMessagesParams.initial('conv_1'));

      // assert
      expect(result, const Right([]));
    });

    test('should return ServerFailure when repository fails', () async {
      // arrange
      const tFailure = ServerFailure(message: 'Failed to fetch messages');
      when(() => mockRepository.getMessages(
            conversationId: any(named: 'conversationId'),
            limit: any(named: 'limit'),
            beforeMessageId: any(named: 'beforeMessageId'),
          )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(GetMessagesParams.initial('conv_1'));

      // assert
      expect(result, const Left(tFailure));
    });

    test('should return NetworkFailure when no internet connection', () async {
      // arrange
      const tFailure = NetworkFailure(message: 'No internet connection');
      when(() => mockRepository.getMessages(
            conversationId: any(named: 'conversationId'),
            limit: any(named: 'limit'),
            beforeMessageId: any(named: 'beforeMessageId'),
          )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(GetMessagesParams.initial('conv_1'));

      // assert
      expect(result, const Left(tFailure));
    });

    test('nextPage helper should preserve limit and add cursor', () {
      // arrange
      final params = GetMessagesParams.initial('conv_1', limit: 30);

      // act
      final nextPageParams = params.nextPage('last_message_id');

      // assert
      expect(nextPageParams.conversationId, 'conv_1');
      expect(nextPageParams.limit, 30);
      expect(nextPageParams.beforeMessageId, 'last_message_id');
    });

    test('initial factory should create params with null beforeMessageId',
        () {
      // act
      final params = GetMessagesParams.initial('conv_1');

      // assert
      expect(params.conversationId, 'conv_1');
      expect(params.limit, 50);
      expect(params.beforeMessageId, null);
    });
  });
}
