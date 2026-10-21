import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/data/datasources/remote/kyc_api.dart';
import 'package:hivmeet/domain/entities/kyc.dart';
import 'package:hivmeet/domain/repositories/kyc_repository.dart';

class KycRepositoryImpl implements KycRepository {
  final KycApi _api;
  final Random _random;

  KycRepositoryImpl(this._api, {Random? random})
      : _random = random ?? Random.secure();

  @override
  Future<Either<Failure, KycSnapshot>> getStatus() async {
    try {
      final response = await _api.getStatus();
      return Right(_snapshot(response.data ?? const {}));
    } on DioException catch (error) {
      return Left(_failure(error));
    } catch (_) {
      return const Left(ServerFailure(message: 'kyc.error.unavailable'));
    }
  }

  @override
  Future<Either<Failure, KycStartSession>> startAttempt({
    required String consentVersion,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _api.startAttempt({
        'consent_version': consentVersion,
        'confirmations': const {
          'official_identity_document': true,
          'medical_document_under_90_days': true,
          'single_use_selfie_challenge': true,
          'human_review_acknowledged': true,
        },
        'idempotency_key': idempotencyKey,
      });
      final data = response.data ?? const <String, dynamic>{};
      final challenge = data['selfie_challenge'];
      if (challenge is! Map ||
          data['attempt_id'] is! String ||
          challenge['code'] is! String ||
          challenge['expires_at'] is! String) {
        return const Left(ServerFailure(message: 'kyc.error.invalid_response'));
      }
      return Right(KycStartSession(
        attemptId: data['attempt_id'] as String,
        status: KycStatus.fromWire(data['status'] as String?),
        selfieChallengeCode: challenge['code'] as String,
        selfieChallengeExpiresAt:
            DateTime.parse(challenge['expires_at'] as String),
      ));
    } on DioException catch (error) {
      return Left(_failure(error));
    } catch (_) {
      return const Left(ServerFailure(message: 'kyc.error.invalid_response'));
    }
  }

