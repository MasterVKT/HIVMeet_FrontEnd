// test/domain/usecases/chat/send_media_message_test.dart

import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';
import 'package:hivmeet/domain/usecases/chat/send_media_message.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

class MockFile extends Mock implements File {}

void main() {
  late SendMediaMessage usecase;
  late MockMessageRepository mockRepository;
  late MockFile mockFile;

  setUp(() {
    mockRepository = MockMessageRepository();
    mockFile = MockFile();
    usecase = SendMediaMessage(mockRepository);
  });

  final tMessage = Message(
    id: 'msg_123',
    conversationId: 'conv_1',
    senderId: 'user_1',
    content: '',
    mediaUrl: 'https://example.com/media/image.jpg',
    type: MessageType.image,
    createdAt: DateTime(2024, 1, 20, 15, 30),
    isRead: false,
    reactions: const {},
    status: MessageStatus.sent,
  );

  group('SendMediaMessage', () {
    test('should send image message successfully', () async {
      // arrange
      final tParams = SendMediaMessageParams.image(
        conversationId: 'conv_1',
        mediaFile: mockFile,
      );

      when(() => mockFile.exists()).thenAnswer((_) async => true);
      when(() => mockFile.length())
          .thenAnswer((_) async => 5 * 1024 * 1024); // 5 MB

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
      verify(() => mockFile.exists()).called(1);
      verify(() => mockFile.length()).called(1);
      verify(() => mockRepository.sendMessage(
            conversationId: 'conv_1',
            content: '',
            type: MessageType.image,
            mediaFile: mockFile,
          )).called(1);
    });

    test('should send video message successfully', () async {
      // arrange
      final tParams = SendMediaMessageParams.video(
        conversationId: 'conv_1',
        mediaFile: mockFile,
      );

      when(() => mockFile.exists()).thenAnswer((_) async => true);
      when(() => mockFile.length())
          .thenAnswer((_) async => 10 * 1024 * 1024); // 10 MB

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
            content: '',
            type: MessageType.video,
            mediaFile: mockFile,
          )).called(1);
    });

    test('should send voice message successfully', () async {
      // arrange
      final tParams = SendMediaMessageParams.voice(
        conversationId: 'conv_1',
        mediaFile: mockFile,
      );

      when(() => mockFile.exists()).thenAnswer((_) async => true);
      when(() => mockFile.length())
          .thenAnswer((_) async => 1 * 1024 * 1024); // 1 MB

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
            content: '',
            type: MessageType.voice,
            mediaFile: mockFile,
          )).called(1);
    });

    test('should return ServerFailure when file does not exist', () async {
      // arrange
      final tParams = SendMediaMessageParams.image(
        conversationId: 'conv_1',
        mediaFile: mockFile,
      );

      when(() => mockFile.exists()).thenAnswer((_) async => false);

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, isA<Left>());
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Le fichier média n\'existe pas');
        },
        (_) => fail('Should return failure'),
      );

      verify(() => mockFile.exists()).called(1);
      verifyNever(() => mockFile.length());
      verifyNever(() => mockRepository.sendMessage(
            conversationId: any(named: 'conversationId'),
            content: any(named: 'content'),
            type: any(named: 'type'),
            mediaFile: any(named: 'mediaFile'),
          ));
    });

    test('should return ServerFailure when file is too large (>50MB)',
        () async {
      // arrange
      final tParams = SendMediaMessageParams.image(
        conversationId: 'conv_1',
        mediaFile: mockFile,
      );

      when(() => mockFile.exists()).thenAnswer((_) async => true);
      when(() => mockFile.length())
          .thenAnswer((_) async => 51 * 1024 * 1024); // 51 MB

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, isA<Left>());
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('trop volumineux'));
          expect(failure.message, contains('max 50 MB'));
        },
        (_) => fail('Should return failure'),
      );

      verify(() => mockFile.exists()).called(1);
      verify(() => mockFile.length()).called(1);
      verifyNever(() => mockRepository.sendMessage(
            conversationId: any(named: 'conversationId'),
            content: any(named: 'content'),
            type: any(named: 'type'),
            mediaFile: any(named: 'mediaFile'),
          ));
    });

    test('should accept file exactly at 50MB limit', () async {
      // arrange
      final tParams = SendMediaMessageParams.image(
        conversationId: 'conv_1',
        mediaFile: mockFile,
      );

      when(() => mockFile.exists()).thenAnswer((_) async => true);
      when(() => mockFile.length())
          .thenAnswer((_) async => 50 * 1024 * 1024); // Exactly 50 MB

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
            content: '',
            type: MessageType.image,
            mediaFile: mockFile,
          )).called(1);
    });

    test('should return ServerFailure when repository fails', () async {
      // arrange
      final tParams = SendMediaMessageParams.image(
        conversationId: 'conv_1',
        mediaFile: mockFile,
      );
      const tFailure = ServerFailure(message: 'Failed to upload media');

      when(() => mockFile.exists()).thenAnswer((_) async => true);
      when(() => mockFile.length())
          .thenAnswer((_) async => 5 * 1024 * 1024); // 5 MB

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
      final tParams = SendMediaMessageParams.image(
        conversationId: 'conv_1',
        mediaFile: mockFile,
      );
      const tFailure = NetworkFailure(message: 'No internet connection');

      when(() => mockFile.exists()).thenAnswer((_) async => true);
      when(() => mockFile.length())
          .thenAnswer((_) async => 5 * 1024 * 1024); // 5 MB

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

    test('image factory should create params with correct type', () {
      // act
      final params = SendMediaMessageParams.image(
        conversationId: 'conv_1',
        mediaFile: mockFile,
      );

      // assert
      expect(params.conversationId, 'conv_1');
      expect(params.mediaFile, mockFile);
      expect(params.type, MessageType.image);
    });

    test('video factory should create params with correct type', () {
      // act
      final params = SendMediaMessageParams.video(
        conversationId: 'conv_1',
        mediaFile: mockFile,
      );

      // assert
      expect(params.conversationId, 'conv_1');
      expect(params.mediaFile, mockFile);
      expect(params.type, MessageType.video);
    });

    test('voice factory should create params with correct type', () {
      // act
      final params = SendMediaMessageParams.voice(
        conversationId: 'conv_1',
        mediaFile: mockFile,
      );

      // assert
      expect(params.conversationId, 'conv_1');
      expect(params.mediaFile, mockFile);
      expect(params.type, MessageType.voice);
    });
  });
}
