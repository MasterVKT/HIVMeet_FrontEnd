// lib/presentation/blocs/register/register_state.dart

import 'package:equatable/equatable.dart';

class RegisterState extends Equatable {
  final String email;
  final String password;
  final String confirmPassword;
  final String displayName;
  final DateTime? birthDate;
  final String? phoneNumber;
  final bool acceptTerms;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final Map<String, String> fieldErrors;
  final bool emailValid;
  final bool passwordValid;
  final bool confirmPasswordValid;
  final bool displayNameValid;
  final bool birthDateValid;
  final bool phoneNumberValid;
  final PasswordStrength passwordStrength;

  const RegisterState({
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.displayName = '',
    this.birthDate,
    this.phoneNumber,
    this.acceptTerms = false,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.fieldErrors = const {},
    this.emailValid = false,
    this.passwordValid = false,
    this.confirmPasswordValid = false,
    this.displayNameValid = false,
    this.birthDateValid = false,
    this.phoneNumberValid = true, // Optionnel, donc valide par défaut
    this.passwordStrength = PasswordStrength.weak,
  });

  bool get isFormValid =>
      emailValid &&
      passwordValid &&
      confirmPasswordValid &&
      displayNameValid &&
      birthDateValid &&
      phoneNumberValid &&
      acceptTerms;

  RegisterState copyWith({
    String? email,
    String? password,
    String? confirmPassword,
    String? displayName,
    DateTime? birthDate,
    String? phoneNumber,
    bool? acceptTerms,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    Map<String, String>? fieldErrors,
    bool? emailValid,
    bool? passwordValid,
    bool? confirmPasswordValid,
    bool? displayNameValid,
    bool? birthDateValid,
    bool? phoneNumberValid,
    PasswordStrength? passwordStrength,
  }) {
    return RegisterState(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      displayName: displayName ?? this.displayName,
      birthDate: birthDate ?? this.birthDate,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      acceptTerms: acceptTerms ?? this.acceptTerms,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      emailValid: emailValid ?? this.emailValid,
      passwordValid: passwordValid ?? this.passwordValid,
      confirmPasswordValid: confirmPasswordValid ?? this.confirmPasswordValid,
      displayNameValid: displayNameValid ?? this.displayNameValid,
      birthDateValid: birthDateValid ?? this.birthDateValid,
      phoneNumberValid: phoneNumberValid ?? this.phoneNumberValid,
      passwordStrength: passwordStrength ?? this.passwordStrength,
    );
  }

  @override
  List<Object?> get props => [
        email,
        password,
        confirmPassword,
        displayName,
        birthDate,
        phoneNumber,
        acceptTerms,
        isSubmitting,
        isSuccess,
        errorMessage,
        fieldErrors,
        emailValid,
        passwordValid,
        confirmPasswordValid,
        displayNameValid,
        birthDateValid,
        phoneNumberValid,
        passwordStrength,
      ];
}

enum PasswordStrength {
  weak,
  medium,
  strong,
}