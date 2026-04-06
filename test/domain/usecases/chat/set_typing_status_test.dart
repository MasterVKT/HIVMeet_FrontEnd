import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';
import 'package:hivmeet/domain/usecases/chat/set_typing_status.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

void main() {
  late SetTypingStatusUseCase usecase;
  late MockMessageRepository mockRepository;

  setUp(() {
    mockRepository = MockMessageRepository();
    usecase = SetTypingStatusUseCase(mockRepository);
  });

  group('SetTypingStatusUseCase', () {
    test('should set typing status to true', () async {
      const params = SetTypingStatusParams(
        conversationId: 'conv_1',
        isTyping: true,
      );

      when(() => mockRepository.setTypingStatus(
            conversationId: any(named: 'conversationId'),
            isTyping: any(named: 'isTyping'),
          )).thenAnswer((_) async => const Right(null));

      final result = await usecase(params);

      expect(result, const Right(null));
      verify(() => mockRepository.setTypingStatus(
            conversationId: 'conv_1',
            isTyping: true,
          )).called(1);
    });

    test('should set typing status to false', () async {
      const params = SetTypingStatusParams(
        conversationId: 'conv_1',
        isTyping: false,
      );

      when(() => mockRepository.setTypingStatus(
            conversationId: any(named: 'conversationId'),
            isTyping: any(named: 'isTyping'),
          )).thenAnswer((_) async => const Right(null));

      final result = await usecase(params);

      expect(result, const Right(null));
      verify(() => mockRepository.setTypingStatus(
            conversationId: 'conv_1',
            isTyping: false,
          )).called(1);
    });

    test('should return failure when repository fails', () async {
      const params = SetTypingStatusParams(
        conversationId: 'conv_1',
        isTyping: true,
      );
      const tFailure = NetworkFailure(message: 'No internet');

      when(() => mockRepository.setTypingStatus(
            conversationId: any(named: 'conversationId'),
            isTyping: any(named: 'isTyping'),
          )).thenAnswer((_) async => const Left(tFailure));

      final result = await usecase(params);

      expect(result, const Left(tFailure));
    });

    test('params should be equatable', () {
      const paramsA = SetTypingStatusParams(
        conversationId: 'conv_1',
        isTyping: true,
      );
      const paramsB = SetTypingStatusParams(
        conversationId: 'conv_1',
        isTyping: true,
      );

      expect(paramsA, paramsB);
      expect(paramsA.hashCode, paramsB.hashCode);
    });
  });
}
