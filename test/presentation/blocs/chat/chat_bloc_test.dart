import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/core/services/authentication_service.dart';
import 'package:hivmeet/core/services/chat_websocket_service.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/entities/user.dart' as domain;
import 'package:hivmeet/domain/usecases/chat/delete_message.dart';
import 'package:hivmeet/domain/usecases/chat/get_messages.dart';
import 'package:hivmeet/domain/usecases/chat/mark_message_as_read.dart';
import 'package:hivmeet/domain/usecases/chat/send_media_message.dart';
import 'package:hivmeet/domain/usecases/chat/send_text_message.dart';
import 'package:hivmeet/domain/usecases/chat/set_typing_status.dart';
import 'package:hivmeet/domain/usecases/profile/block_user.dart';
import 'package:hivmeet/domain/usecases/profile/report_user.dart';
import 'package:hivmeet/presentation/blocs/chat/chat_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockGetMessages extends Mock implements GetMessages {}

class MockSendTextMessage extends Mock implements SendTextMessage {}

class MockSendMediaMessage extends Mock implements SendMediaMessage {}

class MockMarkMessageAsRead extends Mock implements MarkMessageAsRead {}

class MockSetTypingStatusUseCase extends Mock
    implements SetTypingStatusUseCase {}

class MockDeleteMessage extends Mock implements DeleteMessage {}

class MockBlockUser extends Mock implements BlockUser {}

class MockReportUser extends Mock implements ReportUser {}

class MockAuthenticationService extends Mock implements AuthenticationService {}

class MockChatWebSocketService extends Mock implements ChatWebSocketService {}

