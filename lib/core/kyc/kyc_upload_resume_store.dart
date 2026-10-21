import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hivmeet/domain/entities/kyc.dart';

/// Keeps only opaque identifiers for uploads confirmed by the server long
/// enough to resume an interrupted KYC flow. It deliberately never stores a
/// signed URL, local path, file name, document bytes or selfie challenge.
abstract class KycUploadResumeStore {
  Future<Map<KycDocumentType, String>> read(String attemptId);
  Future<void> save({
    required String attemptId,
    required KycDocumentType type,
    required String uploadId,
  });
  Future<void> remove(
      {required String attemptId, required KycDocumentType type});
  Future<void> clear(String attemptId);
  Future<void> clearAll();
}

class SecureKycUploadResumeStore implements KycUploadResumeStore {
  static const _storageKey = 'hivmeet.kyc.resumable_upload_ids.v1';
  static final _safeIdentifier = RegExp(r'^[A-Za-z0-9_-]{8,128}$');

  final FlutterSecureStorage _storage;

  SecureKycUploadResumeStore(this._storage);

  @override
  Future<Map<KycDocumentType, String>> read(String attemptId) async {
    final all = await _readAll();
    final raw = all[attemptId];
    if (raw is! Map) return const {};
    final result = <KycDocumentType, String>{};
    for (final type in KycDocumentType.values) {
      final value = raw[type.wire];
      if (value is String && _safeIdentifier.hasMatch(value)) {
        result[type] = value;
      }
    }
    return result;
  }

  @override
  Future<void> save({
    required String attemptId,
    required KycDocumentType type,
    required String uploadId,
  }) async {
    if (!_safeIdentifier.hasMatch(attemptId) ||
        !_safeIdentifier.hasMatch(uploadId)) {
      return;
    }
    final all = await _readAll();
    final existing = all[attemptId] is Map
        ? Map<String, dynamic>.from(all[attemptId] as Map)
        : <String, dynamic>{};
    existing[type.wire] = uploadId;
    all[attemptId] = existing;
    await _writeAll(all);
  }

  @override
  Future<void> remove({
    required String attemptId,
    required KycDocumentType type,
  }) async {
    final all = await _readAll();
    final raw = all[attemptId];
    if (raw is! Map) return;
    final existing = Map<String, dynamic>.from(raw)..remove(type.wire);
    if (existing.isEmpty) {
      all.remove(attemptId);
    } else {
      all[attemptId] = existing;
    }
    await _writeAll(all);
  }

  @override
  Future<void> clear(String attemptId) async {
    final all = await _readAll();
    if (all.remove(attemptId) != null) await _writeAll(all);
  }

  @override
  Future<void> clearAll() => _storage.delete(key: _storageKey);

  Future<Map<String, dynamic>> _readAll() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      final decoded = raw == null ? null : jsonDecode(raw);
      return decoded is Map<String, dynamic>
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
    } catch (_) {
      // Corrupt or unavailable local storage must never block KYC or leak its
      // contents to logs.  The user can safely restart the pending flow.
      return <String, dynamic>{};
    }
  }

  Future<void> _writeAll(Map<String, dynamic> value) async {
    try {
      if (value.isEmpty) {
        await _storage.delete(key: _storageKey);
      } else {
        await _storage.write(key: _storageKey, value: jsonEncode(value));
      }
    } catch (_) {
      // Resuming is an enhancement; direct upload and server-side validation
      // remain authoritative if the secure store is temporarily unavailable.
    }
  }
}
