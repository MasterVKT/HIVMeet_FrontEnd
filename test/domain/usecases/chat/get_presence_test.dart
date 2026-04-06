import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';
import 'package:hivmeet/domain/usecases/chat/get_presence.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

void main() {
  late GetPresence usecase;
  late MockMessageRepository mockRepository;

  setUp(() {
    mockRepository = MockMessageRepository();
    usecase = GetPresence(mockRepository);
  });

  const tParams = GetPresenceParams(conversationId: 'conv_1');
  const tPresence = ParticipantPresence(
    userId: 'user_2',
    isOnline: true,
    lastActive: null,
    isTyping: false,
  );

  group('GetPresence', () {
    test('should return presence from repository', () async {
      when(() => mockRepository.getPresence(
            conversationId: any(named: 'conversationId'),
          )).thenAnswer((_) async => const Right(tPresence));

      final result = await usecase(tParams);

      expect(result, const Right(tPresence));
      verify(() => mockRepository.getPresence(conversationId: 'conv_1'))
          .called(1);
    });

    test('should return failure when repository fails', () async {
      const tFailure = ServerFailure(message: 'Presence error');
      when(() => mockRepository.getPresence(
            conversationId: any(named: 'conversationId'),
          )).thenAnswer((_) async => const Left(tFailure));

      final result = await usecase(tParams);

      expect(result, const Left(tFailure));
    });

    test('params should be equatable', () {
      const paramsA = GetPresenceParams(conversationId: 'conv_1');
      const paramsB = GetPresenceParams(conversationId: 'conv_1');

      expect(paramsA, paramsB);
      expect(paramsA.hashCode, paramsB.hashCode);
    });
  });
}
