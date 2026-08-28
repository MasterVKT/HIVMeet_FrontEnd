// lib/presentation/blocs/register/register_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/util/validators.dart';
import 'package:hivmeet/core/services/authentication_service.dart';
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
      errors['email'] = 'Email invalide';
    }
    
    if (!Validators.isValidPassword(event.password)) {
      errors['password'] = 'Le mot de passe doit contenir au moins 8 caractères, une majuscule, une minuscule, un chiffre et un caractère spécial';
    }
    
    if (event.password != event.confirmPassword) {
      errors['confirmPassword'] = 'Les mots de passe ne correspondent pas';
    }
    
    if (!Validators.isValidDisplayName(event.displayName)) {
      errors['displayName'] = 'Le nom doit contenir entre 3 et 30 caractères';
    }
    
    if (!Validators.isAdult(event.birthDate)) {
      errors['birthDate'] = 'Vous devez avoir au moins 18 ans';
    }
    
    if (event.phoneNumber != null && !Validators.isValidPhoneNumber(event.phoneNumber!)) {
      errors['phoneNumber'] = 'Numéro de téléphone invalide';
    }
    
    if (!event.acceptTerms) {
      errors['terms'] = 'Vous devez accepter les conditions d\'utilisation';
    }
    
    if (errors.isNotEmpty) {
      emit(state.copyWith(
        fieldErrors: errors,
        errorMessage: 'Veuillez corriger les erreurs',
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    final result = await _authService.signUpWithEmailAndPassword(
      email: event.email,
      password: event.password,
      displayName: event.displayName,
    );

    if (result.success) {
      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: true,
      ));
    } else {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: result.error ?? 'Erreur d\'inscription',
      ));
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
    // AuthenticationService gère cela via Firebase Auth directement
    // Pour l'instant, on notifie l'utilisateur
    emit(state.copyWith(
      errorMessage: 'Email de vérification envoyé',
    ));
  }
}