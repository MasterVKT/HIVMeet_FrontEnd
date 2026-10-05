import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';

class EditMessage {
  final MessageRepository _repository;

  EditMessage(this._repository);

  Future<Either<Failure, Message>> call(EditMessageParams params) {
    return _repository.editMessage(
      conversationId: params.conversationId,
      messageId: params.messageId,
      content: params.content,
    );
  }
}

class EditMessageParams extends Equatable {
  final String conversationId;
  final String messageId;
  final String content;

  const EditMessageParams({
    required this.conversationId,
    required this.messageId,
    required this.content,
  });

  @override
  List<Object?> get props => [conversationId, messageId, content];
}
