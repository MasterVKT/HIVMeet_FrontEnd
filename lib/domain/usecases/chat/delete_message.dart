import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';

@injectable
class DeleteMessage {
  final MessageRepository repository;

  DeleteMessage(this.repository);

  Future<Either<Failure, void>> call(DeleteMessageParams params) async {
    return repository.deleteMessage(
      conversationId: params.conversationId,
      messageId: params.messageId,
    );
  }
}

class DeleteMessageParams extends Equatable {
  final String conversationId;
  final String messageId;

  const DeleteMessageParams({
    required this.conversationId,
    required this.messageId,
  });

  @override
  List<Object?> get props => [conversationId, messageId];
}