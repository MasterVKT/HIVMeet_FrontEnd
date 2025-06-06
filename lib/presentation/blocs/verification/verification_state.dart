// lib/presentation/blocs/verification/verification_state.dart

import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/profile.dart';

abstract class VerificationState extends Equatable {
  const VerificationState();

  @override
  List<Object?> get props => [];
}

/// État initial
class VerificationInitial extends VerificationState {}

/// État de chargement
class VerificationLoading extends VerificationState {}

/// État principal avec les données de vérification
class VerificationLoaded extends VerificationState {
  final VerificationStatus status;
  final String? verificationCode;
  final DocumentUploadStatus identityDocumentStatus;
  final DocumentUploadStatus medicalDocumentStatus;
  final DocumentUploadStatus selfieStatus;
  final String? currentStep;
  final double progress;

  const VerificationLoaded({
    required this.status,
    this.verificationCode,
    required this.identityDocumentStatus,
    required this.medicalDocumentStatus,
    required this.selfieStatus,
    this.currentStep,
    required this.progress,
  });

  VerificationLoaded copyWith({
    VerificationStatus? status,
    String? verificationCode,
    DocumentUploadStatus? identityDocumentStatus,
    DocumentUploadStatus? medicalDocumentStatus,
    DocumentUploadStatus? selfieStatus,
    String? currentStep,
    double? progress,
  }) {
    return VerificationLoaded(
      status: status ?? this.status,
      verificationCode: verificationCode ?? this.verificationCode,
      identityDocumentStatus: identityDocumentStatus ?? this.identityDocumentStatus,
      medicalDocumentStatus: medicalDocumentStatus ?? this.medicalDocumentStatus,
      selfieStatus: selfieStatus ?? this.selfieStatus,
      currentStep: currentStep ?? this.currentStep,
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object?> get props => [
        status,
        verificationCode,
        identityDocumentStatus,
        medicalDocumentStatus,
        selfieStatus,
        currentStep,
        progress,
      ];
}

/// État pendant l'upload d'un document
class DocumentUploading extends VerificationState {
  final VerificationLoaded previousState;
  final String documentType;
  final double uploadProgress;

  const DocumentUploading({
    required this.previousState,
    required this.documentType,
    required this.uploadProgress,
  });

  @override
  List<Object> get props => [previousState, documentType, uploadProgress];
}

/// État d'erreur
class VerificationError extends VerificationState {
  final String message;
  final VerificationLoaded? previousState;

  const VerificationError({
    required this.message,
    this.previousState,
  });

  @override
  List<Object?> get props => [message, previousState];
}

/// État de soumission finale
class VerificationSubmitting extends VerificationState {
  final VerificationLoaded previousState;

  const VerificationSubmitting({required this.previousState});

  @override
  List<Object> get props => [previousState];
}

/// État de succès après soumission
class VerificationSubmitted extends VerificationState {
  final String message;

  const VerificationSubmitted({required this.message});

  @override
  List<Object> get props => [message];
}

/// Statut d'upload d'un document
class DocumentUploadStatus extends Equatable {
  final bool isUploaded;
  final bool isVerified;
  final String? errorMessage;
  final String? documentUrl;

  const DocumentUploadStatus({
    required this.isUploaded,
    required this.isVerified,
    this.errorMessage,
    this.documentUrl,
  });

  factory DocumentUploadStatus.initial() {
    return const DocumentUploadStatus(
      isUploaded: false,
      isVerified: false,
    );
  }

  DocumentUploadStatus copyWith({
    bool? isUploaded,
    bool? isVerified,
    String? errorMessage,
    String? documentUrl,
  }) {
    return DocumentUploadStatus(
      isUploaded: isUploaded ?? this.isUploaded,
      isVerified: isVerified ?? this.isVerified,
      errorMessage: errorMessage ?? this.errorMessage,
      documentUrl: documentUrl ?? this.documentUrl,
    );
  }

  @override
  List<Object?> get props => [isUploaded, isVerified, errorMessage, documentUrl];
}