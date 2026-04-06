import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';

@injectable
class GetPresence {
  final MessageRepository repository;

  GetPresence(this.repository);

  Future<Either<Failure, ParticipantPresence>> call(GetPresenceParams params) async {
    return repository.getPresence(conversationId: params.conversationId);
  }
}

class GetPresenceParams extends Equatable {
  final String conversationId;

  const GetPresenceParams({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}