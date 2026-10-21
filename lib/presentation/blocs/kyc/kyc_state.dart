import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/kyc.dart';

enum KycUiStage {
  idle,
  loading,
  capturing,
  uploading,
  analysing,
  submitted,
  failure,
}

class KycState extends Equatable {
  final KycSnapshot snapshot;
  final KycUiStage stage;
  final KycStartSession? session;
  final Map<KycDocumentType, KycCapturedDocument> documents;
  final Map<KycDocumentType, KycUploadIntent> intents;
  final Set<KycDocumentType> uploadedTypes;
  final Map<KycDocumentType, String> acceptedUploadIds;
  final Map<KycDocumentType, double> uploadProgress;
  final String? errorCode;

  const KycState({
    this.snapshot = const KycSnapshot.empty(),
    this.stage = KycUiStage.idle,
    this.session,
    this.documents = const {},
    this.intents = const {},
    this.uploadedTypes = const {},
    this.acceptedUploadIds = const {},
    this.uploadProgress = const {},
    this.errorCode,
  });

  bool get isBusy =>
      stage == KycUiStage.loading ||
      stage == KycUiStage.capturing ||
      stage == KycUiStage.uploading ||
      stage == KycUiStage.analysing;

  bool hasAcceptedDocument(KycDocumentType type) =>
      snapshot.documentState(type) == KycDocumentState.accepted &&
      acceptedUploadIds.containsKey(type);

  bool get canSubmit =>
      session != null &&
      KycDocumentType.values.every(
        (type) => documents.containsKey(type) || hasAcceptedDocument(type),
      ) &&
      !isBusy;

  KycState copyWith({
    KycSnapshot? snapshot,
    KycUiStage? stage,
    KycStartSession? session,
    bool clearSession = false,
    Map<KycDocumentType, KycCapturedDocument>? documents,
    Map<KycDocumentType, KycUploadIntent>? intents,
    Set<KycDocumentType>? uploadedTypes,
    Map<KycDocumentType, String>? acceptedUploadIds,
    Map<KycDocumentType, double>? uploadProgress,
    String? errorCode,
    bool clearError = false,
  }) {
    return KycState(
      snapshot: snapshot ?? this.snapshot,
      stage: stage ?? this.stage,
      session: clearSession ? null : (session ?? this.session),
      documents: documents ?? this.documents,
      intents: intents ?? this.intents,
      uploadedTypes: uploadedTypes ?? this.uploadedTypes,
      acceptedUploadIds: acceptedUploadIds ?? this.acceptedUploadIds,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
    );
  }

  @override
  List<Object?> get props => [
        snapshot,
        stage,
        session != null,
        documents.keys.toSet(),
        uploadedTypes,
        acceptedUploadIds.keys.toSet(),
        uploadProgress,
        errorCode,
        // Deliberately omit local paths, signed URLs and selfie challenge.
      ];
}
