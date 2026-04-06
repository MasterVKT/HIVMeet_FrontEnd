import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';

@injectable
class GenerateMediaUploadUrl {
  final MessageRepository repository;

  GenerateMediaUploadUrl(this.repository);

  Future<Either<Failure, MediaUploadTarget>> call(
    GenerateMediaUploadUrlParams params,
  ) async {
    return repository.generateMediaUploadUrl(
      fileName: params.fileName,
      contentType: params.contentType,
    );
  }
}

class GenerateMediaUploadUrlParams extends Equatable {
  final String fileName;
  final String contentType;

  const GenerateMediaUploadUrlParams({
    required this.fileName,
    required this.contentType,
  });

  @override
  List<Object?> get props => [fileName, contentType];
}
