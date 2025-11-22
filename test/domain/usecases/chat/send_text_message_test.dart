// test/domain/usecases/chat/send_text_message_test.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';
import 'package:hivmeet/domain/usecases/chat/send_text_message.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

void main() {
  late SendTextMessage usecase;
  late MockMessageRepository mockRepository;

  setUp(() {
    mockRepository = MockMessageRepository();
    usecase = SendTextMessage(mockRepository);
  });

  final tMessage = Message(
    id: 'msg_123',
    conversationId: 'conv_1',
    senderId: 'user_1',
    content: 'Hello world!',
    type: MessageType.text,
    createdAt: DateTime(2024, 1, 20, 15, 30),
    isRead: false,
    reactions: const {},
    status: MessageStatus.sent,
  );

  group('SendTextMessage', () {
    test('should send text message successfully', () async {
      // arrange
      const tParams = SendTextMessageParams(
        conversationId: 'conv_1',
        content: 'Hello world!',
      );

      when(() => mockRepository.sendMessage(
            conversationId: any(named: 'conversationId'),
            content: any(named: 'content'),
            type: any(named: 'type'),
            mediaFile: any(named: 'mediaFile'),
          )).thenAnswer((_) async => Right(tMessage));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, Right(tMessage));
      verify(() => mockRepository.sendMessage(
            conversationId: 'conv_1',
            content: 'Hello world!',
            type: MessageType.text,
          )).called(1);
    });

    test('should return ServerFailure when content is empty', () async {
      // arrange
      const tParams = SendTextMessageParams(
        conversationId: 'conv_1',
        content: '',
      );

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, isA<Left>());
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Le message ne peut pas être vide');
        },
        (_) => fail('Should return failure'),
      );

      // Should not call repository when validation fails
      verifyNever(() => mockRepository.sendMessage(
            conversationId: any(named: 'conversationId'),
            content: any(named: 'content'),
            type: any(named: 'type'),
          ));
    });

    test('should return ServerFailure when content is only whitespace',
        () async {
      // arrange
      const tParams = SendTextMessageParams(
        conversationId: 'conv_1',
        content: '   ',
      );

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, isA<Left>());
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Le message ne peut pas être vide');
        },
        (_) => fail('Should return failure'),
      );

      verifyNever(() => mockRepository.sendMessage(
            conversationId: any(named: 'conversationId'),
            content: any(named: 'content'),
            type: any(named: 'type'),
          ));
    });

    test('should trim whitespace and send message', () async {
      // arrange
      const tParams = SendTextMessageParams(
        conversationId: 'conv_1',
        content: '  Hello  ',
      );

      when(() => mockRepository.sendMessage(
            conversationId: any(named: 'conversationId'),
            content: any(named: 'content'),
            type: any(named: 'type'),
            mediaFile: any(named: 'mediaFile'),
          )).thenAnswer((_) async => Right(tMessage));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, Right(tMessage));
      verify(() => mockRepository.sendMessage(
            conversationId: 'conv_1',
            content: '  Hello  ',
            type: MessageType.text,
          )).called(1);
    });

    test('should return ServerFailure when repository fails', () async {
      // arrange
      const tParams = SendTextMessageParams(
        conversationId: 'conv_1',
        content: 'Hello!',
      );
      const tFailure = ServerFailure(message: 'Failed to send message');

      when(() => mockRepository.sendMessage(
            conversationId: any(named: 'conversationId'),
            content: any(named: 'content'),
            type: any(named: 'type'),
            mediaFile: any(named: 'mediaFile'),
          )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
    });

    test('should return NetworkFailure when no internet connection', () async {
      // arrange
      const tParams = SendTextMessageParams(
        conversationId: 'conv_1',
        content: 'Hello!',
      );
      const tFailure = NetworkFailure(message: 'No internet connection');

      when(() => mockRepository.sendMessage(
            conversationId: any(named: 'conversationId'),
            content: any(named: 'content'),
            type: any(named: 'type'),
            mediaFile: any(named: 'mediaFile'),
          )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
    });

    test('should handle long messages correctly', () async {
      // arrange
      final longContent = 'A' * 5000; // 5000 characters
      final tParams = SendTextMessageParams(
        conversationId: 'conv_1',
        content: longContent,
      );

      when(() => mockRepository.sendMessage(
            conversationId: any(named: 'conversationId'),
            content: any(named: 'content'),
            type: any(named: 'type'),
            mediaFile: any(named: 'mediaFile'),
          )).thenAnswer((_) async => Right(tMessage));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, Right(tMessage));
      verify(() => mockRepository.sendMessage(
            conversationId: 'conv_1',
            content: longContent,
            type: MessageType.text,
          )).called(1);
    });
  });
}
