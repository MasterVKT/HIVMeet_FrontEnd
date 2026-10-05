import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/network/api_client.dart';
import 'package:hivmeet/core/services/media_download_service.dart';

class _FakeDownloadApiClient extends Fake implements ApiClient {
  _FakeDownloadApiClient(this.payload);

  final List<int> payload;
  final List<String?> requestedRanges = [];
  DioExceptionType? failFirstAttemptWith;
  bool ignoreNextRange = false;
  int _attempts = 0;

  @override
  Future<Response<void>> download(
    String path,
    String savePath, {
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    FileAccessMode fileAccessMode = FileAccessMode.write,
  }) async {
    _attempts++;
    final range = options?.headers?['Range']?.toString();
    requestedRanges.add(range);
    final ignoreRange = range != null && ignoreNextRange;
    if (ignoreRange) ignoreNextRange = false;

    final start = ignoreRange || range == null ? 0 : _rangeStart(range);
    final bytes = payload.sublist(start);
    final file = File(savePath);
    await file.parent.create(recursive: true);

    if (failFirstAttemptWith != null && _attempts == 1) {
      final received = bytes.take(3).toList(growable: false);
      await file.writeAsBytes(received, mode: FileMode.write);
      onReceiveProgress?.call(received.length, bytes.length);
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: failFirstAttemptWith!,
      );
    }

    await file.writeAsBytes(
      bytes,
      mode: fileAccessMode == FileAccessMode.append
          ? FileMode.append
          : FileMode.write,
    );
    onReceiveProgress?.call(bytes.length, bytes.length);
    return Response<void>(
      requestOptions: RequestOptions(path: path),
      statusCode: range == null || ignoreRange ? 200 : 206,
    );
  }

  int _rangeStart(String range) {
    final match = RegExp(r'^bytes=(\d+)-$').firstMatch(range);
    if (match == null) throw ArgumentError.value(range, 'range');
    return int.parse(match.group(1)!);
  }
}

