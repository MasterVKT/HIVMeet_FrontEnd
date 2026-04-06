import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/services/authentication_service.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/entities/user.dart' as domain;
import 'package:hivmeet/domain/usecases/chat/get_messages.dart';
import 'package:hivmeet/domain/usecases/chat/mark_message_as_read.dart';
import 'package:hivmeet/domain/usecases/chat/send_media_message.dart';
import 'package:hivmeet/domain/usecases/chat/send_text_message.dart';
import 'package:hivmeet/presentation/blocs/chat/chat_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockGetMessages extends Mock implements GetMessages {}

class MockSendTextMessage extends Mock implements SendTextMessage {}

class MockSendMediaMessage extends Mock implements SendMediaMessage {}

class MockMarkMessageAsRead extends Mock implements MarkMessageAsRead {}

class MockAuthenticationService extends Mock implements AuthenticationService {}

void main() {
  late ChatBloc bloc;
  late MockGetMessages mockGetMessages;
  late MockSendTextMessage mockSendTextMessage;
  late MockSendMediaMessage mockSendMediaMessage;
  late MockMarkMessageAsRead mockMarkMessageAsRead;
  late MockAuthenticationService mockAuthService;

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
    mockAuthService = MockAuthenticationService();

    bloc = ChatBloc(
      getMessages: mockGetMessages,
      sendTextMessage: mockSendTextMessage,
      sendMediaMessage: mockSendMediaMessage,
      markMessageAsRead: mockMarkMessageAsRead,
      authService: mockAuthService,
    );

    registerFallbackValue(const GetMessagesParams(conversationId: 'conv_1'));
    registerFallbackValue(const SendTextMessageParams(conversationId: 'conv_1', content: 'x'));
    registerFallbackValue(
      SendMediaMessageParams(
        conversationId: 'conv_1',
        mediaFile: File('x'),
        type: MessageType.image,
      ),
    );
    registerFallbackValue(const MarkMessageAsReadParams(conversationId: 'conv_1', messageId: 'msg_1'));
  });

  tearDown(() async {
    await bloc.close();
  });

  group('ChatBloc', () {
    test('initial state is ChatInitial', () {
      expect(bloc.state, equals(ChatInitial()));
    });

    test('LoadConversation emits loading then loaded with page metadata', () async {
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
          isA<ChatLoaded>().having((s) => s.messages.first.id, 'first id', 'msg_0'),
        ),
      );

      bloc.add(LoadMoreMessages());
      await untilCalled(() => mockGetMessages(any()));
      await emission;

      final captured = verify(() => mockGetMessages(captureAny())).captured.last as GetMessagesParams;
      expect(captured.beforeMessageId, 'msg_1');
    });

    test('SendTextMessage success eventually emits server message', () async {
      when(() => mockAuthService.currentUser).thenReturn(tUser);
      when(() => mockGetMessages(any())).thenAnswer(
        (_) async => Right(
          ConversationMessagesPage(messages: tMessages, hasMore: false, showPremiumPrompt: false),
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
      when(() => mockSendTextMessage(any())).thenAnswer((_) async => Right(sent));

      final emission = expectLater(
        bloc.stream,
        emitsThrough(
          isA<ChatLoaded>().having((s) => s.messages.last.id, 'id', 'msg_server'),
        ),
      );

      bloc.add(const SendTextMessageEvent(content: 'New message'));
      await untilCalled(() => mockSendTextMessage(any()));
      await emission;
    });

    test('SendTextMessage failure eventually emits failed temp message', () async {
      when(() => mockAuthService.currentUser).thenReturn(tUser);
      when(() => mockGetMessages(any())).thenAnswer(
        (_) async => Right(
          ConversationMessagesPage(messages: tMessages, hasMore: false, showPremiumPrompt: false),
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
          isA<ChatLoaded>().having((s) => s.messages.last.status, 'status', MessageStatus.failed),
        ),
      );

      bloc.add(const SendTextMessageEvent(content: 'New message'));
      await untilCalled(() => mockSendTextMessage(any()));
      await emission;
    });

    test('MarkAsRead delegates to usecase', () async {
      when(() => mockGetMessages(any())).thenAnswer(
        (_) async => Right(
          ConversationMessagesPage(messages: tMessages, hasMore: false, showPremiumPrompt: false),
        ),
      );
      when(() => mockMarkMessageAsRead(any())).thenAnswer((_) async => const Right(null));

      bloc.add(const LoadConversation(conversationId: 'conv_1'));
      await untilCalled(() => mockGetMessages(any()));

      bloc.add(const MarkAsReadEvent(messageId: 'msg_1'));
      await untilCalled(() => mockMarkMessageAsRead(any()));

      verify(() => mockMarkMessageAsRead(
            const MarkMessageAsReadParams(conversationId: 'conv_1', messageId: 'msg_1'),
          )).called(1);
    });
  });
}
