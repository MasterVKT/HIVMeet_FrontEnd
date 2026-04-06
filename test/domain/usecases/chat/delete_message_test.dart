import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';
import 'package:hivmeet/domain/usecases/chat/delete_message.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

void main() {
  late DeleteMessage usecase;
  late MockMessageRepository mockRepository;

  setUp(() {
    mockRepository = MockMessageRepository();
    usecase = DeleteMessage(mockRepository);
  });

  const tParams = DeleteMessageParams(
    conversationId: 'conv_1',
    messageId: 'msg_1',
  );

  group('DeleteMessage', () {
    test('should delete message successfully', () async {
      when(() => mockRepository.deleteMessage(
            conversationId: any(named: 'conversationId'),
            messageId: any(named: 'messageId'),
          )).thenAnswer((_) async => const Right(null));

      final result = await usecase(tParams);

      expect(result, const Right(null));
      verify(() => mockRepository.deleteMessage(
            conversationId: 'conv_1',
            messageId: 'msg_1',
          )).called(1);
    });

    test('should return failure when repository fails', () async {
      const tFailure = ServerFailure(message: 'Delete failed');
      when(() => mockRepository.deleteMessage(
            conversationId: any(named: 'conversationId'),
            messageId: any(named: 'messageId'),
          )).thenAnswer((_) async => const Left(tFailure));

      final result = await usecase(tParams);

      expect(result, const Left(tFailure));
    });

    test('params should be equatable', () {
      const paramsA = DeleteMessageParams(
        conversationId: 'conv_1',
        messageId: 'msg_1',
      );
      const paramsB = DeleteMessageParams(
        conversationId: 'conv_1',
        messageId: 'msg_1',
      );

      expect(paramsA, paramsB);
      expect(paramsA.hashCode, paramsB.hashCode);
    });
  });
}
