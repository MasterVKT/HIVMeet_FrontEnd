import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hivmeet/core/network/api_client.dart';
import 'package:hivmeet/core/services/token_manager.dart';
import 'package:path_provider/path_provider.dart';

typedef MediaDownloadProgress = void Function(int received, int total);
typedef MediaAccountIdProvider = Future<String?> Function();
typedef MediaAppDirectoryProvider = Future<Directory> Function();

/// Returns a portable file name for exporting a downloaded attachment.
///
/// New message DTOs carry the sender's validated filename. Older messages can
/// lack it (or have the historical `attachment` fallback), so use their
/// immutable media kind to add an unambiguous conventional extension.
String mediaDownloadFileName({
  String? fileName,
  String? mediaType,
  String? mimeType,
}) {
  final supplied = fileName?.trim();
  final base = supplied == null || supplied.isEmpty ? 'attachment' : supplied;
  if (RegExp(r'\.[A-Za-z0-9]{1,10}$').hasMatch(base)) return base;
  return '$base${_defaultMediaExtension(mediaType, mimeType)}';
}

/// Returns the MIME type used by Android's system open action.
///
/// Valid server metadata takes precedence. The fallbacks only cover historic
/// messages that were persisted before MIME details became part of the DTO.
String? mediaDownloadMimeType({String? mediaType, String? mimeType}) {
  final supplied = mimeType?.trim().toLowerCase();
  if (supplied != null &&
      supplied.isNotEmpty &&
      supplied != 'application/octet-stream') {
    return supplied;
  }
  switch (mediaType?.trim().toLowerCase()) {
    case 'image':
      return 'image/jpeg';
    case 'video':
      return 'video/mp4';
    case 'audio':
      return 'audio/mpeg';
    default:
      return supplied;
  }
}

String _defaultMediaExtension(String? mediaType, String? mimeType) {
  switch (mimeType?.trim().toLowerCase()) {
    case 'image/png':
      return '.png';
    case 'image/webp':
      return '.webp';
    case 'audio/ogg':
      return '.ogg';
    case 'audio/wav':
      return '.wav';
  }
  switch (mediaType?.trim().toLowerCase()) {
    case 'image':
      return '.jpg';
    case 'video':
      return '.mp4';
    case 'audio':
      return '.mp3';
    default:
      return '';
  }
}

/// Result of an explicit attachment download kept in app-private storage.
/// It is intentionally never saved to Photos, MediaStore or the iOS gallery.
class MediaDownloadResult {
  final File file;
  final bool resumed;
  final bool restartedAfterRangeMismatch;
  final bool alreadyPresent;

  const MediaDownloadResult({
    required this.file,
    required this.resumed,
    this.restartedAfterRangeMismatch = false,
    this.alreadyPresent = false,
  });
}

/// Authenticated, resumable download service for one message attachment.
///
/// Completed files are private to the signed-in account and stored at
/// `message_media/<account>/<conversation>/<message>/<safe-file-name>` below
/// the application support directory. A partial download remains next to that
/// file as `.part`; only an atomically renamed completed file is shown as
/// available to the user.
class MediaDownloadService {
  final ApiClient _apiClient;
  final MediaAccountIdProvider? _accountIdProvider;
  final MediaAppDirectoryProvider _applicationDirectoryProvider;

  MediaDownloadService(
    this._apiClient, {
    TokenManager? tokenManager,
    MediaAccountIdProvider? accountIdProvider,
    MediaAppDirectoryProvider? applicationDirectoryProvider,
  })  : _accountIdProvider = accountIdProvider ??
            (tokenManager == null
                ? null
                : () async => (await tokenManager.getStoredUserData())?.id),
        _applicationDirectoryProvider =
            applicationDirectoryProvider ?? getApplicationSupportDirectory;

  /// Finds a completed download for the active account only.
  ///
  /// A missing, empty or size-mismatched target is not treated as downloaded.
  /// It is removed so the UI offers a safe authenticated download again.
  Future<File?> findCompleted({
    required String conversationId,
    required String messageId,
    required String fileName,
    int? expectedSizeBytes,
  }) async {
    final target = await _targetFile(
      conversationId: conversationId,
      messageId: messageId,
      fileName: fileName,
      createDirectory: false,
    );
    return _validCompletedFile(target, expectedSizeBytes: expectedSizeBytes);
  }

