// lib/presentation/blocs/verification/verification_bloc.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';
import 'verification_event.dart';
import 'verification_state.dart';

@injectable
class VerificationBloc extends Bloc<VerificationEvent, VerificationState> {
  final ProfileRepository _profileRepository;
  
  String? _currentVerificationCode;
  DocumentUploadStatus _identityStatus = DocumentUploadStatus.initial();
  DocumentUploadStatus _medicalStatus = DocumentUploadStatus.initial();
  DocumentUploadStatus _selfieStatus = DocumentUploadStatus.initial();

  VerificationBloc({
    required ProfileRepository profileRepository,
  })  : _profileRepository = profileRepository,
        super(VerificationInitial()) {
    on<LoadVerificationStatus>(_onLoadVerificationStatus);
    on<SubmitIdentityDocument>(_onSubmitIdentityDocument);
    on<SubmitMedicalDocument>(_onSubmitMedicalDocument);
    on<SubmitSelfieWithCode>(_onSubmitSelfieWithCode);
    on<FinalizeVerificationSubmission>(_onFinalizeVerificationSubmission);
    on<ResetVerification>(_onResetVerification);
    on<GenerateVerificationCode>(_onGenerateVerificationCode);
  }

  Future<void> _onLoadVerificationStatus(
    LoadVerificationStatus event,
    Emitter<VerificationState> emit,
  ) async {
    emit(VerificationLoading());
    
    final result = await _profileRepository.getVerificationStatus();
    
    result.fold(
      (failure) => emit(VerificationError(message: failure.message)),
      (status) {
        // Generate verification code if needed
        if (status.status == 'pending_selfie' || status.status == 'not_started') {
          _currentVerificationCode = _generateCode();
        }
        
        // Update document statuses based on backend data
        _updateDocumentStatuses(status);
        
        emit(VerificationLoaded(
          status: status,
          verificationCode: _currentVerificationCode,
          identityDocumentStatus: _identityStatus,
          medicalDocumentStatus: _medicalStatus,
          selfieStatus: _selfieStatus,
          currentStep: _getCurrentStep(status),
          progress: _calculateProgress(),
        ));
      },
    );
  }

  Future<void> _onSubmitIdentityDocument(
    SubmitIdentityDocument event,
    Emitter<VerificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is VerificationLoaded) {
      emit(DocumentUploading(
        previousState: currentState,
        documentType: 'identity_document',
        uploadProgress: 0.0,
      ));
      
      // Simulate upload progress
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        emit(DocumentUploading(
          previousState: currentState,
          documentType: 'identity_document',
          uploadProgress: i * 0.1,
        ));
      }
      
      final result = await _profileRepository.uploadProfilePhoto(
        photo: event.document,
        isMain: false,
        isPrivate: true,
      );
      
