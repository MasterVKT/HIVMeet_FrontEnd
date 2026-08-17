import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';

@injectable
class DeleteConversation implements UseCase<void, DeleteConversationParams> {
  final MessageRepository repository;

  DeleteConversation(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteConversationParams params) {
    return repository.deleteConversation(params.conversationId);
  }
}

class DeleteConversationParams extends Equatable {
  final String conversationId;

  const DeleteConversationParams({required this.conversationId});

  @override
  List<Object> get props => [conversationId];
}
