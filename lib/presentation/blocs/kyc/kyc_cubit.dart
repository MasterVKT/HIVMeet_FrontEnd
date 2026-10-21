import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/kyc/kyc_access_controller.dart';
import 'package:hivmeet/core/kyc/kyc_capture_port.dart';
import 'package:hivmeet/core/kyc/kyc_upload_resume_store.dart';
import 'package:hivmeet/domain/entities/kyc.dart';
import 'package:hivmeet/domain/repositories/kyc_repository.dart';
import 'package:hivmeet/core/realtime/realtime_event.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/presentation/blocs/kyc/kyc_state.dart';

class KycCubit extends Cubit<KycState> {
  static const consentVersion = 'kyc-v1-development';

  final KycRepository _repository;
  final KycCapturePort _capture;
  final KycAccessController _access;
  final KycUploadResumeStore _resumeStore;
  final Random _random;
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;
  int _flowGeneration = 0;

  static const _technicalValidationPollInterval = Duration(seconds: 2);
  static const _technicalValidationPollLimit = 150;

  KycCubit({
    required KycRepository repository,
    required KycCapturePort capture,
    required KycAccessController access,
    required KycUploadResumeStore resumeStore,
    required RealtimeEventBus realtimeBus,
    Random? random,
  })  : _repository = repository,
        _capture = capture,
        _access = access,
        _resumeStore = resumeStore,
        _random = random ?? Random.secure(),
        super(const KycState()) {
    _realtimeSubscription = realtimeBus.events.listen((event) {
      if (event.type == RealtimeEventType.appResumed ||
          event.type == RealtimeEventType.kycVerificationUpdated) {
        refresh();
      }
    });
  }

  Future<void> refresh() async {
    if (isClosed || state.isBusy) return;
    // A stale client cache must never retain access while the authoritative
    // server status cannot be revalidated.
    _access.requireVerification();
    emit(state.copyWith(stage: KycUiStage.loading, clearError: true));
    final result = await _repository.getStatus();
    await result.fold<Future<void>>(
      (failure) async => _emitFailure(failure),
      (snapshot) async {
        final acceptedUploadIds =
            await _resumeStore.read(snapshot.attemptId ?? '');
        if (isClosed) return;
        _access.markActive(snapshot.hasActiveAccess);
        emit(state.copyWith(
          snapshot: snapshot,
          acceptedUploadIds: acceptedUploadIds,
          stage: KycUiStage.idle,
          clearError: true,
        ));
      },
    );
  }

  Future<void> start({required bool consentAccepted}) async {
    if (!consentAccepted || state.isBusy) {
      if (!consentAccepted) _emitCode('consent_required');
      return;
    }
    _access.requireVerification();
    emit(state.copyWith(stage: KycUiStage.loading, clearError: true));
    final result = await _repository.startAttempt(
      consentVersion: consentVersion,
      idempotencyKey: _idempotencyKey(),
    );
    await result.fold<Future<void>>((failure) async => _emitFailure(failure),
        (session) async {
      final status = await _repository.getStatus();
      final snapshot = status.fold<KycSnapshot>(
        (_) =>
            KycSnapshot(attemptId: session.attemptId, status: session.status),
        (value) => value,
      );
      final acceptedUploadIds = await _resumeStore.read(session.attemptId);
      if (isClosed) return;
      emit(state.copyWith(
        snapshot: snapshot,
        session: session,
        stage: KycUiStage.idle,
        documents: const {},
        intents: const {},
        uploadedTypes: const {},
        acceptedUploadIds: acceptedUploadIds,
        uploadProgress: const {},
        clearError: true,
      ));
    });
  }

  Future<void> captureDocument({
    required KycDocumentType type,
    required KycCaptureSource source,
  }) async {
    if (state.isBusy || state.session == null) return;
    emit(state.copyWith(stage: KycUiStage.capturing, clearError: true));
    try {
      final document = await _capture.capture(type: type, source: source);
      if (document == null) {
        emit(state.copyWith(stage: KycUiStage.idle));
        return;
      }
      final next =
          Map<KycDocumentType, KycCapturedDocument>.from(state.documents)
            ..[type] = document;
      emit(state.copyWith(
        stage: KycUiStage.idle,
        documents: next,
        uploadedTypes: {...state.uploadedTypes}..remove(type),
        clearError: true,
      ));
    } on KycCaptureException catch (error) {
      _emitCode(error.code);
    } catch (_) {
      _emitCode('capture_failed');
    }
  }

