import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';

@injectable
class SetTypingStatusUseCase {
  final MessageRepository repository;

  SetTypingStatusUseCase(this.repository);

  Future<Either<Failure, void>> call(SetTypingStatusParams params) async {
    return repository.setTypingStatus(
      conversationId: params.conversationId,
      isTyping: params.isTyping,
    );
  }
}

class SetTypingStatusParams extends Equatable {
  final String conversationId;
  final bool isTyping;

  const SetTypingStatusParams({
    required this.conversationId,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [conversationId, isTyping];
}