      result.fold(
        (failure) {
          _identityStatus = _identityStatus.copyWith(
            errorMessage: failure.message,
          );
          emit(VerificationError(
            message: failure.message,
            previousState: currentState,
          ));
        },
        (photoUrl) {
          _identityStatus = _identityStatus.copyWith(
            isUploaded: true,
            documentUrl: photoUrl,
            errorMessage: null,
          );
          
          emit(currentState.copyWith(
            identityDocumentStatus: _identityStatus,
            currentStep: _getCurrentStepAfterUpload(),
            progress: _calculateProgress(),
          ));
        },
      );
    }
  }

  Future<void> _onSubmitMedicalDocument(
    SubmitMedicalDocument event,
    Emitter<VerificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is VerificationLoaded) {
      emit(DocumentUploading(
        previousState: currentState,
        documentType: 'medical_document',
        uploadProgress: 0.0,
      ));
      
      // Simulate upload progress
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        emit(DocumentUploading(
          previousState: currentState,
          documentType: 'medical_document',
          uploadProgress: i * 0.1,
        ));
      }
      
      final result = await _profileRepository.uploadProfilePhoto(
        photo: event.document,
        isMain: false,
        isPrivate: true,
      );
      
      result.fold(
        (failure) {
          _medicalStatus = _medicalStatus.copyWith(
            errorMessage: failure.message,
          );
          emit(VerificationError(
            message: failure.message,
            previousState: currentState,
          ));
        },
        (photoUrl) {
          _medicalStatus = _medicalStatus.copyWith(
            isUploaded: true,
            documentUrl: photoUrl,
            errorMessage: null,
          );
          
          emit(currentState.copyWith(
            medicalDocumentStatus: _medicalStatus,
            currentStep: _getCurrentStepAfterUpload(),
            progress: _calculateProgress(),
          ));
        },
      );
    }
  }

  Future<void> _onSubmitSelfieWithCode(
    SubmitSelfieWithCode event,
    Emitter<VerificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is VerificationLoaded) {
      emit(DocumentUploading(
        previousState: currentState,
        documentType: 'selfie_with_code',
        uploadProgress: 0.0,
      ));
      
      // Simulate upload progress
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        emit(DocumentUploading(
          previousState: currentState,
          documentType: 'selfie_with_code',
          uploadProgress: i * 0.1,
        ));
      }
      
      final result = await _profileRepository.uploadProfilePhoto(
        photo: event.selfie,
        isMain: false,
        isPrivate: true,
      );
      
      result.fold(
        (failure) {
          _selfieStatus = _selfieStatus.copyWith(
            errorMessage: failure.message,
          );
          emit(VerificationError(
            message: failure.message,
            previousState: currentState,
          ));
        },
        (photoUrl) {
          _selfieStatus = _selfieStatus.copyWith(
            isUploaded: true,
            documentUrl: photoUrl,
            errorMessage: null,
          );
          
          emit(currentState.copyWith(
            selfieStatus: _selfieStatus,
            currentStep: 'ready_to_submit',
            progress: _calculateProgress(),
          ));
        },
      );
    }
  }

  Future<void> _onFinalizeVerificationSubmission(
    FinalizeVerificationSubmission event,
    Emitter<VerificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is VerificationLoaded) {
      emit(VerificationSubmitting(previousState: currentState));
      
      // Simulate API call - in real implementation, this would submit all documents
      await Future.delayed(const Duration(seconds: 2));
      
      // Here you would normally call the API to submit verification documents
      // For now, we'll simulate success
      
      emit(const VerificationSubmitted(
        message: 'Vos documents ont été soumis avec succès. La vérification peut prendre 24 à 48 heures.',
      ));
    }
  }

  Future<void> _onResetVerification(
    ResetVerification event,
    Emitter<VerificationState> emit,
  ) async {
    _identityStatus = DocumentUploadStatus.initial();
    _medicalStatus = DocumentUploadStatus.initial();
    _selfieStatus = DocumentUploadStatus.initial();
    _currentVerificationCode = null;
    
    add(LoadVerificationStatus());
  }

  Future<void> _onGenerateVerificationCode(
    GenerateVerificationCode event,
    Emitter<VerificationState> emit,
  ) async {
    _currentVerificationCode = _generateCode();
    
    final currentState = state;
    if (currentState is VerificationLoaded) {
      emit(currentState.copyWith(
        verificationCode: _currentVerificationCode,
      ));
    }
  }

  String _generateCode() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  void _updateDocumentStatuses(VerificationStatus status) {
    for (final doc in status.documents.values) {
      switch (doc.type) {
        case 'identity_document':
          _identityStatus = DocumentUploadStatus(
            isUploaded: doc.status == 'uploaded' || doc.status == 'approved',
            isVerified: doc.status == 'approved',
          );
          break;
        case 'medical_document':
          _medicalStatus = DocumentUploadStatus(
            isUploaded: doc.status == 'uploaded' || doc.status == 'approved',
            isVerified: doc.status == 'approved',
          );
          break;
        case 'selfie_with_code':
          _selfieStatus = DocumentUploadStatus(
            isUploaded: doc.status == 'uploaded' || doc.status == 'approved',
            isVerified: doc.status == 'approved',
          );
          break;
      }
    }
  }

  String _getCurrentStep(VerificationStatus status) {
    if (!_identityStatus.isUploaded) return 'identity_document';
    if (!_medicalStatus.isUploaded) return 'medical_document';
    if (!_selfieStatus.isUploaded) return 'selfie_with_code';
    if (status.status == 'pending_review') return 'pending_review';
    if (status.status == 'verified') return 'verified';
    return 'ready_to_submit';
  }

  String _getCurrentStepAfterUpload() {
    if (!_identityStatus.isUploaded) return 'identity_document';
    if (!_medicalStatus.isUploaded) return 'medical_document';
    if (!_selfieStatus.isUploaded) return 'selfie_with_code';
    return 'ready_to_submit';
  }

  double _calculateProgress() {
    double progress = 0.0;
    if (_identityStatus.isUploaded) progress += 0.33;
    if (_medicalStatus.isUploaded) progress += 0.33;
    if (_selfieStatus.isUploaded) progress += 0.34;
    return progress;
  }
}