  Future<void> removeDocument(KycDocumentType type) async {
    final document = state.documents[type];
    if (document == null) return;
    await _capture.deleteCopy(document);
    final next = Map<KycDocumentType, KycCapturedDocument>.from(state.documents)
      ..remove(type);
    emit(state.copyWith(
      documents: next,
      intents: {...state.intents}..remove(type),
      uploadedTypes: {...state.uploadedTypes}..remove(type),
      uploadProgress: {...state.uploadProgress}..remove(type),
      stage: KycUiStage.idle,
      clearError: true,
    ));
  }

  Future<void> submit() async {
    final session = state.session;
    if (session == null || !state.canSubmit) {
      _emitCode('documents_required');
      return;
    }
    if (!session.selfieChallengeExpiresAt.isAfter(DateTime.now())) {
      _emitCode('challenge_expired');
      return;
    }

    final generation = ++_flowGeneration;
    final uploadIds = <KycDocumentType, String>{};
    for (final type in KycDocumentType.values) {
      if (!_isCurrentFlow(generation)) return;
      final acceptedUploadId = state.hasAcceptedDocument(type)
          ? state.acceptedUploadIds[type]
          : null;
      if (acceptedUploadId != null) {
        uploadIds[type] = acceptedUploadId;
        continue;
      }
      final document = state.documents[type];
      if (document == null) {
        _emitCode('documents_required');
        return;
      }
      emit(state.copyWith(stage: KycUiStage.uploading, clearError: true));
      final intent = state.intents[type] ??
          await _newIntent(session.attemptId, document, type);
      if (intent == null || !_isCurrentFlow(generation)) return;

      if (!state.uploadedTypes.contains(type)) {
        final upload = await _repository.uploadDocument(
          document: document,
          intent: intent,
          onProgress: (sent, total) {
            if (isClosed || total <= 0) return;
            final progress =
                Map<KycDocumentType, double>.from(state.uploadProgress)
                  ..[type] = (sent / total).clamp(0, 1);
            emit(state.copyWith(uploadProgress: progress));
          },
        );
        final failed = upload.fold<Failure?>((failure) => failure, (_) => null);
        if (failed != null || !_isCurrentFlow(generation)) {
          if (failed == null) return;
          _emitFailure(failed);
          return;
        }
        emit(state.copyWith(uploadedTypes: {...state.uploadedTypes, type}));
      }

      if (intent.requiresCompletion) {
        final complete =
            await _repository.completeUpload(uploadId: intent.uploadId);
        final failed =
            complete.fold<Failure?>((failure) => failure, (_) => null);
        if (failed != null || !_isCurrentFlow(generation)) {
          if (failed == null) return;
          _emitFailure(failed);
          return;
        }
      }
      await _capture.deleteCopy(document);
      if (!_isCurrentFlow(generation)) return;
      // The server has confirmed receipt of this opaque upload id. Persist it
      // before waiting for the asynchronous technical check so a worker that
      // completes after a client timeout can still be resumed safely.
      await _resumeStore.save(
        attemptId: session.attemptId,
        type: type,
        uploadId: intent.uploadId,
      );
      if (!_isCurrentFlow(generation)) return;
      final accepted = await _waitForTechnicalAcceptance(
        type: type,
        generation: generation,
      );
      if (!accepted || !_isCurrentFlow(generation)) return;
      uploadIds[type] = intent.uploadId;
      emit(state.copyWith(
        acceptedUploadIds: {...state.acceptedUploadIds, type: intent.uploadId},
      ));
    }

    final submitted = await _repository.submitAttempt(
      attemptId: session.attemptId,
      uploadIds: uploadIds,
      selfieChallengeCode: session.selfieChallengeCode,
      idempotencyKey: _idempotencyKey(),
    );
    await submitted.fold<Future<void>>(
      (failure) async => _emitFailure(failure),
      (snapshot) async {
        if (!_isCurrentFlow(generation)) return;
        await _capture.clearTemporaryCopies();
        await _resumeStore.clear(session.attemptId);
        _access.markActive(false);
        emit(KycState(snapshot: snapshot, stage: KycUiStage.submitted));
      },
    );
  }

