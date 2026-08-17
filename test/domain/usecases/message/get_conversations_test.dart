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

  setUpAll(() {
    registerFallbackValue(ConversationFilter.all);
  });

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

  final tPage =
      ConversationListPage(conversations: tConversations, hasMore: false);

  group('GetConversations', () {
    test('should get conversations with default params (page 1, 20 items)',
        () async {
      // arrange
      when(() => mockRepository.getConversations(
            limit: any(named: 'limit'),
            page: any(named: 'page'),
            filter: any(named: 'filter'),
          )).thenAnswer((_) async => Right(tPage));

      // act
      final result = await usecase(GetConversationsParams.initial());

      // assert
      expect(result, Right(tPage));
      verify(() => mockRepository.getConversations(
            limit: 20,
            page: 1,
            filter: ConversationFilter.all,
          )).called(1);
    });

    test('should get conversations with custom limit', () async {
      // arrange
      when(() => mockRepository.getConversations(
            limit: any(named: 'limit'),
            page: any(named: 'page'),
            filter: any(named: 'filter'),
          )).thenAnswer((_) async => Right(tPage));

      // act
      final result = await usecase(const GetConversationsParams(limit: 50));

      // assert
      expect(result, Right(tPage));
      verify(() => mockRepository.getConversations(
            limit: 50,
            page: 1,
            filter: ConversationFilter.all,
          )).called(1);
    });

    test('should get conversations for a given page (page-based pagination)',
        () async {
      // Le backend (ConversationListView) est un vrai DRF
      // PageNumberPagination — pas de curseur par ID pour cette ressource.
      when(() => mockRepository.getConversations(
            limit: any(named: 'limit'),
            page: any(named: 'page'),
            filter: any(named: 'filter'),
          )).thenAnswer((_) async => Right(tPage));

      // act
      final params = GetConversationsParams.initial().nextPage(2);
      final result = await usecase(params);

      // assert
      expect(result, Right(tPage));
      verify(() => mockRepository.getConversations(
            limit: 20,
            page: 2,
            filter: ConversationFilter.all,
          )).called(1);
    });

    test('should return ServerFailure when repository fails', () async {
      // arrange
      const tFailure = ServerFailure(message: 'Server error');
      when(() => mockRepository.getConversations(
            limit: any(named: 'limit'),
            page: any(named: 'page'),
            filter: any(named: 'filter'),
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
            page: any(named: 'page'),
            filter: any(named: 'filter'),
          )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(GetConversationsParams.initial());

      // assert
      expect(result, const Left(tFailure));
    });

    test('nextPage helper should preserve limit and advance the page number',
        () {
      // arrange
      const params = GetConversationsParams(limit: 30);

      // act
      final nextPageParams = params.nextPage(2);

      // assert
      expect(nextPageParams.limit, 30);
      expect(nextPageParams.page, 2);
    });

    test('nextPage preserves the active server filter', () {
      final params = GetConversationsParams.initial(
        filter: ConversationFilter.unread,
      );

      final nextPage = params.nextPage(2);

      expect(nextPage.filter, ConversationFilter.unread);
      expect(nextPage.filter.apiValue, 'unread');
    });
  });
}
