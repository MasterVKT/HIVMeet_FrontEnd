import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/kyc/kyc_access_controller.dart';
import 'package:hivmeet/core/kyc/kyc_capture_port.dart';
import 'package:hivmeet/core/kyc/kyc_upload_resume_store.dart';
import 'package:hivmeet/core/realtime/realtime_event.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/kyc.dart';
import 'package:hivmeet/domain/repositories/kyc_repository.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/kyc/kyc_cubit.dart';
import 'package:hivmeet/presentation/blocs/kyc/kyc_state.dart';
import 'package:hivmeet/presentation/pages/verification/verification_page.dart';

class _Cleaner implements KycMediaCacheCleaner {
  int calls = 0;

  @override
  Future<void> clearPrivateMedia() async => calls++;
}

class _Capture implements KycCapturePort {
  int deleted = 0;
  int cleared = 0;
  int captures = 0;
  bool cancelNextCapture = false;
  KycCaptureException? nextCaptureError;

  @override
  Future<KycCapturedDocument?> capture({
    required KycDocumentType type,
    required KycCaptureSource source,
  }) async {
    captures++;
    if (cancelNextCapture) {
      cancelNextCapture = false;
      return null;
    }
    final error = nextCaptureError;
    if (error != null) {
      nextCaptureError = null;
      throw error;
    }
    return KycCapturedDocument(
      type: type,
      localPath: '/temporary/${type.wire}.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 1024,
      redactedCopy: true,
    );
  }

  @override
  Future<void> clearTemporaryCopies() async => cleared++;

  @override
  Future<void> deleteCopy(KycCapturedDocument document) async => deleted++;
}

class _BlockingCapture extends _Capture {
  final Completer<KycCapturedDocument?> _result = Completer();

  @override
  Future<KycCapturedDocument?> capture({
    required KycDocumentType type,
    required KycCaptureSource source,
  }) {
    captures++;
    return _result.future;
  }

  void complete(KycDocumentType type) {
    _result.complete(KycCapturedDocument(
      type: type,
      localPath: '/temporary/${type.wire}.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 1024,
      redactedCopy: true,
    ));
  }
}

class _ResumeStore implements KycUploadResumeStore {
  final Map<String, Map<KycDocumentType, String>> _values = {};

  @override
  Future<void> clear(String attemptId) async => _values.remove(attemptId);

  @override
  Future<void> clearAll() async => _values.clear();

  @override
  Future<Map<KycDocumentType, String>> read(String attemptId) async =>
      Map<KycDocumentType, String>.from(_values[attemptId] ?? const {});

  @override
  Future<void> remove({
    required String attemptId,
    required KycDocumentType type,
  }) async {
    _values[attemptId]?.remove(type);
  }

  @override
  Future<void> save({
    required String attemptId,
    required KycDocumentType type,
    required String uploadId,
  }) async {
    (_values[attemptId] ??= {})[type] = uploadId;
  }
}

class _Repository implements KycRepository {
  int completed = 0;
  int statusReads = 0;
  int blockingStatusReads = 0;
  Completer<KycSnapshot>? pendingStatus;
  KycSnapshot statusSnapshot = const KycSnapshot.empty();
  final Set<KycDocumentType> acceptedTypes = {};
  KycDocumentType? rejectedType;
  KycUploadTransport uploadTransport = KycUploadTransport.directPut;

  @override
  Future<Either<Failure, void>> completeUpload(
      {required String uploadId}) async {
    completed++;
    acceptedTypes.add(KycDocumentType.values.firstWhere(
      (type) => uploadId.startsWith(type.wire),
    ));
    return const Right(null);
  }

  @override
  Future<Either<Failure, KycUploadIntent>> createUploadIntent({
    required String attemptId,
    required KycCapturedDocument document,
    required String idempotencyKey,
  }) async =>
      Right(KycUploadIntent(
        uploadId: '${document.type.wire}-upload',
        uploadUri: uploadTransport == KycUploadTransport.directPut
            ? Uri.parse('https://uploads.example.test/put')
            : null,
        requiredHeaders: const {
          'Content-Type': 'image/jpeg',
          'Content-Length': '1024',
        },
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        transport: uploadTransport,
      ));

