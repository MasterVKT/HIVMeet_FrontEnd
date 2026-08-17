// test/presentation/blocs/conversations/conversations_bloc_test.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/usecases/message/get_conversations.dart';
import 'package:hivmeet/domain/usecases/message/send_message.dart';
import 'package:hivmeet/domain/usecases/message/mark_as_read.dart';
import 'package:hivmeet/domain/usecases/message/delete_conversation.dart'
    as delete_conversation;
import 'package:hivmeet/presentation/blocs/conversations/conversations_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockGetConversations extends Mock implements GetConversations {}

class MockSendMessage extends Mock implements SendMessage {}

class MockMarkAsRead extends Mock implements MarkAsRead {}

class MockDeleteConversation extends Mock
    implements delete_conversation.DeleteConversation {}

/// Enveloppe une liste de conversations dans une [ConversationListPage], comme
/// le fait désormais `MessageRepositoryImpl.getConversations` (pagination
/// page-based, `hasMore` dérivé du champ DRF `next`).
Either<Failure, ConversationListPage> _rightPage(
  List<Conversation> conversations, {
  bool hasMore = false,
}) {
  return Right(
      ConversationListPage(conversations: conversations, hasMore: hasMore));
}

void main() {
  late ConversationsBloc bloc;
  late MockGetConversations mockGetConversations;
  late MockSendMessage mockSendMessage;
  late MockMarkAsRead mockMarkAsRead;
  late MockDeleteConversation mockDeleteConversation;
  late RealtimeEventBus realtimeBus;

  setUp(() {
    mockGetConversations = MockGetConversations();
    mockSendMessage = MockSendMessage();
    mockMarkAsRead = MockMarkAsRead();
    mockDeleteConversation = MockDeleteConversation();
    realtimeBus = RealtimeEventBus();

    bloc = ConversationsBloc(
      getConversations: mockGetConversations,
      sendMessage: mockSendMessage,
      markAsRead: mockMarkAsRead,
      deleteConversation: mockDeleteConversation,
      realtimeBus: realtimeBus,
    );

    // Register fallback values
    registerFallbackValue(GetConversationsParams.initial());
    registerFallbackValue(
      const MarkAsReadParams(conversationId: 'test', messageId: 'msg_test'),
    );
    registerFallbackValue(
      const delete_conversation.DeleteConversationParams(
          conversationId: 'test'),
    );
  });

  tearDown(() {
    bloc.close();
    realtimeBus.dispose();
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
      test(
          'should emit [ConversationsLoading, ConversationsLoaded] when successful',
          () async {
        // arrange
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => _rightPage(tConversations));

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
            .thenAnswer((_) async => _rightPage(conversationsWithUnread));

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

        when(() => mockGetConversations(any())).thenAnswer(
            (_) async => _rightPage(twentyConversations, hasMore: true));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            ConversationsLoading(),
            isA<ConversationsLoaded>()
                .having((s) => s.hasMore, 'hasMore', true),
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
            .thenAnswer((_) async => _rightPage(tConversations));
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
        // arrange - initial load must contain 20 items so internal _hasMore is true
        final twentyConversations = List.generate(
          20,
          (i) => Conversation(
            id: 'conv_$i',
            participantIds: const ['user_1', 'user_2'],
            updatedAt: DateTime.now().subtract(Duration(minutes: i)),
            unreadCount: i == 0 ? 3 : 0,
          ),
        );

        when(() => mockGetConversations(any())).thenAnswer(
            (_) async => _rightPage(twentyConversations, hasMore: true));
        bloc.add(LoadConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        // arrange - load more. Uses an id disjoint from the first page:
        // `_sortConversations` dedupes by id (a conversation can legitimately
        // be re-sent across pages if its `updatedAt` shifted), so reusing an
        // id already present on page 1 (e.g. 'conv_3') would collapse the
        // two into one and make the length/unread assertions below wrong.
        final moreConversations = [
          Conversation(
            id: 'conv_20',
            participantIds: const ['user_1', 'user_4'],
            updatedAt: DateTime(2024, 1, 20, 13, 00),
            unreadCount: 1,
          ),
        ];
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => _rightPage(moreConversations));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ConversationsLoaded>()
                .having((s) => s.isLoadingMore, 'isLoadingMore', true),
            isA<ConversationsLoaded>()
                .having((s) => s.conversations.length, 'length', 21)
                .having((s) => s.isLoadingMore, 'isLoadingMore', false)
                .having((s) => s.totalUnreadCount, 'totalUnread', 4), // 3 + 1
          ]),
        );

        // act
        bloc.add(LoadMoreConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        // assert - pagination page-based: page 1 (initial) puis page 2
        // (pas de curseur par ID, le backend est un DRF PageNumberPagination
        // réel pour cette ressource).
        verify(() => mockGetConversations(any(
              that: isA<GetConversationsParams>().having(
                (p) => p.page,
                'page',
                2,
              ),
            ))).called(1);
      });

      test('should set hasMore=false when no more conversations', () async {
        // arrange - initial load
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => _rightPage(tConversations));
        bloc.add(LoadConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        // arrange - load more returns empty
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => _rightPage(const []));

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
            .thenAnswer((_) async => _rightPage(tConversations));
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

      test(
          'should NOT emit ConversationsError when loading more fails '
          '(regression: used to flash an error over the loaded list)',
          () async {
        // arrange - initial load must contain 20 items so internal _hasMore is true
        final twentyConversations = List.generate(
          20,
          (i) => Conversation(
            id: 'conv_$i',
            participantIds: const ['user_1', 'user_2'],
            updatedAt: DateTime.now().subtract(Duration(minutes: i)),
            unreadCount: i == 0 ? 3 : 0,
          ),
        );

        when(() => mockGetConversations(any())).thenAnswer(
            (_) async => _rightPage(twentyConversations, hasMore: true));
        bloc.add(LoadConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        // arrange - load more fails
        const tFailure = NetworkFailure(message: 'No internet');
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => const Left(tFailure));

        // assert later: seulement isLoadingMore true -> false, jamais un
        // ConversationsError qui effacerait temporairement la liste déjà
        // chargée pour un simple échec de pagination.
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ConversationsLoaded>()
                .having((s) => s.isLoadingMore, 'isLoadingMore', true),
            isA<ConversationsLoaded>()
                .having((s) => s.isLoadingMore, 'isLoadingMore', false)
                .having((s) => s.conversations.length, 'still 20', 20),
          ]),
        );

        // act
        bloc.add(LoadMoreConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        // assert - le stream ne doit jamais avoir émis de ConversationsError
        expect(bloc.state, isNot(isA<ConversationsError>()));
      });
    });

    group('RefreshConversations', () {
      test('should delegate to LoadConversations with refresh=true', () async {
        // arrange
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => _rightPage(tConversations));

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

    group('MarkConversationAsRead', () {
      test('uses the server unread count after a successful mark', () async {
        // arrange - load conversations first
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => _rightPage(tConversations));
        bloc.add(LoadConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        when(() => mockMarkAsRead(any())).thenAnswer(
          (_) async => const Right(MarkAsReadResult(
            messagesMarked: 3,
            unreadCountForMe: 0,
          )),
        );

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
            .thenAnswer((_) async => _rightPage(tConversations));
        bloc.add(LoadConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        when(() => mockMarkAsRead(any())).thenAnswer(
          (_) async => const Right(MarkAsReadResult(
            messagesMarked: 3,
            unreadCountForMe: 0,
          )),
        );

        // act
        bloc.add(const MarkConversationAsRead(conversationId: 'conv_1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // assert
        verify(() => mockMarkAsRead(
              const MarkAsReadParams(
                  conversationId: 'conv_1', messageId: 'msg_1'),
            )).called(1);
      });

      test(
          'preserves otherUserName/otherUserPhotoUrl/isOnline (regression: '
          'used to reconstruct Conversation manually and lose these fields)',
          () async {
        // arrange
        final enrichedConversation = Conversation(
          id: 'conv_enriched',
          participantIds: const ['user_1', 'user_9'],
          otherUserId: 'user_9',
          otherUserName: 'Alice',
          otherUserPhotoUrl: 'https://example.com/alice.jpg',
          isOnline: true,
          lastActive: DateTime(2024, 1, 20, 15, 0),
          updatedAt: DateTime(2024, 1, 20, 15, 30),
          unreadCount: 2,
          lastMessage: Message(
            id: 'msg_enriched',
            conversationId: 'conv_enriched',
            senderId: 'user_9',
            content: 'Salut !',
            type: MessageType.text,
            createdAt: DateTime(2024, 1, 20, 15, 30),
            reactions: const {},
            status: MessageStatus.sent,
          ),
        );

        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => _rightPage([enrichedConversation]));
        bloc.add(LoadConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        when(() => mockMarkAsRead(any())).thenAnswer(
          (_) async => const Right(MarkAsReadResult(
            messagesMarked: 2,
            unreadCountForMe: 0,
          )),
        );

        // act
        bloc.add(const MarkConversationAsRead(conversationId: 'conv_enriched'));
        await Future.delayed(const Duration(milliseconds: 100));

        // assert
        final state = bloc.state as ConversationsLoaded;
        final updated =
            state.conversations.firstWhere((c) => c.id == 'conv_enriched');
        expect(updated.unreadCount, 0);
        expect(updated.otherUserName, 'Alice');
        expect(updated.otherUserPhotoUrl, 'https://example.com/alice.jpg');
        expect(updated.isOnline, true);
        expect(updated.otherUserId, 'user_9');
      });
    });

    group('MarkConversationAsRead failure', () {
      test('keeps the list and exposes a transient action error on failure',
          () async {
        // arrange - load conversations
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => _rightPage(tConversations));
        bloc.add(LoadConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        // arrange - mark as read fails
        const tFailure = ServerFailure(message: 'Failed to mark as read');
        when(() => mockMarkAsRead(any()))
            .thenAnswer((_) async => const Left(tFailure));

        expectLater(
          bloc.stream,
          emits(isA<ConversationsLoaded>()
              .having((s) => s.totalUnreadCount, 'totalUnread', 3)
              .having((s) => s.actionError, 'actionError', isNotNull)),
        );

        // act
        bloc.add(const MarkConversationAsRead(conversationId: 'conv_1'));
      });
    });

    group('SearchConversations', () {
      test('should filter conversations by last message content', () async {
        // arrange - load conversations
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => _rightPage(tConversations));
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
            .thenAnswer((_) async => _rightPage(tConversations));
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
            .thenAnswer((_) async => _rightPage(tConversations));
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

      test('should filter conversations by participant name', () async {
        // Régression F35: la recherche ne filtrait auparavant que sur le
        // contenu du dernier message, pas sur le nom du participant — alors
        // que otherUserName est disponible sur l'entité depuis longtemps.
        final withNames = [
          Conversation(
            id: 'conv_alice',
            participantIds: const ['user_1', 'user_9'],
            otherUserName: 'Alice Wonderland',
            updatedAt: DateTime(2024, 1, 20, 15, 0),
            unreadCount: 0,
            lastMessage: Message(
              id: 'msg_a',
              conversationId: 'conv_alice',
              senderId: 'user_9',
              content: 'On se voit quand ?',
              type: MessageType.text,
              createdAt: DateTime(2024, 1, 20, 15, 0),
              reactions: const {},
              status: MessageStatus.sent,
            ),
          ),
          Conversation(
            id: 'conv_bob',
            participantIds: const ['user_1', 'user_8'],
            otherUserName: 'Bob',
            updatedAt: DateTime(2024, 1, 20, 14, 0),
            unreadCount: 0,
            lastMessage: Message(
              id: 'msg_b',
              conversationId: 'conv_bob',
              senderId: 'user_8',
              content: 'Salut',
              type: MessageType.text,
              createdAt: DateTime(2024, 1, 20, 14, 0),
              reactions: const {},
              status: MessageStatus.sent,
            ),
          ),
        ];

        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => _rightPage(withNames));
        bloc.add(LoadConversations());
        await Future.delayed(const Duration(milliseconds: 100));

        // act: recherche par nom, aucun des deux derniers messages ne
        // contient "alice" ou "wonderland".
        bloc.add(const SearchConversations(query: 'wonderland'));
        await Future.delayed(const Duration(milliseconds: 100));

        // assert
        final state = bloc.state as ConversationsLoaded;
        expect(state.conversations.length, 1);
        expect(state.conversations.first.id, 'conv_alice');
      });

      test('should preserve allConversations while filtering', () async {
        // arrange
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => _rightPage(tConversations));
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

    group('Conversation filters and hiding', () {
      test('changes filter, clears search and keeps it on page two', () async {
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => _rightPage(tConversations, hasMore: true));

        bloc.add(LoadConversations());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const SearchConversations(query: 'hello'));
        bloc.add(
            const ChangeConversationFilter(filter: ConversationFilter.unread));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(LoadMoreConversations());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final state = bloc.state as ConversationsLoaded;
        expect(state.activeFilter, ConversationFilter.unread);
        expect(state.searchQuery, isEmpty);
        final captured = verify(() => mockGetConversations(captureAny()))
            .captured
            .cast<GetConversationsParams>();
        expect(captured.last.page, 2);
        expect(captured.last.filter, ConversationFilter.unread);
      });

      test('keeps the optimistic hide when the conversation is already absent',
          () async {
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => _rightPage(tConversations));
        when(() => mockDeleteConversation(any())).thenAnswer(
          (_) async => const Left(ServerFailure(
            message: 'missing',
            code: 'not-found',
          )),
        );

        bloc.add(LoadConversations());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const DeleteConversation(conversationId: 'conv_1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final state = bloc.state as ConversationsLoaded;
        expect(state.allConversations.map((item) => item.id),
            isNot(contains('conv_1')));
        expect(state.totalUnreadCount, 0);
      });

      test('restores the exact snapshot when hiding fails', () async {
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => _rightPage(tConversations));
        when(() => mockDeleteConversation(any())).thenAnswer(
          (_) async => const Left(NetworkFailure(message: 'offline')),
        );

        bloc.add(LoadConversations());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const DeleteConversation(conversationId: 'conv_1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final state = bloc.state as ConversationsLoaded;
        expect(state.allConversations, tConversations);
        expect(state.totalUnreadCount, 3);
        expect(state.actionError, isNotNull);
      });
    });

    group('State copyWith', () {
      test('should copy state with updated fields', () async {
        // arrange
        when(() => mockGetConversations(any()))
            .thenAnswer((_) async => _rightPage(tConversations));
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