  Future<void> clearSensitiveDrafts() async {
    _flowGeneration++;
    await _capture.clearTemporaryCopies();
    if (!isClosed) {
      emit(state.copyWith(
        documents: const {},
        intents: const {},
        uploadedTypes: const {},
        uploadProgress: const {},
        clearSession: true,
        stage: KycUiStage.idle,
        clearError: true,
      ));
    }
  }

  Future<void> resetForLogout() async {
    _flowGeneration++;
    await _capture.clearTemporaryCopies();
    await _resumeStore.clearAll();
    _access.reset();
    if (!isClosed) emit(const KycState());
  }

  Future<KycUploadIntent?> _newIntent(
    String attemptId,
    KycCapturedDocument document,
    KycDocumentType type,
  ) async {
    final created = await _repository.createUploadIntent(
      attemptId: attemptId,
      document: document,
      idempotencyKey: _idempotencyKey(),
    );
    final intent = created.fold<KycUploadIntent?>((failure) {
      _emitFailure(failure);
      return null;
    }, (value) => value);
    if (intent != null) {
      emit(state.copyWith(intents: {...state.intents, type: intent}));
    }
    return intent;
  }

  Future<bool> _waitForTechnicalAcceptance({
    required KycDocumentType type,
    required int generation,
  }) async {
    emit(state.copyWith(stage: KycUiStage.analysing, clearError: true));
    for (var poll = 0; poll < _technicalValidationPollLimit; poll++) {
      if (!_isCurrentFlow(generation)) return false;
      final result = await _repository.getStatus();
      if (!_isCurrentFlow(generation)) return false;
      final failure = result.fold<Failure?>((value) => value, (_) => null);
      if (failure != null) {
        _emitFailure(failure);
        return false;
      }
      final snapshot = result.getOrElse(() => state.snapshot);
      emit(state.copyWith(
        snapshot: snapshot,
        stage: KycUiStage.analysing,
        clearError: true,
      ));
      switch (snapshot.documentState(type)) {
        case KycDocumentState.accepted:
          return true;
        case KycDocumentState.rejected:
          await _discardTechnicallyRejectedDocument(type);
          _emitCode('technical_rejected');
          return false;
        case KycDocumentState.missing:
        case KycDocumentState.intentIssued:
        case KycDocumentState.uploaded:
        case KycDocumentState.processing:
          await Future<void>.delayed(_technicalValidationPollInterval);
      }
    }
    _emitCode('technical_processing_timeout');
    return false;
  }

  Future<void> _discardTechnicallyRejectedDocument(KycDocumentType type) async {
    final document = state.documents[type];
    if (document != null) await _capture.deleteCopy(document);
    final attemptId = state.session?.attemptId ?? state.snapshot.attemptId;
    if (attemptId != null) {
      await _resumeStore.remove(attemptId: attemptId, type: type);
    }
    if (isClosed) return;
    emit(state.copyWith(
      documents: {...state.documents}..remove(type),
      intents: {...state.intents}..remove(type),
      uploadedTypes: {...state.uploadedTypes}..remove(type),
      acceptedUploadIds: {...state.acceptedUploadIds}..remove(type),
      uploadProgress: {...state.uploadProgress}..remove(type),
      stage: KycUiStage.idle,
      clearError: true,
    ));
  }

  bool _isCurrentFlow(int generation) =>
      !isClosed && generation == _flowGeneration;

  void _emitFailure(Failure failure) =>
      _emitCode(failure.code ?? failure.message);

  void _emitCode(String code) {
    if (isClosed) return;
    emit(state.copyWith(stage: KycUiStage.failure, errorCode: code));
  }

  String _idempotencyKey() {
    final bytes = List<int>.generate(24, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  @override
  Future<void> close() async {
    await _realtimeSubscription?.cancel();
    return super.close();
  }
}
