import 'package:dio/dio.dart';
import 'package:hivmeet/core/network/api_client.dart';

/// KYC control-plane calls plus the authenticated local-development transfer.
/// Direct object-store uploads remain outside [ApiClient].
class KycApi {
  final ApiClient _apiClient;

  KycApi(this._apiClient);

  Future<Response<Map<String, dynamic>>> getStatus() =>
      _apiClient.get('/user-profiles/me/verification/');

  Future<Response<Map<String, dynamic>>> startAttempt(
    Map<String, dynamic> payload,
  ) =>
      _apiClient.post('/user-profiles/me/verification/start/', data: payload);

  Future<Response<Map<String, dynamic>>> createUploadIntent(
    Map<String, dynamic> payload,
  ) =>
      _apiClient.post(
        '/user-profiles/me/verification/upload-intents/',
        data: payload,
      );

  Future<Response<Map<String, dynamic>>> completeUpload(String uploadId) =>
      _apiClient.post(
        '/user-profiles/me/verification/upload-intents/complete/',
        data: {'upload_id': uploadId},
      );

  Future<Response<Map<String, dynamic>>> uploadMultipartFile({
    required String uploadId,
    required String localPath,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(localPath),
    });
    return _apiClient.post(
      '/user-profiles/me/verification/upload-intents/$uploadId/file/',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: onSendProgress,
    );
  }

  Future<Response<Map<String, dynamic>>> submitAttempt(
    Map<String, dynamic> payload,
  ) =>
      _apiClient.post('/user-profiles/me/verification/submit/', data: payload);
}
