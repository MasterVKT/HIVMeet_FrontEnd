import 'package:equatable/equatable.dart';

enum KycStatus {
  notStarted,
  pendingId,
  pendingMedical,
  pendingSelfie,
  pendingReview,
  verified,
  rejected,
  expired;

  static KycStatus fromWire(String? value) {
    return switch (value) {
      'pending_id' => KycStatus.pendingId,
      'pending_medical' => KycStatus.pendingMedical,
      'pending_selfie' => KycStatus.pendingSelfie,
      'pending_review' => KycStatus.pendingReview,
      'verified' => KycStatus.verified,
      'rejected' => KycStatus.rejected,
      'expired' => KycStatus.expired,
      _ => KycStatus.notStarted,
    };
  }

  String get wire => switch (this) {
        KycStatus.notStarted => 'not_started',
        KycStatus.pendingId => 'pending_id',
        KycStatus.pendingMedical => 'pending_medical',
        KycStatus.pendingSelfie => 'pending_selfie',
        KycStatus.pendingReview => 'pending_review',
        KycStatus.verified => 'verified',
        KycStatus.rejected => 'rejected',
        KycStatus.expired => 'expired',
      };

  bool get isActive => this == KycStatus.verified;
}

enum KycDocumentType {
  identityDocument,
  medicalDocument,
  selfieWithCode;

  String get wire => switch (this) {
        KycDocumentType.identityDocument => 'identity_document',
        KycDocumentType.medicalDocument => 'medical_document',
        KycDocumentType.selfieWithCode => 'selfie_with_code',
      };

  bool get isSelfie => this == KycDocumentType.selfieWithCode;

  int get maxBytes => isSelfie ? 5 * 1024 * 1024 : 10 * 1024 * 1024;
}

enum KycDocumentState {
  missing,
  intentIssued,
  uploaded,
  processing,
  accepted,
  rejected;

  static KycDocumentState fromWire(String? value) => switch (value) {
        'intent_issued' => KycDocumentState.intentIssued,
        'uploaded' => KycDocumentState.uploaded,
        'processing' => KycDocumentState.processing,
        'accepted' => KycDocumentState.accepted,
        'rejected' => KycDocumentState.rejected,
        _ => KycDocumentState.missing,
      };
}

class KycDocumentStatus extends Equatable {
  final KycDocumentType type;
  final KycDocumentState state;

  const KycDocumentStatus({required this.type, required this.state});

  @override
  List<Object> get props => [type, state];
}

class KycSnapshot extends Equatable {
  final String? attemptId;
  final KycStatus status;
  final List<KycDocumentStatus> documents;
  final DateTime? expiresAt;
  final DateTime? submittedAt;
  final String? rejectionReasonCode;

  const KycSnapshot({
    required this.attemptId,
    required this.status,
    this.documents = const [],
    this.expiresAt,
    this.submittedAt,
    this.rejectionReasonCode,
  });

  const KycSnapshot.empty()
      : attemptId = null,
        status = KycStatus.notStarted,
        documents = const [],
        expiresAt = null,
        submittedAt = null,
        rejectionReasonCode = null;

  /// The server only grants KYC access for a verified, unexpired attempt.
  /// Missing expiry is deliberately restrictive: it must never unlock social
  /// data if a malformed or incomplete response reaches the client.
  bool get hasActiveAccess =>
      status.isActive &&
      expiresAt != null &&
      expiresAt!.isAfter(DateTime.now());

  KycDocumentState documentState(KycDocumentType type) {
    for (final document in documents) {
      if (document.type == type) return document.state;
    }
    return KycDocumentState.missing;
  }

  @override
  List<Object?> get props => [
        attemptId,
        status,
        documents,
        expiresAt,
        submittedAt,
        rejectionReasonCode,
      ];
}

class KycStartSession extends Equatable {
  final String attemptId;
  final KycStatus status;
  final String selfieChallengeCode;
  final DateTime selfieChallengeExpiresAt;

  const KycStartSession({
    required this.attemptId,
    required this.status,
    required this.selfieChallengeCode,
    required this.selfieChallengeExpiresAt,
  });

  @override
  // The one-time selfie challenge is intentionally excluded from diagnostics.
  List<Object> get props => [
        attemptId,
        status,
        selfieChallengeExpiresAt,
      ];
}

class KycCapturedDocument extends Equatable {
  final KycDocumentType type;
  final String localPath;
  final String mimeType;
  final int sizeBytes;
  final bool redactedCopy;

  const KycCapturedDocument({
    required this.type,
    required this.localPath,
    required this.mimeType,
    required this.sizeBytes,
    required this.redactedCopy,
  });

  @override
  // The private local path must never appear in Equatable diagnostics.
  List<Object> get props => [type, mimeType, sizeBytes, redactedCopy];
}

enum KycUploadTransport {
  directPut,
  backendMultipart;
}

class KycUploadIntent extends Equatable {
  final String uploadId;
  final Uri? uploadUri;
  final Map<String, String> requiredHeaders;
  final DateTime expiresAt;
  final KycUploadTransport transport;

  const KycUploadIntent({
    required this.uploadId,
    this.uploadUri,
    this.requiredHeaders = const {},
    required this.expiresAt,
    this.transport = KycUploadTransport.directPut,
  });

  bool get requiresCompletion => transport == KycUploadTransport.directPut;

  @override
  // Signed upload URLs and their headers must never appear in diagnostics.
  List<Object> get props => [expiresAt, transport];
}