  Future<MediaDownloadResult> download({
    required String mediaDownloadUrl,
    required String conversationId,
    required String messageId,
    required String fileName,
    required CancelToken cancelToken,
    required MediaDownloadProgress onProgress,
    int? expectedSizeBytes,
  }) async {
    final target = await _targetFile(
      conversationId: conversationId,
      messageId: messageId,
      fileName: fileName,
      createDirectory: true,
    );
    final existingTarget = await _validCompletedFile(
      target,
      expectedSizeBytes: expectedSizeBytes,
    );
    if (existingTarget != null) {
      return MediaDownloadResult(
        file: existingTarget,
        resumed: false,
        alreadyPresent: true,
      );
    }

    final partial = File('${target.path}.part');
    var existingBytes = await _partialLength(partial, expectedSizeBytes);

    // A previous request may have received every byte and crashed before its
    // rename. With a trusted expected size we can finish it without another
    // network request.
    if (_hasExpectedSize(expectedSizeBytes) &&
        existingBytes == expectedSizeBytes) {
      await partial.rename(target.path);
      return MediaDownloadResult(file: target, resumed: existingBytes > 0);
    }

    final response = await _downloadIntoPartial(
      mediaDownloadUrl: mediaDownloadUrl,
      partial: partial,
      existingBytes: existingBytes,
      cancelToken: cancelToken,
      onProgress: onProgress,
    );

    if (existingBytes > 0 && response.statusCode != 206) {
      // A rolling deployment or proxy may ignore Range and return the full
      // file. Dio has already appended that response, so discard it and start
      // one clean request instead of leaving a corrupted concatenation.
      await _deleteIfExists(partial);
      existingBytes = 0;
      await _downloadIntoPartial(
        mediaDownloadUrl: mediaDownloadUrl,
        partial: partial,
        existingBytes: existingBytes,
        cancelToken: cancelToken,
        onProgress: onProgress,
      );
      await _finalize(
        partial: partial,
        target: target,
        expectedSizeBytes: expectedSizeBytes,
      );
      return MediaDownloadResult(
        file: target,
        resumed: false,
        restartedAfterRangeMismatch: true,
      );
    }

    await _finalize(
      partial: partial,
      target: target,
      expectedSizeBytes: expectedSizeBytes,
    );
    return MediaDownloadResult(file: target, resumed: existingBytes > 0);
  }

  Future<Response<void>> _downloadIntoPartial({
    required String mediaDownloadUrl,
    required File partial,
    required int existingBytes,
    required CancelToken cancelToken,
    required MediaDownloadProgress onProgress,
  }) {
    return _apiClient.download(
      mediaDownloadUrl,
      partial.path,
      cancelToken: cancelToken,
      fileAccessMode:
          existingBytes > 0 ? FileAccessMode.append : FileAccessMode.write,
      options: existingBytes > 0
          ? Options(headers: {'Range': 'bytes=$existingBytes-'})
          : null,
      onReceiveProgress: (received, total) {
        final totalBytes = total > 0 ? existingBytes + total : -1;
        onProgress(existingBytes + received, totalBytes);
      },
    );
  }

  Future<void> _finalize({
    required File partial,
    required File target,
    required int? expectedSizeBytes,
  }) async {
    final length = await _partialLength(partial, expectedSizeBytes);
    if (length <= 0) {
      throw StateError('empty_download');
    }
    if (_hasExpectedSize(expectedSizeBytes) && length != expectedSizeBytes) {
      throw StateError('incomplete_download');
    }
    await _deleteIfExists(target);
    await partial.rename(target.path);
  }

  Future<File?> _validCompletedFile(
    File target, {
    required int? expectedSizeBytes,
  }) async {
    if (!await target.exists()) return null;
    final length = await target.length();
    if (length <= 0 ||
        (_hasExpectedSize(expectedSizeBytes) && length != expectedSizeBytes)) {
      await target.delete();
      return null;
    }
    return target;
  }

  Future<int> _partialLength(File partial, int? expectedSizeBytes) async {
    if (!await partial.exists()) return 0;
    final length = await partial.length();
    if (length <= 0 ||
        (_hasExpectedSize(expectedSizeBytes) && length > expectedSizeBytes!)) {
      await partial.delete();
      return 0;
    }
    return length;
  }

  Future<File> _targetFile({
    required String conversationId,
    required String messageId,
    required String fileName,
    required bool createDirectory,
  }) async {
    final accountId = await _accountIdProvider?.call();
    if (accountId == null || accountId.trim().isEmpty) {
      throw StateError('download_account_unavailable');
    }
    final appDirectory = await _applicationDirectoryProvider();
    final directory = Directory([
      appDirectory.path,
      'message_media',
      _safeSegment(accountId, fallback: 'account'),
      _safeSegment(conversationId, fallback: 'conversation'),
      _safeSegment(messageId, fallback: 'message'),
    ].join(Platform.pathSeparator));
    if (createDirectory && !await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File(
      '${directory.path}${Platform.pathSeparator}'
      '${_safeSegment(fileName, fallback: 'attachment')}',
    );
  }

  Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) await file.delete();
  }

  bool _hasExpectedSize(int? expectedSizeBytes) =>
      expectedSizeBytes != null && expectedSizeBytes > 0;

  String _safeSegment(String value, {required String fallback}) {
    final sanitized = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    if (sanitized.isEmpty || sanitized == '.' || sanitized == '..') {
      return fallback;
    }
    return sanitized.length > 120 ? sanitized.substring(0, 120) : sanitized;
  }
}