  @override
  Future<Either<Failure, KycSnapshot>> getStatus() async {
    statusReads++;
    final pending = pendingStatus;
    if (pending != null) {
      pendingStatus = null;
      blockingStatusReads++;
      return Right(await pending.future);
    }
    if (rejectedType != null) {
      return Right(KycSnapshot(
        attemptId: 'attempt-1',
        status: KycStatus.pendingId,
        documents: [
          KycDocumentStatus(
            type: rejectedType!,
            state: KycDocumentState.rejected,
          ),
        ],
      ));
    }
    if (acceptedTypes.isNotEmpty) {
      return Right(KycSnapshot(
        attemptId: 'attempt-1',
        status: KycStatus.pendingId,
        documents: KycDocumentType.values
            .map((type) => KycDocumentStatus(
                  type: type,
                  state: acceptedTypes.contains(type)
                      ? KycDocumentState.accepted
                      : KycDocumentState.missing,
                ))
            .toList(growable: false),
      ));
    }
    return Right(statusSnapshot);
  }

  @override
  Future<Either<Failure, KycStartSession>> startAttempt({
    required String consentVersion,
    required String idempotencyKey,
  }) async =>
      Right(KycStartSession(
        attemptId: 'attempt-1',
        status: KycStatus.pendingId,
        selfieChallengeCode: 'CODE-123',
        selfieChallengeExpiresAt:
            DateTime.now().add(const Duration(minutes: 5)),
      ));

  @override
  Future<Either<Failure, KycSnapshot>> submitAttempt({
    required String attemptId,
    required Map<KycDocumentType, String> uploadIds,
    required String selfieChallengeCode,
    required String idempotencyKey,
  }) async =>
      const Right(KycSnapshot(
        attemptId: 'attempt-1',
        status: KycStatus.pendingReview,
      ));

  @override
  Future<Either<Failure, void>> uploadDocument({
    required KycCapturedDocument document,
    required KycUploadIntent intent,
    required void Function(int sent, int total) onProgress,
  }) async {
    onProgress(document.sizeBytes, document.sizeBytes);
    if (intent.transport == KycUploadTransport.backendMultipart) {
      acceptedTypes.add(document.type);
    }
    return const Right(null);
  }
}

