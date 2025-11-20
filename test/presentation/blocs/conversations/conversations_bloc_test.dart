// test/presentation/blocs/conversations/conversations_bloc_test.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/usecases/message/get_conversations.dart';
import 'package:hivmeet/domain/usecases/message/send_message.dart';
import 'package:hivmeet/domain/usecases/message/mark_as_read.dart';
import 'package:hivmeet/presentation/blocs/conversations/conversations_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockGetConversations extends Mock implements GetConversations {}

class MockSendMessage extends Mock implements SendMessage {}

class MockMarkAsRead extends Mock implements MarkAsRead {}

void main() {
  late ConversationsBloc bloc;
  late MockGetConversations mockGetConversations;
  late MockSendMessage mockSendMessage;
  late MockMarkAsRead mockMarkAsRead;

  setUp(() {
    mockGetConversations = MockGetConversations();
    mockSendMessage = MockSendMessage();
    mockMarkAsRead = MockMarkAsRead();

    bloc = ConversationsBloc(
      getConversations: mockGetConversations,
      sendMessage: mockSendMessage,
      markAsRead: mockMarkAsRead,
    );

    // Register fallback values
    registerFallbackValue(GetConversationsParams.initial());
    registerFallbackValue(const MarkAsReadParams(conversationId: 'test'));
  });

  tearDown(() {
    bloc.close();
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
        content: 'Hello!',
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
      lastMessage: Message(
        id: 'msg_2',
        conversationId: 'conv_2',
        senderId: 'user_3',
        content: 'Hi there!',
        type: MessageType.text,
        createdAt: DateTime(2024, 1, 20, 14, 00),
        isRead: true,
        reactions: const {},
        status: MessageStatus.sent,
      ),
    ),
  ];

  group('ConversationsBloc', () {
    test('initial state is ConversationsInitial', () {
      expect(bloc.state, equals(ConversationsInitial()));
    });

    group('LoadConversations', () {
      test('should emit [ConversationsLoading, ConversationsLoaded] when successful',
          () async {
        // arrange
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => Right(tConversations));

        // assert later
        final expected = [
          ConversationsLoading(),
          ConversationsLoaded(
            conversations: tConversations,
            allConversations: tConversations,
            hasMore: false, // 2 conversations < 20
            isLoadingMore: false,
            totalUnreadCount: 3, // Only conv_1 has 3 unread
            searchQuery: '',
          ),
        ];
        expectLater(bloc.stream, emitsInOrder(expected));

        // act
        bloc.add(LoadConversations());
      });

      test('should calculate totalUnreadCount correctly', () async {
        // arrange
        final conversationsWithUnread = [
          Conversation(
            id: 'conv_1',
            participantIds: const ['user_1', 'user_2'],
            updatedAt: DateTime.now(),
            unreadCount: 5,
          ),
          Conversation(
            id: 'conv_2',
            participantIds: const ['user_1', 'user_3'],
            updatedAt: DateTime.now(),
            unreadCount: 3,
          ),
          Conversation(
            id: 'conv_3',
            participantIds: const ['user_1', 'user_4'],
            updatedAt: DateTime.now(),
            unreadCount: 0,
          ),
        ];

        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => Right(conversationsWithUnread));

        // act
        bloc.add(LoadConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        // assert
        final state = bloc.state as ConversationsLoaded;
        expect(state.totalUnreadCount, 8); // 5 + 3 + 0 = 8
      });

      test('should set hasMore=true when 20 conversations returned', () async {
        // arrange
        final twentyConversations = List.generate(
          20,
          (i) => Conversation(
            id: 'conv_$i',
            participantIds: const ['user_1', 'user_2'],
            updatedAt: DateTime.now(),
            unreadCount: 0,
          ),
        );

        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => Right(twentyConversations));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            ConversationsLoading(),
            isA<ConversationsLoaded>().having((s) => s.hasMore, 'hasMore', true),
          ]),
        );

        // act
        bloc.add(LoadConversations());
      });

      test('should emit [ConversationsLoading, ConversationsError] when fails',
          () async {
        // arrange
        const tFailure = ServerFailure(message: 'Failed to load conversations');
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => const Left(tFailure));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            ConversationsLoading(),
            const ConversationsError(message: 'Failed to load conversations'),
          ]),
        );

        // act
        bloc.add(LoadConversations());
      });

      test('should reset state when refresh=true', () async {
        // arrange - first load
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => Right(tConversations));
        bloc.add(LoadConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        // act - refresh
        bloc.add(LoadConversations(refresh: true));
        await Future.delayed(const Duration(milliseconds: 100));

        // assert - should call getConversations again
        verify(() => mockGetConversations(any())).called(2);
      });
    });

    group('LoadMoreConversations', () {
      test('should load more conversations with pagination', () async {
        // arrange - initial load
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => Right(tConversations));
        bloc.add(LoadConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        // arrange - load more
        final moreConversations = [
          Conversation(
            id: 'conv_3',
            participantIds: const ['user_1', 'user_4'],
            updatedAt: DateTime(2024, 1, 20, 13, 00),
            unreadCount: 1,
          ),
        ];
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => Right(moreConversations));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ConversationsLoaded>()
                .having((s) => s.isLoadingMore, 'isLoadingMore', true),
            isA<ConversationsLoaded>()
                .having((s) => s.conversations.length, 'length', 3)
                .having((s) => s.isLoadingMore, 'isLoadingMore', false)
                .having((s) => s.totalUnreadCount, 'totalUnread', 4), // 3 + 1
          ]),
        );

        // act
        bloc.add(LoadMoreConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        // assert - should use last conversation ID as cursor
        verify(() => mockGetConversations(any(
              that: isA<GetConversationsParams>().having(
                (p) => p.lastConversationId,
                'lastConversationId',
                'conv_2',
              ),
            ))).called(1);
      });

      test('should set hasMore=false when no more conversations', () async {
        // arrange - initial load
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => Right(tConversations));
        bloc.add(LoadConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        // arrange - load more returns empty
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => const Right([]));

        // act
        bloc.add(LoadMoreConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        // assert
        final state = bloc.state as ConversationsLoaded;
        expect(state.hasMore, false);
      });

      test('should not load more if already loading', () async {
        // arrange
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => Right(tConversations));
        bloc.add(LoadConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        // Manually set isLoadingMore to true
        final currentState = bloc.state as ConversationsLoaded;
        bloc.emit(currentState.copyWith(isLoadingMore: true));

        // Reset mock to track new calls
        reset(mockGetConversations);

        // act
        bloc.add(LoadMoreConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        // assert - should not call getConversations
        verifyNever(() => mockGetConversations(any()));
      });

      test('should emit error when loading more fails', () async {
        // arrange - initial load
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => Right(tConversations));
        bloc.add(LoadConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        // arrange - load more fails
        const tFailure = NetworkFailure(message: 'No internet');
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => const Left(tFailure));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ConversationsLoaded>()
                .having((s) => s.isLoadingMore, 'isLoadingMore', true),
            isA<ConversationsLoaded>()
                .having((s) => s.isLoadingMore, 'isLoadingMore', false),
            const ConversationsError(message: 'No internet'),
          ]),
        );

        // act
        bloc.add(LoadMoreConversations());
      });
    });

    group('RefreshConversations', () {
      test('should delegate to LoadConversations with refresh=true', () async {
        // arrange
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => Right(tConversations));

        // assert later - should emit loading twice (refresh triggers new load)
        expectLater(
          bloc.stream,
          emitsInOrder([
            ConversationsLoading(),
            isA<ConversationsLoaded>(),
          ]),
        );

        // act
        bloc.add(RefreshConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        // assert
        verify(() => mockGetConversations(any())).called(1);
      });
    });

    group('MarkConversationAsRead - Optimistic Update', () {
      test('should optimistically update unread count', () async {
        // arrange - load conversations first
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => Right(tConversations));
        bloc.add(LoadConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        when(() => mockMarkAsRead(any()))
            .thenAnswer((_) async => const Right(null));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ConversationsLoaded>()
                .having((s) => s.totalUnreadCount, 'totalUnread', 0)
                .having(
                  (s) => s.conversations
                      .firstWhere((c) => c.id == 'conv_1')
                      .unreadCount,
                  'conv_1 unreadCount',
                  0,
                ),
          ]),
        );

        // act
        bloc.add(const MarkConversationAsRead(conversationId: 'conv_1'));
      });

      test('should call MarkAsRead use case with correct params', () async {
        // arrange
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => Right(tConversations));
        bloc.add(LoadConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        when(() => mockMarkAsRead(any()))
            .thenAnswer((_) async => const Right(null));

        // act
        bloc.add(const MarkConversationAsRead(conversationId: 'conv_1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // assert
        verify(() => mockMarkAsRead(
              const MarkAsReadParams(conversationId: 'conv_1'),
            )).called(1);
      });
    });

    group('MarkConversationAsRead - Rollback', () {
      test('should rollback on failure', () async {
        // arrange - load conversations
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => Right(tConversations));
        bloc.add(LoadConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        final initialState = bloc.state as ConversationsLoaded;

        // arrange - mark as read fails
        const tFailure = ServerFailure(message: 'Failed to mark as read');
        when(() => mockMarkAsRead(any()))
            .thenAnswer((_) async => const Left(tFailure));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ConversationsLoaded>()
                .having((s) => s.totalUnreadCount, 'totalUnread', 0),
            isA<ConversationsLoaded>()
                .having((s) => s.totalUnreadCount, 'totalUnread', 3), // Rollback
            const ConversationsError(message: 'Failed to mark as read'),
          ]),
        );

        // act
        bloc.add(const MarkConversationAsRead(conversationId: 'conv_1'));
      });
    });

    group('SearchConversations', () {
      test('should filter conversations by last message content', () async {
        // arrange - load conversations
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => Right(tConversations));
        bloc.add(LoadConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ConversationsLoaded>()
                .having((s) => s.conversations.length, 'filtered length', 1)
                .having((s) => s.searchQuery, 'searchQuery', 'hello')
                .having(
                  (s) => s.conversations.first.id,
                  'filtered conv id',
                  'conv_1',
                ),
          ]),
        );

        // act
        bloc.add(const SearchConversations(query: 'hello'));
      });

      test('should return all conversations when query is empty', () async {
        // arrange - load and search first
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => Right(tConversations));
        bloc.add(LoadConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(const SearchConversations(query: 'hello'));
        await Future.delayed(const Duration(milliseconds: 100));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ConversationsLoaded>()
                .having((s) => s.conversations.length, 'all conversations', 2)
                .having((s) => s.searchQuery, 'searchQuery', ''),
          ]),
        );

        // act - clear search
        bloc.add(const SearchConversations(query: ''));
      });

      test('should be case insensitive', () async {
        // arrange
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => Right(tConversations));
        bloc.add(LoadConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        // act
        bloc.add(const SearchConversations(query: 'HELLO'));
        await Future.delayed(const Duration(milliseconds: 100));

        // assert
        final state = bloc.state as ConversationsLoaded;
        expect(state.conversations.length, 1);
        expect(state.conversations.first.id, 'conv_1');
      });

      test('should preserve allConversations while filtering', () async {
        // arrange
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => Right(tConversations));
        bloc.add(LoadConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        // act
        bloc.add(const SearchConversations(query: 'hello'));
        await Future.delayed(const Duration(milliseconds: 100));

        // assert - allConversations should still contain all
        final state = bloc.state as ConversationsLoaded;
        expect(state.conversations.length, 1); // Filtered
        expect(state.allConversations.length, 2); // All preserved
      });
    });

    group('State copyWith', () {
      test('should copy state with updated fields', () async {
        // arrange
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => Right(tConversations));
        bloc.add(LoadConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        final state = bloc.state as ConversationsLoaded;

        // act
        final newState = state.copyWith(
          isLoadingMore: true,
          totalUnreadCount: 10,
        );

        // assert
        expect(newState.isLoadingMore, true);
        expect(newState.totalUnreadCount, 10);
        expect(newState.conversations, state.conversations);
        expect(newState.hasMore, state.hasMore);
        expect(newState.searchQuery, state.searchQuery);
      });
    });
  });
}
