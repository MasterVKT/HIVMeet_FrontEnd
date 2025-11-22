// test/presentation/blocs/chat/chat_bloc_test.dart

import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/services/authentication_service.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/entities/user.dart' as domain;
import 'package:hivmeet/domain/usecases/chat/get_messages.dart';
import 'package:hivmeet/domain/usecases/chat/send_text_message.dart';
import 'package:hivmeet/domain/usecases/chat/send_media_message.dart';
import 'package:hivmeet/domain/usecases/chat/mark_message_as_read.dart';
import 'package:hivmeet/presentation/blocs/chat/chat_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockGetMessages extends Mock implements GetMessages {}

class MockSendTextMessage extends Mock implements SendTextMessage {}

class MockSendMediaMessage extends Mock implements SendMediaMessage {}

class MockMarkMessageAsRead extends Mock implements MarkMessageAsRead {}

class MockAuthenticationService extends Mock implements AuthenticationService {}

class MockFile extends Mock implements File {}

void main() {
  late ChatBloc bloc;
  late MockGetMessages mockGetMessages;
  late MockSendTextMessage mockSendTextMessage;
  late MockSendMediaMessage mockSendMediaMessage;
  late MockMarkMessageAsRead mockMarkMessageAsRead;
  late MockAuthenticationService mockAuthService;

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

    // Register fallback values for any
    registerFallbackValue(
      const GetMessagesParams(conversationId: 'test'),
    );
    registerFallbackValue(
      const SendTextMessageParams(conversationId: 'test', content: 'test'),
    );
    registerFallbackValue(
      SendMediaMessageParams(
        conversationId: 'test',
        mediaFile: File('test'),
        type: MessageType.image,
      ),
    );
    registerFallbackValue(
      const MarkMessageAsReadParams(
        conversationId: 'test',
        messageId: 'test',
      ),
    );
  });

  tearDown(() {
    bloc.close();
  });

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
      senderId: 'user_1',
      content: 'Hello',
      type: MessageType.text,
      createdAt: DateTime(2024, 1, 20, 10, 0),
      isRead: true,
      reactions: const {},
      status: MessageStatus.sent,
    ),
    Message(
      id: 'msg_2',
      conversationId: 'conv_1',
      senderId: 'user_2',
      content: 'Hi!',
      type: MessageType.text,
      createdAt: DateTime(2024, 1, 20, 10, 1),
      isRead: false,
      reactions: const {},
      status: MessageStatus.sent,
    ),
  ];

  group('ChatBloc', () {
    test('initial state is ChatInitial', () {
      expect(bloc.state, equals(ChatInitial()));
    });

    group('LoadConversation', () {
      test('should emit [ChatLoading, ChatLoaded] when successful', () async {
        // arrange
        when(() => mockGetMessages(any()))
            .thenAnswer((_) async => Right(tMessages));

        // assert later
        final expected = [
          ChatLoading(),
          ChatLoaded(
            messages: tMessages,
            hasMore: false, // Only 2 messages, less than 50
            isTyping: false,
            isLoadingMore: false,
          ),
        ];
        expectLater(bloc.stream, emitsInOrder(expected));

        // act
        bloc.add(const LoadConversation(conversationId: 'conv_1'));
      });

      test('should set hasMore=true when 50 messages returned', () async {
        // arrange
        final fiftyMessages = List.generate(
          50,
          (i) => Message(
            id: 'msg_$i',
            conversationId: 'conv_1',
            senderId: 'user_1',
            content: 'Message $i',
            type: MessageType.text,
            createdAt: DateTime(2024, 1, 20, 10, i),
            isRead: false,
            reactions: const {},
            status: MessageStatus.sent,
          ),
        );

        when(() => mockGetMessages(any()))
            .thenAnswer((_) async => Right(fiftyMessages));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            ChatLoading(),
            ChatLoaded(
              messages: fiftyMessages,
              hasMore: true, // 50 messages = probably more
              isTyping: false,
              isLoadingMore: false,
            ),
          ]),
        );

        // act
        bloc.add(const LoadConversation(conversationId: 'conv_1'));
      });

      test('should emit [ChatLoading, ChatError] when fails', () async {
        // arrange
        const tFailure = ServerFailure(message: 'Failed to load messages');
        when(() => mockGetMessages(any()))
            .thenAnswer((_) async => const Left(tFailure));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            ChatLoading(),
            const ChatError(message: 'Failed to load messages'),
          ]),
        );

        // act
        bloc.add(const LoadConversation(conversationId: 'conv_1'));
      });

      test('should call GetMessages with correct params', () async {
        // arrange
        when(() => mockGetMessages(any()))
            .thenAnswer((_) async => Right(tMessages));

        // act
        bloc.add(const LoadConversation(conversationId: 'conv_1'));
        await untilCalled(() => mockGetMessages(any()));

        // assert
        verify(() => mockGetMessages(
              GetMessagesParams.initial('conv_1'),
            )).called(1);
      });
    });

    group('LoadMoreMessages', () {
      test('should load more messages with pagination cursor', () async {
        // arrange - first load
        when(() => mockGetMessages(any()))
            .thenAnswer((_) async => Right(tMessages));
        bloc.add(const LoadConversation(conversationId: 'conv_1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // arrange - load more
        final moreMessages = [
          Message(
            id: 'msg_0',
            conversationId: 'conv_1',
            senderId: 'user_1',
            content: 'Older message',
            type: MessageType.text,
            createdAt: DateTime(2024, 1, 20, 9, 0),
            isRead: true,
            reactions: const {},
            status: MessageStatus.sent,
          ),
        ];
        when(() => mockGetMessages(any()))
            .thenAnswer((_) async => Right(moreMessages));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ChatLoaded>()
                .having((s) => s.isLoadingMore, 'isLoadingMore', true),
            isA<ChatLoaded>()
                .having((s) => s.messages.length, 'messages length', 3)
                .having((s) => s.isLoadingMore, 'isLoadingMore', false)
                .having((s) => s.messages.first.id, 'first message', 'msg_0'),
          ]),
        );

        // act
        bloc.add(LoadMoreMessages());
        await Future.delayed(const Duration(milliseconds: 100));

        // assert
        verify(() => mockGetMessages(
              const GetMessagesParams(
                conversationId: 'conv_1',
                beforeMessageId: 'msg_1', // Oldest message ID
              ),
            )).called(1);
      });

      test('should not load more if already loading', () async {
        // arrange
        when(() => mockGetMessages(any()))
            .thenAnswer((_) async => Right(tMessages));
        bloc.add(const LoadConversation(conversationId: 'conv_1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Change state to loading more
        final currentState = bloc.state as ChatLoaded;
        bloc.emit(currentState.copyWith(isLoadingMore: true));

        // act
        bloc.add(LoadMoreMessages());
        await Future.delayed(const Duration(milliseconds: 100));

        // assert - should not call getMessages again
        verifyNever(() => mockGetMessages(any(
              that: isA<GetMessagesParams>()
                  .having((p) => p.beforeMessageId, 'beforeMessageId', isNotNull),
            )));
      });

      test('should not load more if hasMore is false', () async {
        // arrange
        when(() => mockGetMessages(any()))
            .thenAnswer((_) async => Right(tMessages));
        bloc.add(const LoadConversation(conversationId: 'conv_1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // State should have hasMore=false (only 2 messages)
        expect((bloc.state as ChatLoaded).hasMore, false);

        // Reset mock to track new calls
        reset(mockGetMessages);

        // act
        bloc.add(LoadMoreMessages());
        await Future.delayed(const Duration(milliseconds: 100));

        // assert - should not call getMessages
        verifyNever(() => mockGetMessages(any()));
      });
    });

    group('SendTextMessage - Optimistic Updates', () {
      test('should show optimistic message immediately', () async {
        // arrange
        when(() => mockAuthService.currentUser).thenReturn(tUser);
        when(() => mockGetMessages(any()))
            .thenAnswer((_) async => Right(tMessages));
        bloc.add(const LoadConversation(conversationId: 'conv_1'));
        await Future.delayed(const Duration(milliseconds: 100));

        final sentMessage = Message(
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
            .thenAnswer((_) async => Right(sentMessage));

        // assert later - should emit optimistic message first
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ChatLoaded>()
                .having((s) => s.messages.length, 'messages length', 3)
                .having(
                    (s) => s.messages.last.status, 'status', MessageStatus.sending)
                .having((s) => s.messages.last.content, 'content', 'New message'),
            isA<ChatLoaded>()
                .having((s) => s.messages.length, 'messages length', 3)
                .having((s) => s.messages.last.status, 'status', MessageStatus.sent)
                .having((s) => s.messages.last.id, 'id', 'msg_server'),
          ]),
        );

        // act
        bloc.add(const SendTextMessageEvent(content: 'New message'));
      });

      test('should use real user ID from AuthService', () async {
        // arrange
        when(() => mockAuthService.currentUser).thenReturn(tUser);
        when(() => mockGetMessages(any()))
            .thenAnswer((_) async => Right(tMessages));
        bloc.add(const LoadConversation(conversationId: 'conv_1'));
        await Future.delayed(const Duration(milliseconds: 100));

        final sentMessage = Message(
          id: 'msg_server',
          conversationId: 'conv_1',
          senderId: 'user_1',
          content: 'Test',
          type: MessageType.text,
          createdAt: DateTime.now(),
          isRead: false,
          reactions: const {},
          status: MessageStatus.sent,
        );

        when(() => mockSendTextMessage(any()))
            .thenAnswer((_) async => Right(sentMessage));

        // act
        bloc.add(const SendTextMessageEvent(content: 'Test'));
        await Future.delayed(const Duration(milliseconds: 100));

        // assert - optimistic message should have user_1 as senderId
        final state = bloc.state as ChatLoaded;
        expect(state.messages.last.senderId, 'user_1');
      });

      test('should use "unknown" when user not authenticated', () async {
        // arrange
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(() => mockGetMessages(any()))
            .thenAnswer((_) async => Right(tMessages));
        bloc.add(const LoadConversation(conversationId: 'conv_1'));
        await Future.delayed(const Duration(milliseconds: 100));

        final sentMessage = Message(
          id: 'msg_server',
          conversationId: 'conv_1',
          senderId: 'unknown',
          content: 'Test',
          type: MessageType.text,
          createdAt: DateTime.now(),
          isRead: false,
          reactions: const {},
          status: MessageStatus.sent,
        );

        when(() => mockSendTextMessage(any()))
            .thenAnswer((_) async => Right(sentMessage));

        // act
        bloc.add(const SendTextMessageEvent(content: 'Test'));
        await Future.delayed(const Duration(milliseconds: 100));

        // assert
        final state = bloc.state as ChatLoaded;
        expect(state.messages.any((m) => m.senderId == 'unknown'), true);
      });
    });

    group('SendTextMessage - Rollback on Failure', () {
      test('should mark message as failed when send fails', () async {
        // arrange
        when(() => mockAuthService.currentUser).thenReturn(tUser);
        when(() => mockGetMessages(any()))
            .thenAnswer((_) async => Right(tMessages));
        bloc.add(const LoadConversation(conversationId: 'conv_1'));
        await Future.delayed(const Duration(milliseconds: 100));

        const tFailure = NetworkFailure(message: 'No internet');
        when(() => mockSendTextMessage(any()))
            .thenAnswer((_) async => const Left(tFailure));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ChatLoaded>()
                .having((s) => s.messages.last.status, 'status', MessageStatus.sending),
            isA<ChatLoaded>()
                .having((s) => s.messages.last.status, 'status', MessageStatus.failed)
                .having((s) => s.messages.last.content, 'content', 'Failed message'),
          ]),
        );

        // act
        bloc.add(const SendTextMessageEvent(content: 'Failed message'));
      });

      test('should keep failed message in list for retry', () async {
        // arrange
        when(() => mockAuthService.currentUser).thenReturn(tUser);
        when(() => mockGetMessages(any()))
            .thenAnswer((_) async => Right(tMessages));
        bloc.add(const LoadConversation(conversationId: 'conv_1'));
        await Future.delayed(const Duration(milliseconds: 100));

        const tFailure = ServerFailure(message: 'Server error');
        when(() => mockSendTextMessage(any()))
            .thenAnswer((_) async => const Left(tFailure));

        // act
        bloc.add(const SendTextMessageEvent(content: 'Will fail'));
        await Future.delayed(const Duration(milliseconds: 150));

        // assert - message should still be in the list with failed status
        final state = bloc.state as ChatLoaded;
        expect(state.messages.length, 3);
        expect(state.messages.last.status, MessageStatus.failed);
        expect(state.messages.last.content, 'Will fail');
      });
    });

    group('SendMediaMessage - Optimistic Updates', () {
      test('should show optimistic media message immediately', () async {
        // arrange
        when(() => mockAuthService.currentUser).thenReturn(tUser);
        when(() => mockGetMessages(any()))
            .thenAnswer((_) async => Right(tMessages));
        bloc.add(const LoadConversation(conversationId: 'conv_1'));
        await Future.delayed(const Duration(milliseconds: 100));

        final mockFile = MockFile();
        final sentMessage = Message(
          id: 'msg_server',
          conversationId: 'conv_1',
          senderId: 'user_1',
          content: '',
          mediaUrl: 'https://example.com/image.jpg',
          type: MessageType.image,
          createdAt: DateTime.now(),
          isRead: false,
          reactions: const {},
          status: MessageStatus.sent,
        );

        when(() => mockSendMediaMessage(any()))
            .thenAnswer((_) async => Right(sentMessage));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ChatLoaded>()
                .having((s) => s.messages.length, 'messages length', 3)
                .having(
                    (s) => s.messages.last.status, 'status', MessageStatus.sending)
                .having((s) => s.messages.last.type, 'type', MessageType.image),
            isA<ChatLoaded>()
                .having((s) => s.messages.last.status, 'status', MessageStatus.sent)
                .having((s) => s.messages.last.mediaUrl, 'mediaUrl', isNotNull),
          ]),
        );

        // act
        bloc.add(SendMediaMessageEvent(
          mediaFile: mockFile,
          type: MessageType.image,
        ));
      });

      test('should mark media message as failed on error', () async {
        // arrange
        when(() => mockAuthService.currentUser).thenReturn(tUser);
        when(() => mockGetMessages(any()))
            .thenAnswer((_) async => Right(tMessages));
        bloc.add(const LoadConversation(conversationId: 'conv_1'));
        await Future.delayed(const Duration(milliseconds: 100));

        final mockFile = MockFile();
        const tFailure = ServerFailure(message: 'Upload failed');
        when(() => mockSendMediaMessage(any()))
            .thenAnswer((_) async => const Left(tFailure));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ChatLoaded>()
                .having((s) => s.messages.last.status, 'status', MessageStatus.sending),
            isA<ChatLoaded>()
                .having((s) => s.messages.last.status, 'status', MessageStatus.failed),
          ]),
        );

        // act
        bloc.add(SendMediaMessageEvent(
          mediaFile: mockFile,
          type: MessageType.image,
        ));
      });
    });

    group('MarkAsRead', () {
      test('should call markMessageAsRead use case', () async {
        // arrange
        when(() => mockGetMessages(any()))
            .thenAnswer((_) async => Right(tMessages));
        bloc.add(const LoadConversation(conversationId: 'conv_1'));
        await Future.delayed(const Duration(milliseconds: 100));

        when(() => mockMarkMessageAsRead(any()))
            .thenAnswer((_) async => const Right(null));

        // act
        bloc.add(const MarkAsReadEvent(messageId: 'msg_2'));
        await Future.delayed(const Duration(milliseconds: 100));

        // assert
        verify(() => mockMarkMessageAsRead(
              const MarkMessageAsReadParams(
                conversationId: 'conv_1',
                messageId: 'msg_2',
              ),
            )).called(1);
      });

      test('should not emit new state after marking as read', () async {
        // arrange
        when(() => mockGetMessages(any()))
            .thenAnswer((_) async => Right(tMessages));
        bloc.add(const LoadConversation(conversationId: 'conv_1'));
        await Future.delayed(const Duration(milliseconds: 100));

        when(() => mockMarkMessageAsRead(any()))
            .thenAnswer((_) async => const Right(null));

        final stateBefore = bloc.state;

        // act
        bloc.add(const MarkAsReadEvent(messageId: 'msg_2'));
        await Future.delayed(const Duration(milliseconds: 100));

        // assert - state should not change
        expect(bloc.state, equals(stateBefore));
      });
    });

    group('SetTypingStatus', () {
      test('should update typing status', () async {
        // arrange
        when(() => mockGetMessages(any()))
            .thenAnswer((_) async => Right(tMessages));
        bloc.add(const LoadConversation(conversationId: 'conv_1'));
        await Future.delayed(const Duration(milliseconds: 100));

        // assert later
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ChatLoaded>().having((s) => s.isTyping, 'isTyping', true),
            isA<ChatLoaded>().having((s) => s.isTyping, 'isTyping', false),
          ]),
        );

        // act
        bloc.add(const SetTypingStatus(isTyping: true));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const SetTypingStatus(isTyping: false));
      });

      test('should preserve other state when updating typing', () async {
        // arrange
        when(() => mockGetMessages(any()))
            .thenAnswer((_) async => Right(tMessages));
        bloc.add(const LoadConversation(conversationId: 'conv_1'));
        await Future.delayed(const Duration(milliseconds: 100));

        final stateBefore = bloc.state as ChatLoaded;

        // act
        bloc.add(const SetTypingStatus(isTyping: true));
        await Future.delayed(const Duration(milliseconds: 100));

        // assert
        final stateAfter = bloc.state as ChatLoaded;
        expect(stateAfter.messages, equals(stateBefore.messages));
        expect(stateAfter.hasMore, equals(stateBefore.hasMore));
        expect(stateAfter.isLoadingMore, equals(stateBefore.isLoadingMore));
        expect(stateAfter.isTyping, true);
      });
    });
  });
}
