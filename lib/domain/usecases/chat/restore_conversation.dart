import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';

class RestoreConversation {
  final MessageRepository _repository;

  RestoreConversation(this._repository);

  Future<Either<Failure, void>> call(RestoreConversationParams params) {
    return _repository.restoreConversation(params.conversationId);
  }
}

class RestoreConversationParams extends Equatable {
  final String conversationId;

  const RestoreConversationParams({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}
