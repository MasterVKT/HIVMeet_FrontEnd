// test/domain/usecases/message/get_conversations_test.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';
import 'package:hivmeet/domain/usecases/message/get_conversations.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

void main() {
  late GetConversations usecase;
  late MockMessageRepository mockRepository;

  setUp(() {
    mockRepository = MockMessageRepository();
    usecase = GetConversations(mockRepository);
  });

  final tConversations = [
    Conversation(
      id: 'conv_1',
      participantIds: const ['user_1', 'user_2'],
      updatedAt: DateTime(2024, 1, 20, 15, 30),
      unreadCount: 3,
      lastMessage: Message(
        id: 'msg_1',
        conversationId: 'conv_1',
        senderId: 'user_2',
        content: 'Salut!',
        type: MessageType.text,
        createdAt: DateTime(2024, 1, 20, 15, 30),
        isRead: false,
        reactions: const {},
        status: MessageStatus.sent,
      ),
    ),
    Conversation(
      id: 'conv_2',
      participantIds: const ['user_1', 'user_3'],
      updatedAt: DateTime(2024, 1, 20, 14, 00),
      unreadCount: 0,
    ),
  ];

  group('GetConversations', () {
    test('should get conversations with default params (20 items)', () async {
      // arrange
      when(() => mockRepository.getConversations(
            limit: any(named: 'limit'),
            lastConversationId: any(named: 'lastConversationId'),
          )).thenAnswer((_) async => Right(tConversations));

      // act
      final result = await usecase(GetConversationsParams.initial());

      // assert
      expect(result, Right(tConversations));
      verify(() => mockRepository.getConversations(
            limit: 20,
            lastConversationId: null,
          )).called(1);
    });

    test('should get conversations with custom limit', () async {
      // arrange
      when(() => mockRepository.getConversations(
            limit: any(named: 'limit'),
            lastConversationId: any(named: 'lastConversationId'),
          )).thenAnswer((_) async => Right(tConversations));

      // act
      final result = await usecase(const GetConversationsParams(limit: 50));

      // assert
      expect(result, Right(tConversations));
      verify(() => mockRepository.getConversations(
            limit: 50,
            lastConversationId: null,
          )).called(1);
    });

    test('should get conversations with pagination cursor', () async {
      // arrange
      when(() => mockRepository.getConversations(
            limit: any(named: 'limit'),
            lastConversationId: any(named: 'lastConversationId'),
          )).thenAnswer((_) async => Right(tConversations));

      // act
      final params = GetConversationsParams.initial().nextPage('conv_20');
      final result = await usecase(params);

      // assert
      expect(result, Right(tConversations));
      verify(() => mockRepository.getConversations(
            limit: 20,
            lastConversationId: 'conv_20',
          )).called(1);
    });

    test('should return ServerFailure when repository fails', () async {
      // arrange
      const tFailure = ServerFailure(message: 'Server error');
      when(() => mockRepository.getConversations(
            limit: any(named: 'limit'),
            lastConversationId: any(named: 'lastConversationId'),
          )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(GetConversationsParams.initial());

      // assert
      expect(result, const Left(tFailure));
    });

    test('should return NetworkFailure when no internet', () async {
      // arrange
      const tFailure = NetworkFailure(message: 'No internet connection');
      when(() => mockRepository.getConversations(
            limit: any(named: 'limit'),
            lastConversationId: any(named: 'lastConversationId'),
          )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(GetConversationsParams.initial());

      // assert
      expect(result, const Left(tFailure));
    });

    test('nextPage helper should preserve limit and add cursor', () {
      // arrange
      final params = const GetConversationsParams(limit: 30);

      // act
      final nextPageParams = params.nextPage('last_conv_id');

      // assert
      expect(nextPageParams.limit, 30);
      expect(nextPageParams.lastConversationId, 'last_conv_id');
    });
  });
}
