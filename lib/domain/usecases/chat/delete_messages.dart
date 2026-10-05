import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';

class DeleteMessages {
  final MessageRepository _repository;

  DeleteMessages(this._repository);

  Future<Either<Failure, void>> call(DeleteMessagesParams params) {
    return _repository.deleteMessages(
      conversationId: params.conversationId,
      messageIds: params.messageIds,
      scope: params.scope,
    );
  }
}

class DeleteMessagesParams extends Equatable {
  final String conversationId;
  final List<String> messageIds;
  final MessageDeletionScope scope;

  const DeleteMessagesParams({
    required this.conversationId,
    required this.messageIds,
    required this.scope,
  });

  @override
  List<Object?> get props => [conversationId, messageIds, scope];
}