void main() {
  Future<void> registerVerificationPageDependencies(KycCubit cubit) async {
    await getIt.reset();
    final localization = LocalizationService();
    await localization.initialize();
    getIt.registerSingleton<LocalizationService>(localization);
    getIt.registerSingleton<KycCubit>(cubit);
  }

  test('only an explicitly unexpired verified KYC unlocks access', () {
    expect(
      const KycSnapshot(attemptId: 'id', status: KycStatus.verified)
          .hasActiveAccess,
      isFalse,
    );
    expect(
      KycSnapshot(
        attemptId: 'id',
        status: KycStatus.verified,
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
      ).hasActiveAccess,
      isFalse,
    );
    expect(
      KycSnapshot(
        attemptId: 'id',
        status: KycStatus.verified,
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ).hasActiveAccess,
      isTrue,
    );
  });

  test('losing active KYC purges private media cache', () async {
    final cleaner = _Cleaner();
    final access = KycAccessController(cleaner);

    access.markActive(true);
    access.requireVerification();
    await Future<void>.delayed(Duration.zero);

    expect(access.hasActiveKyc, isFalse);
    expect(cleaner.calls, 1);
  });

  test('submits the three required documents to a pending human review',
      () async {
    final repository = _Repository();
    final capture = _Capture();
    final cleaner = _Cleaner();
    final bus = RealtimeEventBus();
    final cubit = KycCubit(
      repository: repository,
      capture: capture,
      access: KycAccessController(cleaner),
      resumeStore: _ResumeStore(),
      realtimeBus: bus,
    );
    addTearDown(() async {
      await cubit.close();
      bus.dispose();
    });

    await cubit.start(consentAccepted: true);
    for (final type in KycDocumentType.values) {
      await cubit.captureDocument(type: type, source: KycCaptureSource.camera);
    }
    await cubit.submit();

    expect(cubit.state.stage, KycUiStage.submitted);
    expect(cubit.state.snapshot.status, KycStatus.pendingReview);
    expect(repository.completed, 3);
    expect(capture.deleted, 3);
    expect(capture.cleared, greaterThanOrEqualTo(1));
  });

  test('local multipart transport does not call the direct completion route',
      () async {
    final repository = _Repository()
      ..uploadTransport = KycUploadTransport.backendMultipart;
    final bus = RealtimeEventBus();
    final cubit = KycCubit(
      repository: repository,
      capture: _Capture(),
      access: KycAccessController(_Cleaner()),
      resumeStore: _ResumeStore(),
      realtimeBus: bus,
    );
    addTearDown(() async {
      await cubit.close();
      bus.dispose();
    });

    await cubit.start(consentAccepted: true);
    for (final type in KycDocumentType.values) {
      await cubit.captureDocument(type: type, source: KycCaptureSource.files);
    }
    await cubit.submit();

    expect(cubit.state.stage, KycUiStage.submitted);
    expect(repository.completed, 0);
  });

  test('cancelling the cropper keeps the KYC session and no document copy',
      () async {
    final capture = _Capture()..cancelNextCapture = true;
    final bus = RealtimeEventBus();
    final cubit = KycCubit(
      repository: _Repository(),
      capture: capture,
      access: KycAccessController(_Cleaner()),
      resumeStore: _ResumeStore(),
      realtimeBus: bus,
    );
    addTearDown(() async {
      await cubit.close();
      bus.dispose();
    });

    await cubit.start(consentAccepted: true);
    await cubit.captureDocument(
      type: KycDocumentType.identityDocument,
      source: KycCaptureSource.files,
    );

    expect(capture.captures, 1);
    expect(cubit.state.session, isNotNull);
    expect(cubit.state.documents, isEmpty);
    expect(cubit.state.stage, KycUiStage.idle);
    expect(capture.cleared, 0);
  });

  testWidgets(
      'keeps a KYC draft while a system capture activity pauses Flutter',
      (tester) async {
    final capture = _BlockingCapture();
    final bus = RealtimeEventBus();
    final cubit = KycCubit(
      repository: _Repository(),
      capture: capture,
      access: KycAccessController(_Cleaner()),
      resumeStore: _ResumeStore(),
      realtimeBus: bus,
    );
    await registerVerificationPageDependencies(cubit);
    addTearDown(() async {
      await cubit.close();
      bus.dispose();
      await getIt.reset();
    });

    await cubit.start(consentAccepted: true);
    final captureFuture = cubit.captureDocument(
      type: KycDocumentType.identityDocument,
      source: KycCaptureSource.files,
    );
    await tester.pumpWidget(
      BlocProvider<KycCubit>.value(
        value: cubit,
        child: const MaterialApp(home: VerificationPage()),
      ),
    );
    await tester.pump();

    expect(cubit.state.stage, KycUiStage.capturing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(capture.cleared, 0);
    expect(cubit.state.session, isNotNull);

    capture.complete(KycDocumentType.identityDocument);
    await captureFuture;

    expect(cubit.state.documents,
        contains(KycDocumentType.identityDocument));
  });

  test('maps an unavailable cropper and purges drafts on background cleanup',
      () async {
    final capture = _Capture()
      ..nextCaptureError = const KycCaptureException('cropper_unavailable');
    final bus = RealtimeEventBus();
    final cubit = KycCubit(
      repository: _Repository(),
      capture: capture,
      access: KycAccessController(_Cleaner()),
      resumeStore: _ResumeStore(),
      realtimeBus: bus,
    );
    addTearDown(() async {
      await cubit.close();
      bus.dispose();
    });

    await cubit.start(consentAccepted: true);
    await cubit.captureDocument(
      type: KycDocumentType.identityDocument,
      source: KycCaptureSource.camera,
    );

    expect(cubit.state.stage, KycUiStage.failure);
    expect(cubit.state.errorCode, 'cropper_unavailable');

    await cubit.captureDocument(
      type: KycDocumentType.identityDocument,
      source: KycCaptureSource.camera,
    );
    expect(cubit.state.documents, contains(KycDocumentType.identityDocument));

    await cubit.clearSensitiveDrafts();
    expect(capture.cleared, 1);
    expect(cubit.state.session, isNull);
    expect(cubit.state.documents, isEmpty);
    expect(cubit.state.stage, KycUiStage.idle);
  });

  test('removing a selected document deletes its temporary copy', () async {
    final capture = _Capture();
    final bus = RealtimeEventBus();
    final cubit = KycCubit(
      repository: _Repository(),
      capture: capture,
      access: KycAccessController(_Cleaner()),
      resumeStore: _ResumeStore(),
      realtimeBus: bus,
    );
    addTearDown(() async {
      await cubit.close();
      bus.dispose();
    });

    await cubit.start(consentAccepted: true);
    await cubit.captureDocument(
      type: KycDocumentType.medicalDocument,
      source: KycCaptureSource.files,
    );
    await cubit.removeDocument(KycDocumentType.medicalDocument);

    expect(capture.deleted, 1);
    expect(cubit.state.documents, isEmpty);
  });

  test('a safe verification update refreshes the authoritative access state',
      () async {
    final repository = _Repository()
      ..statusSnapshot = KycSnapshot(
        attemptId: 'attempt-verified',
        status: KycStatus.verified,
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );
    final cleaner = _Cleaner();
    final access = KycAccessController(cleaner);
    final bus = RealtimeEventBus();
    final cubit = KycCubit(
      repository: repository,
      capture: _Capture(),
      access: access,
      resumeStore: _ResumeStore(),
      realtimeBus: bus,
    );
    addTearDown(() async {
      await cubit.close();
      bus.dispose();
    });

    bus.publish(const RealtimeEvent(
      type: RealtimeEventType.kycVerificationUpdated,
      source: RealtimeSource.websocket,
    ));
    await Future<void>.delayed(Duration.zero);

    expect(repository.statusReads, 1);
    expect(access.hasActiveKyc, isTrue);
  });

  test('keeps human review closed when technical validation rejects a document',
      () async {
    final repository = _Repository()
      ..rejectedType = KycDocumentType.identityDocument;
    final capture = _Capture();
    final bus = RealtimeEventBus();
    final cubit = KycCubit(
      repository: repository,
      capture: capture,
      access: KycAccessController(_Cleaner()),
      resumeStore: _ResumeStore(),
      realtimeBus: bus,
    );
    addTearDown(() async {
      await cubit.close();
      bus.dispose();
    });

    await cubit.start(consentAccepted: true);
    for (final type in KycDocumentType.values) {
      await cubit.captureDocument(type: type, source: KycCaptureSource.camera);
    }
    await cubit.submit();

    expect(cubit.state.stage, KycUiStage.failure);
    expect(cubit.state.errorCode, 'technical_rejected');
    expect(cubit.state.documents,
        isNot(contains(KycDocumentType.identityDocument)));
    expect(repository.completed, 1);
  });

  test('resumes accepted uploads without retaining a URL or local document',
      () async {
    final repository = _Repository()
      ..acceptedTypes.add(KycDocumentType.identityDocument);
    final resumeStore = _ResumeStore();
    await resumeStore.save(
      attemptId: 'attempt-1',
      type: KycDocumentType.identityDocument,
      uploadId: 'identity_document-upload',
    );
    final capture = _Capture();
    final bus = RealtimeEventBus();
    final cubit = KycCubit(
      repository: repository,
      capture: capture,
      access: KycAccessController(_Cleaner()),
      resumeStore: resumeStore,
      realtimeBus: bus,
    );
    addTearDown(() async {
      await cubit.close();
      bus.dispose();
    });

    await cubit.start(consentAccepted: true);
    expect(cubit.state.documents, isEmpty);
    expect(cubit.state.hasAcceptedDocument(KycDocumentType.identityDocument),
        isTrue);
    await cubit.captureDocument(
      type: KycDocumentType.medicalDocument,
      source: KycCaptureSource.files,
    );
    await cubit.captureDocument(
      type: KycDocumentType.selfieWithCode,
      source: KycCaptureSource.camera,
    );
    await cubit.submit();

    expect(repository.completed, 2);
    expect(cubit.state.stage, KycUiStage.submitted);
  });

  test('persists a confirmed upload before technical processing completes',
      () async {
    final repository = _Repository();
    final resumeStore = _ResumeStore();
    final bus = RealtimeEventBus();
    final cubit = KycCubit(
      repository: repository,
      capture: _Capture(),
      access: KycAccessController(_Cleaner()),
      resumeStore: resumeStore,
      realtimeBus: bus,
    );
    addTearDown(() async {
      await cubit.close();
      bus.dispose();
    });

    await cubit.start(consentAccepted: true);
    for (final type in KycDocumentType.values) {
      await cubit.captureDocument(type: type, source: KycCaptureSource.files);
    }
    final technicalResult = Completer<KycSnapshot>();
    repository.pendingStatus = technicalResult;
    final submission = cubit.submit();
    for (var i = 0; i < 10 && repository.blockingStatusReads == 0; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(repository.blockingStatusReads, 1);
    expect(
      await resumeStore.read('attempt-1'),
      containsPair(KycDocumentType.identityDocument, 'identity_document-upload'),
    );

    await cubit.clearSensitiveDrafts();
    technicalResult.complete(const KycSnapshot.empty());
    await submission;
  });
}
