import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hivmeet/domain/entities/kyc.dart';

enum KycCaptureSource { camera, files }

abstract class KycCapturePort {
  Future<KycCapturedDocument?> capture({
    required KycDocumentType type,
    required KycCaptureSource source,
  });

  Future<void> deleteCopy(KycCapturedDocument document);
  Future<void> clearTemporaryCopies();
}

/// Native mobile capture with bounded local quality checks. The implementation
/// only retains copies created below the app's KYC temporary directory.
class DeviceKycCapturePort implements KycCapturePort {
  static const _directoryName = 'hivmeet_kyc';
  static const _nativeScannerDirectoryName = 'hivmeet_kyc_scan';
  final ImagePicker _picker;
  final ImageCropper _cropper;

  DeviceKycCapturePort({ImagePicker? picker, ImageCropper? cropper})
      : _picker = picker ?? ImagePicker(),
        _cropper = cropper ?? ImageCropper();

  @override
  Future<KycCapturedDocument?> capture({
    required KycDocumentType type,
    required KycCaptureSource source,
  }) async {
    final capturedSource = await _sourcePath(type: type, source: source);
    if (capturedSource == null) return null;

    final sourceFile = File(capturedSource.path);
    File? temporary;
    var retained = false;
    try {
      if (!await sourceFile.exists()) return null;
      final mimeType = _mimeType(capturedSource.path);
      if (mimeType == null ||
          (type.isSelfie && mimeType == 'application/pdf')) {
        throw const KycCaptureException('unsupported_format');
      }

      final length = await sourceFile.length();
      if (length <= 0 || length > type.maxBytes) {
        throw const KycCaptureException('file_too_large');
      }

      temporary = await _temporaryFile(
        extension: mimeType == 'application/pdf' ? 'pdf' : 'jpg',
      );
      final isImage = mimeType.startsWith('image/');
      if (isImage) {
        await _validateImage(
          sourceFile,
          requireDocumentRectangle: !type.isSelfie,
        );
        final cropped = await _cropImage(capturedSource.path);
        // Cancellation is expected. The finally block removes the empty
        // destination allocated before launching the native activity.
        if (cropped == null) return null;
        final croppedFile = File(cropped.path);
        try {
          await croppedFile.copy(temporary.path);
          await _validateImage(
            temporary,
            requireDocumentRectangle: !type.isSelfie,
          );
        } finally {
          if (croppedFile.path != sourceFile.path) {
            await _deleteIfExists(croppedFile);
          }
        }
      } else {
        await sourceFile.copy(temporary.path);
      }

      final copiedSize = await temporary.length();
      if (copiedSize <= 0 || copiedSize > type.maxBytes) {
        throw const KycCaptureException('file_too_large');
      }
      retained = true;
      return KycCapturedDocument(
        type: type,
        localPath: temporary.path,
        mimeType: isImage ? 'image/jpeg' : 'application/pdf',
        sizeBytes: copiedSize,
        // Cropping creates a new raster file and never mutates the source.
        redactedCopy: isImage,
      );
    } on KycCaptureException {
      rethrow;
    } on PlatformException {
      throw const KycCaptureException('capture_failed');
    } on MissingPluginException {
      throw const KycCaptureException('capture_failed');
    } finally {
      if (!retained && temporary != null) {
        await _deleteIfExists(temporary);
      }
      if (capturedSource.deleteAfterUse) {
        await _deleteIfExists(sourceFile);
      }
    }
  }