  @override
  Future<Either<Failure, KycUploadIntent>> createUploadIntent({
    required String attemptId,
    required KycCapturedDocument document,
    required String idempotencyKey,
  }) async {
    try {
      final file = File(document.localPath);
      if (!await file.exists()) {
        return const Left(LocalFailure(message: 'kyc.error.file_unavailable'));
      }
      final digest = await sha256.bind(file.openRead()).first;
      final response = await _api.createUploadIntent({
        'attempt_id': attemptId,
        'document_type': document.type.wire,
        'mime_type': document.mimeType,
        'size_bytes': document.sizeBytes,
        'sha256': digest.toString(),
        'idempotency_key': idempotencyKey,
      });
      final data = response.data ?? const <String, dynamic>{};
      final transport = switch (data['upload_transport']) {
        'backend_multipart' => KycUploadTransport.backendMultipart,
        'direct_put' || null => KycUploadTransport.directPut,
        _ => null,
      };
      final rawUrl = data['upload_url'];
      final rawHeaders = data['required_headers'];
      final rawExpiry = data['expires_at'];
      final uploadUri = rawUrl is String ? Uri.tryParse(rawUrl) : null;
      final expiresAt =
          rawExpiry is String ? DateTime.tryParse(rawExpiry) : null;
      if (data['upload_id'] is! String ||
          transport == null ||
          expiresAt == null) {
        return const Left(ServerFailure(message: 'kyc.error.invalid_response'));
      }
      if (transport == KycUploadTransport.directPut &&
          (uploadUri == null ||
              uploadUri.scheme != 'https' ||
              uploadUri.host.isEmpty ||
              rawHeaders is! Map)) {
        return const Left(ServerFailure(message: 'kyc.error.invalid_response'));
      }
      return Right(KycUploadIntent(
        uploadId: data['upload_id'] as String,
        uploadUri: uploadUri,
        requiredHeaders: (rawHeaders is Map ? rawHeaders : const {}).map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ),
        expiresAt: expiresAt,
        transport: transport,
      ));
    } on DioException catch (error) {
      return Left(_failure(error));
    } catch (_) {
      return const Left(ServerFailure(message: 'kyc.error.invalid_response'));
    }
  }

  @override
  Future<Either<Failure, void>> uploadDocument({
    required KycCapturedDocument document,
    required KycUploadIntent intent,
    required void Function(int sent, int total) onProgress,
  }) async {
    if (intent.expiresAt.isBefore(DateTime.now())) {
      return const Left(ValidationFailure(message: 'kyc.error.intent_expired'));
    }
    final file = File(document.localPath);
    if (!await file.exists()) {
      return const Left(LocalFailure(message: 'kyc.error.file_unavailable'));
    }
    if (intent.transport == KycUploadTransport.backendMultipart) {
      try {
        await _api.uploadMultipartFile(
          uploadId: intent.uploadId,
          localPath: document.localPath,
          onSendProgress: onProgress,
        );
        return const Right(null);
      } on DioException catch (error) {
        return Left(_failure(error));
      } catch (_) {
        return const Left(NetworkFailure(message: 'kyc.error.upload_failed'));
      }
    }
    final uploadUri = intent.uploadUri;
    if (uploadUri == null ||
        uploadUri.scheme != 'https' ||
        uploadUri.host.isEmpty) {
      return const Left(
          ValidationFailure(message: 'kyc.error.unsafe_upload_url'));
    }
    final normalizedHeaders = intent.requiredHeaders.map(
      (key, value) => MapEntry(key.toLowerCase(), value),
    );
    if (!normalizedHeaders.containsKey('content-type') ||
        !normalizedHeaders.containsKey('content-length') ||
        normalizedHeaders.containsKey('authorization')) {
      return const Left(
        ValidationFailure(message: 'kyc.error.invalid_response'),
      );
    }
    try {
      final direct = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 30),
        followRedirects: false,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ));
      await direct.putUri<void>(
        uploadUri,
        data: file.openRead(),
        options: Options(
          headers: intent.requiredHeaders,
          contentType: document.mimeType,
          responseType: ResponseType.plain,
        ),
        onSendProgress: onProgress,
      );
      return const Right(null);
    } on DioException catch (error) {
      return Left(_failure(error));
    } catch (_) {
      return const Left(NetworkFailure(message: 'kyc.error.upload_failed'));
    }
  }

  @override
  Future<Either<Failure, void>> completeUpload(
      {required String uploadId}) async {
    try {
      await _api.completeUpload(uploadId);
      return const Right(null);
    } on DioException catch (error) {
      return Left(_failure(error));
    } catch (_) {
      return const Left(ServerFailure(message: 'kyc.error.unavailable'));
    }
  }

  @override
  Future<Either<Failure, KycSnapshot>> submitAttempt({
    required String attemptId,
    required Map<KycDocumentType, String> uploadIds,
    required String selfieChallengeCode,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _api.submitAttempt({
        'attempt_id': attemptId,
        'identity_upload_id': uploadIds[KycDocumentType.identityDocument],
        'medical_upload_id': uploadIds[KycDocumentType.medicalDocument],
        'selfie_upload_id': uploadIds[KycDocumentType.selfieWithCode],
        'selfie_challenge_code': selfieChallengeCode,
        'idempotency_key': idempotencyKey,
      });
      final data = response.data ?? const <String, dynamic>{};
      if (data['attempt_id'] is! String || data['status'] is! String) {
        return const Left(ServerFailure(message: 'kyc.error.invalid_response'));
      }
      return Right(KycSnapshot(
        attemptId: data['attempt_id'] as String,
        status: KycStatus.fromWire(data['status'] as String?),
      ));
    } on DioException catch (error) {
      return Left(_failure(error));
    } catch (_) {
      return const Left(ServerFailure(message: 'kyc.error.unavailable'));
    }
  }

  String newIdempotencyKey() {
    final bytes = List<int>.generate(24, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  KycSnapshot _snapshot(Map<String, dynamic> json) {
    final documents = (json['documents'] as List? ?? const [])
        .whereType<Map>()
        .map(_documentStatus)
        .whereType<KycDocumentStatus>()
        .toList(growable: false);
    return KycSnapshot(
      attemptId: json['attempt_id'] as String?,
      status: KycStatus.fromWire(json['status'] as String?),
      documents: documents,
      expiresAt: _date(json['expires_at']),
      submittedAt: _date(json['submitted_at']),
      rejectionReasonCode: json['rejection_reason_code'] as String?,
    );
  }

  DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;

  KycDocumentStatus? _documentStatus(Map<dynamic, dynamic> value) {
    final type = switch (value['type']) {
      'identity_document' => KycDocumentType.identityDocument,
      'medical_document' => KycDocumentType.medicalDocument,
      'selfie_with_code' => KycDocumentType.selfieWithCode,
      _ => null,
    };
    if (type == null) return null;
    return KycDocumentStatus(
      type: type,
      state: KycDocumentState.fromWire(value['state'] as String?),
    );
  }

  Failure _failure(DioException error) {
    final body = error.response?.data;
    final code = body is Map ? body['error']?.toString() : null;
    final status = error.response?.statusCode;
    if (code == 'kyc_required') {
      return const PermissionFailure(
          message: 'kyc.error.required', code: 'kyc_required');
    }
    if (status == 410 ||
        code == 'intent_expired' ||
        code == 'challenge_expired') {
      return FailureExpired(code: code);
    }
    if (status == 413 || code == 'payload_too_large') {
      return const ValidationFailure(
          message: 'kyc.error.file_too_large', code: 'payload_too_large');
    }
    if (status == 429 || code == 'rate_limited') {
      return const ServerFailure(
          message: 'kyc.error.rate_limited', code: 'rate_limited');
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const NetworkFailure(
          message: 'kyc.error.network', code: 'network');
    }
    return ServerFailure(message: 'kyc.error.unavailable', code: code);
  }
}

class FailureExpired extends ValidationFailure {
  const FailureExpired({super.code})
      : super(message: 'kyc.error.intent_expired');
}