void main() {
  const payload = <int>[1, 2, 3, 4, 5, 6];
  late Directory root;

  setUp(() async {
    root =
        await Directory.systemTemp.createTemp('hivmeet-media-download-test-');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  MediaDownloadService serviceFor(
    _FakeDownloadApiClient api, {
    required String accountId,
  }) {
    return MediaDownloadService(
      api,
      accountIdProvider: () async => accountId,
      applicationDirectoryProvider: () async => root,
    );
  }

  Future<MediaDownloadResult> download(
    MediaDownloadService service,
  ) {
    return service.download(
      mediaDownloadUrl: 'conversations/conv/messages/message/media/',
      conversationId: 'conv/with/slash',
      messageId: 'message:one',
      fileName: 'attachment ?.mp4',
      expectedSizeBytes: payload.length,
      cancelToken: CancelToken(),
      onProgress: (_, __) {},
    );
  }

  group('MediaDownloadService', () {
    test('adds usable metadata for historic attachments without a filename',
        () {
      expect(
        mediaDownloadFileName(mediaType: 'video'),
        'attachment.mp4',
      );
      expect(
        mediaDownloadMimeType(mediaType: 'video'),
        'video/mp4',
      );
      expect(
        mediaDownloadFileName(
          fileName: 'photo',
          mediaType: 'image',
          mimeType: 'image/png',
        ),
        'photo.png',
      );
      expect(
        mediaDownloadMimeType(
          mediaType: 'image',
          mimeType: 'image/png',
        ),
        'image/png',
      );
      expect(
        mediaDownloadFileName(
          fileName: 'sender-file.webm',
          mediaType: 'video',
        ),
        'sender-file.webm',
      );
    });

    test(
        'stores a completed file privately by account, conversation and message',
        () async {
      final api = _FakeDownloadApiClient(payload);
      final service = serviceFor(api, accountId: 'account A');

      final result = await download(service);

      expect(await result.file.readAsBytes(), payload);
      expect(
        result.file.path,
        contains(
          'message_media${Platform.pathSeparator}account_A'
          '${Platform.pathSeparator}conv_with_slash'
          '${Platform.pathSeparator}message_one${Platform.pathSeparator}',
        ),
      );
      final restoredAfterRestart = serviceFor(api, accountId: 'account A');
      final restored = await restoredAfterRestart.findCompleted(
        conversationId: 'conv/with/slash',
        messageId: 'message:one',
        fileName: 'attachment ?.mp4',
        expectedSizeBytes: payload.length,
      );
      expect(restored?.path, result.file.path);

      final sameNameOtherMessage = await service.download(
        mediaDownloadUrl: 'conversations/conv/messages/message-two/media/',
        conversationId: 'conv/with/slash',
        messageId: 'message:two',
        fileName: 'attachment ?.mp4',
        expectedSizeBytes: payload.length,
        cancelToken: CancelToken(),
        onProgress: (_, __) {},
      );
      expect(sameNameOtherMessage.file.path, isNot(result.file.path));
      expect(await sameNameOtherMessage.file.readAsBytes(), payload);

      final unsafeName = await service.download(
        mediaDownloadUrl: 'conversations/conv/messages/unsafe/media/',
        conversationId: 'conv/with/slash',
        messageId: 'unsafe-name',
        fileName: '..',
        expectedSizeBytes: payload.length,
        cancelToken: CancelToken(),
        onProgress: (_, __) {},
      );
      expect(unsafeName.file.uri.pathSegments.last, 'attachment');

      final otherAccount = serviceFor(api, accountId: 'account B');
      expect(
        await otherAccount.findCompleted(
          conversationId: 'conv/with/slash',
          messageId: 'message:one',
          fileName: 'attachment ?.mp4',
          expectedSizeBytes: payload.length,
        ),
        isNull,
      );
    });

    test('keeps a cancelled partial download and resumes it with Range',
        () async {
      final api = _FakeDownloadApiClient(payload)
        ..failFirstAttemptWith = DioExceptionType.cancel;
      final service = serviceFor(api, accountId: 'account');

      await expectLater(download(service), throwsA(isA<DioException>()));
      final result = await download(service);

      expect(result.resumed, isTrue);
      expect(result.restartedAfterRangeMismatch, isFalse);
      expect(await result.file.readAsBytes(), payload);
      expect(api.requestedRanges, [null, 'bytes=3-']);
      expect(await File('${result.file.path}.part').exists(), isFalse);
    });

    test('keeps a network-interrupted partial download and resumes it safely',
        () async {
      final api = _FakeDownloadApiClient(payload)
        ..failFirstAttemptWith = DioExceptionType.connectionError;
      final service = serviceFor(api, accountId: 'account');

      await expectLater(download(service), throwsA(isA<DioException>()));
      final result = await download(service);

      expect(result.resumed, isTrue);
      expect(await result.file.readAsBytes(), payload);
      expect(api.requestedRanges, [null, 'bytes=3-']);
    });

    test('restarts cleanly when a Range request receives 200 instead of 206',
        () async {
      final api = _FakeDownloadApiClient(payload)
        ..failFirstAttemptWith = DioExceptionType.cancel;
      final service = serviceFor(api, accountId: 'account');

      await expectLater(download(service), throwsA(isA<DioException>()));
      api.ignoreNextRange = true;
      final result = await download(service);

      expect(result.restartedAfterRangeMismatch, isTrue);
      expect(result.resumed, isFalse);
      expect(await result.file.readAsBytes(), payload);
      expect(api.requestedRanges, [null, 'bytes=3-', null]);
    });

    test('removes a completed file whose known expected size no longer matches',
        () async {
      final api = _FakeDownloadApiClient(payload);
      final service = serviceFor(api, accountId: 'account');
      final result = await download(service);
      await result.file.writeAsBytes([1, 2]);

      final restored = await service.findCompleted(
        conversationId: 'conv/with/slash',
        messageId: 'message:one',
        fileName: 'attachment ?.mp4',
        expectedSizeBytes: payload.length,
      );

      expect(restored, isNull);
      expect(await result.file.exists(), isFalse);
    });
  });
}
