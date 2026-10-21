// lib/presentation/blocs/register/register_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/util/validators.dart';
import 'package:hivmeet/core/services/authentication_service.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'register_event.dart';
import 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthenticationService _authService;

  RegisterBloc({
    required AuthenticationService authService,
  })  : _authService = authService,
        super(const RegisterState()) {
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<EmailChanged>(_onEmailChanged);
    on<PasswordChanged>(_onPasswordChanged);
    on<ConfirmPasswordChanged>(_onConfirmPasswordChanged);
    on<ResendVerificationEmailRequested>(_onResendVerificationEmail);
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    // Validation finale
    final Map<String, String> errors = {};

    if (!Validators.isValidEmail(event.email)) {
      errors['email'] = 'auth.validation.email_invalid';
    }

    if (!Validators.isValidPassword(event.password)) {
      errors['password'] = 'auth.validation.password_requirements';
    }

    if (event.password != event.confirmPassword) {
      errors['confirmPassword'] = 'auth.validation.password_mismatch';
    }

    if (!Validators.isValidDisplayName(event.displayName)) {
      errors['displayName'] = 'auth.validation.display_name_invalid';
    }

    if (!Validators.isAdult(event.birthDate)) {
      errors['birthDate'] = 'auth.validation.age_requirement';
    }

    // Le numéro est optionnel et peut être saisi avec espaces/tirets.
    final String? phone =
        event.phoneNumber?.replaceAll(RegExp(r'[\s\-.()]'), '');
    if (phone != null &&
        phone.isNotEmpty &&
        !Validators.isValidPhoneNumber(phone)) {
      errors['phoneNumber'] = 'auth.validation.phone_invalid';
    }

    if (!event.acceptTerms) {
      errors['terms'] = 'auth.validation.terms_required';
    }

    if (errors.isNotEmpty) {
      // Message précis (premier champ en erreur) plutôt qu'un message générique.
      emit(state.copyWith(
        fieldErrors: errors,
        errorMessage: errors.values.first,
      ));
      // Remise à zéro : sans cela, un même message ré-émis donne un état égal
      // (Equatable) et le listener UI ne se déclenche plus aux clics suivants.
      emit(state.copyWith(errorMessage: null));
      return;
    }

    emit(state.copyWith(
        isSubmitting: true, errorMessage: null, fieldErrors: const {}));

    final result = await _authService.signUpWithEmailAndPassword(
      email: event.email,
      password: event.password,
      locale: LocalizationService.instance.currentLocale,
      displayName: event.displayName,
      birthDate: event.birthDate,
      phoneNumber: (phone == null || phone.isEmpty) ? null : phone,
      gender: event.gender,
    );

    if (result.success) {
      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        verificationEmailSent: result.verificationEmailSent,
      ));
    } else {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: result.error ?? 'auth.errors.registration_failed',
      ));
      emit(state.copyWith(isSubmitting: false, errorMessage: null));
    }
  }

  void _onEmailChanged(
    EmailChanged event,
    Emitter<RegisterState> emit,
  ) {
    final isValid = Validators.isValidEmail(event.email);
    emit(state.copyWith(
      email: event.email,
      emailValid: isValid,
      fieldErrors: Map.from(state.fieldErrors)..remove('email'),
    ));
  }

  void _onPasswordChanged(
    PasswordChanged event,
    Emitter<RegisterState> emit,
  ) {
    final isValid = Validators.isValidPassword(event.password);
    final strength = Validators.getPasswordStrength(event.password);

    // Revalider la confirmation si elle existe
    final confirmValid = state.confirmPassword.isEmpty ||
        event.password == state.confirmPassword;

    emit(state.copyWith(
      password: event.password,
      passwordValid: isValid,
      passwordStrength: strength,
      confirmPasswordValid: confirmValid,
      fieldErrors: Map.from(state.fieldErrors)..remove('password'),
    ));
  }

  void _onConfirmPasswordChanged(
    ConfirmPasswordChanged event,
    Emitter<RegisterState> emit,
  ) {
    final isValid = event.confirmPassword == event.password;
    emit(state.copyWith(
      confirmPassword: event.confirmPassword,
      confirmPasswordValid: isValid,
      fieldErrors: Map.from(state.fieldErrors)..remove('confirmPassword'),
    ));
  }

  Future<void> _onResendVerificationEmail(
    ResendVerificationEmailRequested event,
    Emitter<RegisterState> emit,
  ) async {
    final result = await _authService.resendEmailVerification(
      locale: LocalizationService.instance.currentLocale,
    );
    emit(state.copyWith(
      verificationEmailSent: result.verificationEmailSent,
      errorMessage: result.verificationEmailSent == true
          ? 'auth.email_verification.resend_sent'
          : 'auth.email_verification.resend_failed',
    ));
  }
}
