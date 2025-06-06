// lib/presentation/blocs/verification/verification_event.dart

import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class VerificationEvent extends Equatable {
  const VerificationEvent();

  @override
  List<Object?> get props => [];
}

/// Événement pour charger le statut de vérification
class LoadVerificationStatus extends VerificationEvent {}

/// Événement pour soumettre un document d'identité
class SubmitIdentityDocument extends VerificationEvent {
  final File document;

  const SubmitIdentityDocument({required this.document});

  @override
  List<Object> get props => [document];
}

/// Événement pour soumettre un document médical
class SubmitMedicalDocument extends VerificationEvent {
  final File document;

  const SubmitMedicalDocument({required this.document});

  @override
  List<Object> get props => [document];
}

/// Événement pour soumettre le selfie avec code
class SubmitSelfieWithCode extends VerificationEvent {
  final File selfie;
  final String code;

  const SubmitSelfieWithCode({
    required this.selfie,
    required this.code,
  });

  @override
  List<Object> get props => [selfie, code];
}

/// Événement pour finaliser la soumission de vérification
class FinalizeVerificationSubmission extends VerificationEvent {}

/// Événement pour réinitialiser le processus
class ResetVerification extends VerificationEvent {}

/// Événement pour générer un nouveau code de vérification
class GenerateVerificationCode extends VerificationEvent {}