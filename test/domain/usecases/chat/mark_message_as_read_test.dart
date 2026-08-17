import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';
import 'package:hivmeet/domain/usecases/chat/mark_message_as_read.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

void main() {
  late MarkMessageAsRead usecase;
  late MockMessageRepository repository;
  const params = MarkMessageAsReadParams(
    conversationId: 'conv_1',
    messageId: 'msg_1',
  );
  const readResult = MarkAsReadResult(
    messagesMarked: 1,
    unreadCountForMe: 2,
  );

  setUp(() {
    repository = MockMessageRepository();
    usecase = MarkMessageAsRead(repository);
  });

  test('forwards the authoritative read result', () async {
    when(() => repository.markAsRead(
          conversationId: 'conv_1',
          messageId: 'msg_1',
        )).thenAnswer((_) async => const Right(readResult));

    final result = await usecase(params);

    expect(result, const Right(readResult));
    verify(() => repository.markAsRead(
          conversationId: 'conv_1',
          messageId: 'msg_1',
        )).called(1);
  });

  test('forwards a failure without changing it', () async {
    const failure = NetworkFailure(message: 'offline');
    when(() => repository.markAsRead(
          conversationId: 'conv_1',
          messageId: 'msg_1',
        )).thenAnswer((_) async => const Left(failure));

    expect(await usecase(params), const Left(failure));
  });

  test('params are equatable', () {
    expect(
        params,
        const MarkMessageAsReadParams(
          conversationId: 'conv_1',
          messageId: 'msg_1',
        ));
  });
}