  Future<CroppedFile?> _cropImage(String sourcePath) async {
    try {
      return await _cropper.cropImage(
        sourcePath: sourcePath,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 92,
        uiSettings: [
          AndroidUiSettings(
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
          IOSUiSettings(),
        ],
      );
    } on MissingPluginException {
      throw const KycCaptureException('cropper_unavailable');
    } on PlatformException {
      throw const KycCaptureException('cropper_unavailable');
    }
  }

  Future<_CapturedSource?> _sourcePath({
    required KycDocumentType type,
    required KycCaptureSource source,
  }) async {
    if (source == KycCaptureSource.camera) {
      if (!type.isSelfie) {
        final scannerResult = await _KycNativeDocumentScanner.scan();
        if (scannerResult?.cancelled == true) return null;
        if (scannerResult?.path != null) {
          return _CapturedSource(scannerResult!.path!, deleteAfterUse: true);
        }
      }
      if (!(await Permission.camera.request()).isGranted) {
        throw const KycCaptureException('camera_permission_denied');
      }
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        requestFullMetadata: false,
      );
      // Camera captures are plugin-owned cache files. They are copied into
      // the KYC directory then removed regardless of success or cancellation.
      return image == null
          ? null
          : _CapturedSource(image.path, deleteAfterUse: true);
    }
    final allowed = type.isSelfie
        ? const ['jpg', 'jpeg', 'png']
        : const ['jpg', 'jpeg', 'png', 'pdf'];
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowed,
      allowMultiple: false,
      withData: false,
    );
    final path = result?.files.single.path;
    return path == null ? null : _CapturedSource(path);
  }

  Future<void> _validateImage(
    File file, {
    required bool requireDocumentRectangle,
  }) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final width = frame.image.width;
    final height = frame.image.height;
    frame.image.dispose();
    codec.dispose();
    if (width < 600 || height < 400) {
      throw const KycCaptureException('image_quality_insufficient');
    }
    if (requireDocumentRectangle &&
        !await _KycNativeDocumentScanner.hasAcceptableDocumentRectangle(
          file.path,
        )) {
      throw const KycCaptureException('image_quality_insufficient');
    }
  }

  Future<File> _temporaryFile({required String extension}) async {
    final root = await getTemporaryDirectory();
    final directory =
        Directory('${root.path}${Platform.pathSeparator}$_directoryName');
    await directory.create(recursive: true);
    final random = Random.secure().nextInt(1 << 32).toRadixString(16);
    return File('${directory.path}${Platform.pathSeparator}$random.$extension');
  }

  String? _mimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return null;
  }

  @override
  Future<void> deleteCopy(KycCapturedDocument document) async {
    final file = File(document.localPath);
    final root = await _temporaryDirectory();
    if (file.path.startsWith('${root.path}${Platform.pathSeparator}') &&
        await file.exists()) {
      await _deleteIfExists(file);
    }
  }

  @override
  Future<void> clearTemporaryCopies() async {
    await _clearTemporaryDirectory(_directoryName);
    // The Android ML Kit scanner copies its result to this sibling directory
    // before Dart receives it. Clear it too if the app is backgrounded while
    // the scanner/cropper is open.
    await _clearTemporaryDirectory(_nativeScannerDirectoryName);
  }

  Future<Directory> _temporaryDirectory() async {
    final root = await getTemporaryDirectory();
    return Directory('${root.path}${Platform.pathSeparator}$_directoryName');
  }

  Future<void> _clearTemporaryDirectory(String name) async {
    final root = await getTemporaryDirectory();
    final directory = Directory('${root.path}${Platform.pathSeparator}$name');
    try {
      if (await directory.exists()) await directory.delete(recursive: true);
    } on FileSystemException {
      // Cleanup is best effort: a concurrent native activity may still be
      // releasing a cache handle while the app is backgrounded.
    }
  }

  Future<void> _deleteIfExists(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // A source/crop output left for the operating system's cache cleanup is
      // safer than propagating a cleanup race into the KYC user flow.
    }
  }
}

class KycCaptureException implements Exception {
  final String code;
  const KycCaptureException(this.code);
}

class _CapturedSource {
  final String path;
  final bool deleteAfterUse;
  const _CapturedSource(this.path, {this.deleteAfterUse = false});
}

class _NativeScanResult {
  final String? path;
  final bool cancelled;
  const _NativeScanResult({this.path, this.cancelled = false});
}

/// Local native helpers only. They never perform facial recognition, send an
/// image to a service, or return any document metadata to Dart.
class _KycNativeDocumentScanner {
  static const _channel = MethodChannel('hivmeet/kyc_capture');

  static Future<_NativeScanResult?> scan() async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'scanDocument',
      );
      if (raw == null) return null;
      if (raw['status'] == 'cancelled') {
        return const _NativeScanResult(cancelled: true);
      }
      final path = raw['path'];
      return path is String && path.isNotEmpty
          ? _NativeScanResult(path: path)
          : null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static Future<bool> hasAcceptableDocumentRectangle(String path) async {
    try {
      final accepted = await _channel.invokeMethod<bool>('assessDocument', {
        'path': path,
      });
      return accepted ?? true;
    } on MissingPluginException {
      return true;
    } on PlatformException {
      // The general local pixel and decode checks remain available when an OS
      // capability is unavailable. No image leaves the device.
      return true;
    }
  }
}
