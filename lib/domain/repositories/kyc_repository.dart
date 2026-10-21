import 'package:dartz/dartz.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/kyc.dart';

abstract class KycRepository {
  Future<Either<Failure, KycSnapshot>> getStatus();

  Future<Either<Failure, KycStartSession>> startAttempt({
    required String consentVersion,
    required String idempotencyKey,
  });

  Future<Either<Failure, KycUploadIntent>> createUploadIntent({
    required String attemptId,
    required KycCapturedDocument document,
    required String idempotencyKey,
  });

  Future<Either<Failure, void>> uploadDocument({
    required KycCapturedDocument document,
    required KycUploadIntent intent,
    required void Function(int sent, int total) onProgress,
  });

  Future<Either<Failure, void>> completeUpload({required String uploadId});

  Future<Either<Failure, KycSnapshot>> submitAttempt({
    required String attemptId,
    required Map<KycDocumentType, String> uploadIds,
    required String selfieChallengeCode,
    required String idempotencyKey,
  });
}