void main() {
  late ChatBloc bloc;
  late MockGetMessages mockGetMessages;
  late MockSendTextMessage mockSendTextMessage;
  late MockSendMediaMessage mockSendMediaMessage;
  late MockMarkMessageAsRead mockMarkMessageAsRead;
  late MockSetTypingStatusUseCase mockSetTypingStatus;
  late MockDeleteMessage mockDeleteMessage;
  late MockBlockUser mockBlockUser;
  late MockReportUser mockReportUser;
  late MockAuthenticationService mockAuthService;
  late MockChatWebSocketService mockWsService;
  late RealtimeEventBus realtimeBus;

  final tUser = domain.User(
    id: 'user_1',
    email: 'test@test.com',
    displayName: 'Test User',
    isVerified: true,
    isPremium: false,
    lastActive: DateTime.now(),
    isEmailVerified: true,
    notificationSettings: domain.NotificationSettings.defaults(),
    blockedUserIds: const [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final tMessages = [
    Message(
      id: 'msg_1',
      conversationId: 'conv_1',
      senderId: 'user_2',
      content: 'Hello',
      type: MessageType.text,
      createdAt: DateTime(2024, 1, 20, 10, 0),
      isRead: false,
      reactions: const {},
      status: MessageStatus.sent,
    ),
    Message(
      id: 'msg_2',
      conversationId: 'conv_1',
      senderId: 'user_1',
      content: 'Hi!',
      type: MessageType.text,
      createdAt: DateTime(2024, 1, 20, 10, 1),
      isRead: true,
      reactions: const {},
      status: MessageStatus.read,
    ),
  ];

  setUp(() {
    mockGetMessages = MockGetMessages();
    mockSendTextMessage = MockSendTextMessage();
    mockSendMediaMessage = MockSendMediaMessage();
    mockMarkMessageAsRead = MockMarkMessageAsRead();
    mockSetTypingStatus = MockSetTypingStatusUseCase();
    mockDeleteMessage = MockDeleteMessage();
    mockBlockUser = MockBlockUser();
    mockReportUser = MockReportUser();
    mockAuthService = MockAuthenticationService();
    mockWsService = MockChatWebSocketService();
    realtimeBus = RealtimeEventBus();

    bloc = ChatBloc(
      getMessages: mockGetMessages,
      sendTextMessage: mockSendTextMessage,
      sendMediaMessage: mockSendMediaMessage,
      markMessageAsRead: mockMarkMessageAsRead,
      setTypingStatus: mockSetTypingStatus,
      deleteMessage: mockDeleteMessage,
      blockUser: mockBlockUser,
      reportUser: mockReportUser,
      authService: mockAuthService,
      wsService: mockWsService,
      realtimeBus: realtimeBus,
    );

    registerFallbackValue(const GetMessagesParams(conversationId: 'conv_1'));
    registerFallbackValue(
        const SendTextMessageParams(conversationId: 'conv_1', content: 'x'));
    registerFallbackValue(
      SendMediaMessageParams(
        conversationId: 'conv_1',
        mediaFile: File('x'),
        type: MessageType.image,
      ),
    );
    registerFallbackValue(const MarkMessageAsReadParams(
        conversationId: 'conv_1', messageId: 'msg_1'));
    registerFallbackValue(
        const SetTypingStatusParams(conversationId: 'conv_1', isTyping: false));
    registerFallbackValue(const DeleteMessageParams(
        conversationId: 'conv_1', messageId: 'msg_1'));
    registerFallbackValue(const BlockUserParams(userId: 'user_2'));
    registerFallbackValue(
        const ReportUserParams(userId: 'user_2', reason: 'other'));
  });

  tearDown(() async {
    await bloc.close();
    realtimeBus.dispose();
  });

  Future<void> loadAndConnectWebSocket(
    StreamController<WsEvent> eventsController,
    List<Message> messages,
  ) async {
    when(() => mockGetMessages(any())).thenAnswer(
      (_) async => Right(
        ConversationMessagesPage(
          messages: messages,
          hasMore: false,
          showPremiumPrompt: false,
        ),
      ),
    );
    when(() => mockAuthService.currentUser).thenReturn(tUser);
    when(() => mockAuthService.getAccessToken()).thenAnswer((_) async => 'jwt');
    when(
      () => mockWsService.connect(
        conversationId: any(named: 'conversationId'),
        token: any(named: 'token'),
        onNeedFreshToken: any(named: 'onNeedFreshToken'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockWsService.events).thenAnswer((_) => eventsController.stream);

    bloc.add(const LoadConversation(conversationId: 'conv_1'));
    await untilCalled(() => mockGetMessages(any()));
    await Future<void>.delayed(Duration.zero);

    bloc.add(const ConnectToWebSocket());
    await untilCalled(
      () => mockWsService.connect(
        conversationId: 'conv_1',
        token: 'jwt',
        onNeedFreshToken: any(named: 'onNeedFreshToken'),
      ),
    );
    // `untilCalled` resolves the instant the mocked `connect(...)` call is
    // recorded — which happens *before* `_onConnectWebSocket`'s `await` on
    // it completes and control reaches `_wsService.events.listen(...)`.
    // Without this pump, an event published right after this helper returns
    // can race ahead of the subscription and be lost forever on the
    // broadcast stream (no replay for late subscribers).
    await Future<void>.delayed(Duration.zero);
  }

  group('ChatBloc', () {
    test('initial state is ChatInitial', () {
      expect(bloc.state, equals(ChatInitial()));
    });

    test('LoadConversation emits loading then loaded with page metadata',
        () async {
      final page = ConversationMessagesPage(
        messages: tMessages,
        hasMore: true,
        showPremiumPrompt: false,
      );
      when(() => mockGetMessages(any())).thenAnswer((_) async => Right(page));

      final emission = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ChatLoading>(),
          isA<ChatLoaded>()
              .having((s) => s.messages.length, 'messages', 2)
              .having((s) => s.hasMore, 'hasMore', true),
        ]),
      );

      bloc.add(const LoadConversation(conversationId: 'conv_1'));
      await emission;
    });

    test('LoadConversation emits error on failure', () async {
      when(() => mockGetMessages(any()))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'boom')));

      final emission = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ChatLoading>(),
          const ChatError(message: 'boom'),
        ]),
      );

      bloc.add(const LoadConversation(conversationId: 'conv_1'));
      await emission;
    });

    test('LoadMoreMessages paginates with oldest message id', () async {
      when(() => mockGetMessages(any())).thenAnswer(
        (_) async => Right(
          ConversationMessagesPage(
            messages: tMessages,
            hasMore: true,
            showPremiumPrompt: false,
          ),
        ),
      );

      bloc.add(const LoadConversation(conversationId: 'conv_1'));
      await untilCalled(() => mockGetMessages(any()));
      clearInteractions(mockGetMessages);

      final older = Message(
        id: 'msg_0',
        conversationId: 'conv_1',
        senderId: 'user_2',
        content: 'Older',
        type: MessageType.text,
        createdAt: DateTime(2024, 1, 20, 9, 0),
        isRead: true,
        reactions: const {},
        status: MessageStatus.read,
      );

      when(() => mockGetMessages(any())).thenAnswer(
        (_) async => Right(
          ConversationMessagesPage(
            messages: [older],
            hasMore: false,
            showPremiumPrompt: false,
          ),
        ),
      );

      final emission = expectLater(
        bloc.stream,
        emitsThrough(
          isA<ChatLoaded>()
              .having((s) => s.messages.first.id, 'first id', 'msg_0'),
        ),
      );

      bloc.add(LoadMoreMessages());
      await untilCalled(() => mockGetMessages(any()));
      await emission;

      final captured = verify(() => mockGetMessages(captureAny())).captured.last
          as GetMessagesParams;
      expect(captured.beforeMessageId, 'msg_1');
    });

    test('SendTextMessage success eventually emits server message', () async {
      when(() => mockAuthService.currentUser).thenReturn(tUser);
      when(() => mockGetMessages(any())).thenAnswer(
        (_) async => Right(
          ConversationMessagesPage(
              messages: tMessages, hasMore: false, showPremiumPrompt: false),
        ),
      );
      bloc.add(const LoadConversation(conversationId: 'conv_1'));
      await untilCalled(() => mockGetMessages(any()));

      final sent = Message(
        id: 'msg_server',
        conversationId: 'conv_1',
        senderId: 'user_1',
        content: 'New message',
        type: MessageType.text,
        createdAt: DateTime.now(),
        isRead: false,
        reactions: const {},
        status: MessageStatus.sent,
      );
      when(() => mockSendTextMessage(any()))
          .thenAnswer((_) async => Right(sent));

      final emission = expectLater(
        bloc.stream,
        emitsThrough(
          isA<ChatLoaded>()
              .having((s) => s.messages.last.id, 'id', 'msg_server'),
        ),
      );

      bloc.add(const SendTextMessageEvent(content: 'New message'));
      await untilCalled(() => mockSendTextMessage(any()));
      await emission;
    });

    test('SendTextMessage failure eventually emits failed temp message',
        () async {
      when(() => mockAuthService.currentUser).thenReturn(tUser);
      when(() => mockGetMessages(any())).thenAnswer(
        (_) async => Right(
          ConversationMessagesPage(
              messages: tMessages, hasMore: false, showPremiumPrompt: false),
        ),
      );
      bloc.add(const LoadConversation(conversationId: 'conv_1'));
      await untilCalled(() => mockGetMessages(any()));

      when(() => mockSendTextMessage(any())).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'send failed')),
      );

      final emission = expectLater(
        bloc.stream,
        emitsThrough(
          isA<ChatLoaded>().having(
              (s) => s.messages.last.status, 'status', MessageStatus.failed),
        ),
      );

      bloc.add(const SendTextMessageEvent(content: 'New message'));
      await untilCalled(() => mockSendTextMessage(any()));
      await emission;
    });

    test('MarkAsRead delegates to usecase', () async {
      when(() => mockGetMessages(any())).thenAnswer(
        (_) async => Right(
          ConversationMessagesPage(
              messages: tMessages, hasMore: false, showPremiumPrompt: false),
        ),
      );
      when(() => mockMarkMessageAsRead(any())).thenAnswer(
        (_) async => const Right(MarkAsReadResult(
          messagesMarked: 1,
          unreadCountForMe: 0,
        )),
      );

      bloc.add(const LoadConversation(conversationId: 'conv_1'));
      await untilCalled(() => mockGetMessages(any()));

      bloc.add(const MarkAsReadEvent(messageId: 'msg_1'));
      await untilCalled(() => mockMarkMessageAsRead(any()));

      verify(() => mockMarkMessageAsRead(
            const MarkMessageAsReadParams(
                conversationId: 'conv_1', messageId: 'msg_1'),
          )).called(1);
    });

    test('coalesces rapid visible-message acknowledgements and updates state',
        () async {
      when(() => mockGetMessages(any())).thenAnswer(
        (_) async => Right(ConversationMessagesPage(
          messages: tMessages,
          hasMore: false,
          showPremiumPrompt: false,
        )),
      );
      final completion = Completer<Either<Failure, MarkAsReadResult>>();
      when(() => mockMarkMessageAsRead(any()))
          .thenAnswer((_) => completion.future);

      bloc.add(const LoadConversation(conversationId: 'conv_1'));
      await untilCalled(() => mockGetMessages(any()));
      await Future<void>.delayed(Duration.zero);

      bloc.add(const MarkUnreadMessagesAsRead());
      bloc.add(const MarkUnreadMessagesAsRead());
      await untilCalled(() => mockMarkMessageAsRead(any()));
      verify(() => mockMarkMessageAsRead(any())).called(1);

      completion.complete(const Right(MarkAsReadResult(
        messagesMarked: 1,
        unreadCountForMe: 0,
      )));
      await Future<void>.delayed(Duration.zero);

      expect((bloc.state as ChatLoaded).messages.first.isRead, isTrue);
    });

    test('retries a visible-message acknowledgement after a failure', () async {
      when(() => mockGetMessages(any())).thenAnswer(
        (_) async => Right(ConversationMessagesPage(
          messages: tMessages,
          hasMore: false,
          showPremiumPrompt: false,
        )),
      );
      when(() => mockMarkMessageAsRead(any())).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'temporary failure')),
      );

      bloc.add(const LoadConversation(conversationId: 'conv_1'));
      await untilCalled(() => mockGetMessages(any()));
      await Future<void>.delayed(Duration.zero);

      bloc.add(const MarkUnreadMessagesAsRead());
      await untilCalled(() => mockMarkMessageAsRead(any()));
      bloc.add(const MarkUnreadMessagesAsRead());
      await Future<void>.delayed(Duration.zero);

      verify(() => mockMarkMessageAsRead(any())).called(2);
      expect((bloc.state as ChatLoaded).messages.first.isRead, isFalse);
    });

    test(
        'SetTypingStatus does not simulate own isTyping locally (only WS inbound does)',
        () async {
      // Régression: _onSetTypingStatus émettait auparavant
      // copyWith(isTyping: currentState.isTyping) — un no-op trompeur.
      // isTyping ne doit refléter QUE l'état de frappe de l'interlocuteur,
      // jamais le sien propre.
      when(() => mockGetMessages(any())).thenAnswer(
        (_) async => Right(
          ConversationMessagesPage(
              messages: tMessages, hasMore: false, showPremiumPrompt: false),
        ),
      );
      when(() => mockSetTypingStatus(any()))
          .thenAnswer((_) async => const Right(null));
      when(() => mockWsService.isConnected).thenReturn(false);

      bloc.add(const LoadConversation(conversationId: 'conv_1'));
      await untilCalled(() => mockGetMessages(any()));

      bloc.add(const SetTypingStatus(isTyping: true));
      await untilCalled(() => mockSetTypingStatus(any()));

      final state = bloc.state as ChatLoaded;
      expect(state.isTyping, false);
    });

    test('two rapid text sends produce distinct client_message_id', () async {
      when(() => mockAuthService.currentUser).thenReturn(tUser);
      when(() => mockGetMessages(any())).thenAnswer(
        (_) async => Right(
          ConversationMessagesPage(
              messages: tMessages, hasMore: false, showPremiumPrompt: false),
        ),
      );
      bloc.add(const LoadConversation(conversationId: 'conv_1'));
      await untilCalled(() => mockGetMessages(any()));

      when(() => mockSendTextMessage(any())).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'pending')),
      );

      bloc.add(const SendTextMessageEvent(content: 'first'));
      bloc.add(const SendTextMessageEvent(content: 'second'));
      await untilCalled(() => mockSendTextMessage(any()));
      await Future.delayed(const Duration(milliseconds: 50));

      final captured = verify(() => mockSendTextMessage(captureAny()))
          .captured
          .cast<SendTextMessageParams>();
      expect(captured.length, 2);
      expect(captured[0].clientMessageId, isNot(captured[1].clientMessageId));
    });

    test('websocket media messages preserve URL, type and thumbnail', () async {
      final eventsController = StreamController<WsEvent>.broadcast();
      addTearDown(eventsController.close);
      await loadAndConnectWebSocket(eventsController, tMessages);

      final nextLoaded = bloc.stream.firstWhere((state) {
        return state is ChatLoaded &&
            state.messages.any((message) => message.id == 'media_1');
      });
      eventsController.add(const WsEvent(
        type: WsEventType.messageCreated,
        data: {
          'message_id': 'media_1',
          'conversation_id': 'conv_1',
          'sender_id': 'user_2',
          'message_type': 'image',
          'content': '',
          'sent_at': '2026-07-26T12:00:00Z',
          'media_url': 'https://cdn.example/media.jpg',
          'media_type': 'image/jpeg',
          'media_thumbnail_url': 'https://cdn.example/thumb.jpg',
        },
      ));

      final state = (await nextLoaded) as ChatLoaded;
      final message = state.messages.firstWhere((item) => item.id == 'media_1');
      expect(message.mediaUrl, 'https://cdn.example/media.jpg');
      expect(message.mediaType, 'image/jpeg');
      expect(message.mediaThumbnailUrl, 'https://cdn.example/thumb.jpg');
    });

    test('read receipt marks only the targeted local message as read',
        () async {
      final eventsController = StreamController<WsEvent>.broadcast();
      addTearDown(eventsController.close);
      final readAt = DateTime.utc(2026, 7, 25, 15);
      final messages = [
        Message(
          id: 'outgoing',
          conversationId: 'conv_1',
          senderId: 'user_1',
          isMine: true,
          content: 'Sent by me',
          type: MessageType.text,
          createdAt: DateTime(2026, 7, 25, 14, 59),
          isRead: false,
          reactions: const {},
          status: MessageStatus.sent,
        ),
        Message(
          id: 'incoming',
          conversationId: 'conv_1',
          senderId: 'user_2',
          content: 'Sent by the other participant',
          type: MessageType.text,
          createdAt: DateTime(2026, 7, 25, 15),
          isRead: false,
          reactions: const {},
          status: MessageStatus.sent,
        ),
      ];
      await loadAndConnectWebSocket(eventsController, messages);

      final updatedState = bloc.stream
          .where((state) => state is ChatLoaded)
          .cast<ChatLoaded>()
          .firstWhere(
            (state) =>
                state.messages
                    .firstWhere((message) => message.id == 'outgoing')
                    .status ==
                MessageStatus.read,
          );
      eventsController.add(WsEvent(
        type: WsEventType.messageRead,
        data: {
          'reader_id': 'user_2',
          'message_ids': ['outgoing'],
          'read_at': readAt.toIso8601String(),
        },
      ));

      final state = await updatedState;
      final outgoing =
          state.messages.firstWhere((message) => message.id == 'outgoing');
      final incoming =
          state.messages.firstWhere((message) => message.id == 'incoming');
      expect(outgoing.status, MessageStatus.read);
      expect(outgoing.isRead, isTrue);
      expect(outgoing.readAt, readAt);
      expect(outgoing.readAtByRecipient, readAt);
      expect(incoming.status, MessageStatus.sent);
      expect(incoming.isRead, isFalse);
    });

    test('read receipt leaves untargeted and received messages unchanged',
        () async {
      final eventsController = StreamController<WsEvent>.broadcast();
      addTearDown(eventsController.close);
      final messages = [
        Message(
          id: 'outgoing-targeted',
          conversationId: 'conv_1',
          senderId: 'user_1',
          isMine: true,
          content: 'Targeted',
          type: MessageType.text,
          createdAt: DateTime(2026, 7, 25, 14, 59),
          reactions: const {},
          status: MessageStatus.sent,
        ),
        Message(
          id: 'outgoing-untargeted',
          conversationId: 'conv_1',
          senderId: 'user_1',
          isMine: true,
          content: 'Untargeted',
          type: MessageType.text,
          createdAt: DateTime(2026, 7, 25, 15),
          reactions: const {},
          status: MessageStatus.sent,
        ),
        Message(
          id: 'incoming-targeted',
          conversationId: 'conv_1',
          senderId: 'user_2',
          content: 'Received',
          type: MessageType.text,
          createdAt: DateTime(2026, 7, 25, 15, 1),
          reactions: const {},
          status: MessageStatus.sent,
        ),
      ];
      await loadAndConnectWebSocket(eventsController, messages);

      final updatedState = bloc.stream
          .where((state) => state is ChatLoaded)
          .cast<ChatLoaded>()
          .first;
      eventsController.add(const WsEvent(
        type: WsEventType.messageRead,
        data: {
          'reader_id': 'user_2',
          'message_ids': ['outgoing-targeted', 'incoming-targeted', 'missing'],
        },
      ));

      final state = await updatedState;
      expect(
        state.messages
            .firstWhere((message) => message.id == 'outgoing-targeted')
            .status,
        MessageStatus.read,
      );
      expect(
        state.messages
            .firstWhere((message) => message.id == 'outgoing-untargeted')
            .status,
        MessageStatus.sent,
      );
      expect(
        state.messages
            .firstWhere((message) => message.id == 'incoming-targeted')
            .status,
        MessageStatus.sent,
      );
    });

    test('read receipt sent by the current user is ignored', () async {
      final eventsController = StreamController<WsEvent>.broadcast();
      addTearDown(eventsController.close);
      final message = Message(
        id: 'outgoing',
        conversationId: 'conv_1',
        senderId: 'user_1',
        isMine: true,
        content: 'Sent by me',
        type: MessageType.text,
        createdAt: DateTime(2026, 7, 25, 14, 59),
        reactions: const {},
        status: MessageStatus.sent,
      );
      await loadAndConnectWebSocket(eventsController, [message]);

      eventsController.add(const WsEvent(
        type: WsEventType.messageRead,
        data: {
          'reader_id': 'user_1',
          'message_ids': ['outgoing'],
        },
      ));
      await Future<void>.delayed(Duration.zero);

      final state = bloc.state as ChatLoaded;
      expect(state.messages.single.status, MessageStatus.sent);
      expect(state.messages.single.isRead, isFalse);
    });

    test('invalid read receipt data is ignored without emitting an error',
        () async {
      final eventsController = StreamController<WsEvent>.broadcast();
      addTearDown(eventsController.close);
      final message = Message(
        id: 'outgoing',
        conversationId: 'conv_1',
        senderId: 'user_1',
        isMine: true,
        content: 'Sent by me',
        type: MessageType.text,
        createdAt: DateTime(2026, 7, 25, 14, 59),
        reactions: const {},
        status: MessageStatus.sent,
      );
      await loadAndConnectWebSocket(eventsController, [message]);

      for (final event in const [
        WsEvent(
          type: WsEventType.messageRead,
          data: {'reader_id': 'user_2'},
        ),
        WsEvent(
          type: WsEventType.messageRead,
          data: {'reader_id': 'user_2', 'message_ids': []},
        ),
        WsEvent(
          type: WsEventType.messageRead,
          data: {'reader_id': 'user_2', 'message_ids': 'not-a-list'},
        ),
        WsEvent(
          type: WsEventType.messageRead,
          data: {
            'message_ids': ['outgoing']
          },
        ),
      ]) {
        eventsController.add(event);
      }
      await Future<void>.delayed(Duration.zero);

      final state = bloc.state as ChatLoaded;
      expect(state.messages.single.status, MessageStatus.sent);
      expect(state, isNot(isA<ChatError>()));
    });

    test('an invalid read_at still marks the targeted local message as read',
        () async {
      final eventsController = StreamController<WsEvent>.broadcast();
      addTearDown(eventsController.close);
      final previousReadAt = DateTime.utc(2026, 7, 25, 14, 50);
      final message = Message(
        id: 'outgoing',
        conversationId: 'conv_1',
        senderId: 'user_1',
        isMine: true,
        content: 'Sent by me',
        type: MessageType.text,
        createdAt: DateTime(2026, 7, 25, 14, 59),
        readAt: previousReadAt,
        readAtByRecipient: previousReadAt,
        reactions: const {},
        status: MessageStatus.sent,
      );
      await loadAndConnectWebSocket(eventsController, [message]);

      final updatedState = bloc.stream
          .where((state) => state is ChatLoaded)
          .cast<ChatLoaded>()
          .first;
      eventsController.add(const WsEvent(
        type: WsEventType.messageRead,
        data: {
          'reader_id': 'user_2',
          'message_ids': ['outgoing'],
          'read_at': 'not-a-date',
        },
      ));

      final state = await updatedState;
      expect(state.messages.single.status, MessageStatus.read);
      expect(state.messages.single.isRead, isTrue);
      expect(state.messages.single.readAt, previousReadAt);
      expect(state.messages.single.readAtByRecipient, previousReadAt);
    });

    test('identical read receipts are idempotent', () async {
      final eventsController = StreamController<WsEvent>.broadcast();
      addTearDown(eventsController.close);
      final message = Message(
        id: 'outgoing',
        conversationId: 'conv_1',
        senderId: 'user_1',
        isMine: true,
        content: 'Sent by me',
        type: MessageType.text,
        createdAt: DateTime(2026, 7, 25, 14, 59),
        reactions: const {},
        status: MessageStatus.sent,
      );
      const receipt = WsEvent(
        type: WsEventType.messageRead,
        data: {
          'reader_id': 'user_2',
          'message_ids': ['outgoing'],
          'read_at': '2026-07-25T15:00:00.000000Z',
        },
      );
      await loadAndConnectWebSocket(eventsController, [message]);

      final firstUpdate = bloc.stream
          .where((state) => state is ChatLoaded)
          .cast<ChatLoaded>()
          .first;
      eventsController.add(receipt);
      await firstUpdate;

      var duplicateEmissions = 0;
      final subscription = bloc.stream.listen((_) => duplicateEmissions++);
      eventsController.add(receipt);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      final state = bloc.state as ChatLoaded;
      expect(state.messages.single.status, MessageStatus.read);
      expect(duplicateEmissions, isZero);
    });
  });
}
