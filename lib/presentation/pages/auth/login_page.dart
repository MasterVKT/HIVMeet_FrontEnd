// lib/presentation/pages/auth/login_page.dart

import 'package:hivmeet/core/utils/log_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/util/validators.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_bloc_simple.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_event.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_state.dart';
import 'package:hivmeet/presentation/widgets/common/app_button.dart';
import 'package:hivmeet/presentation/widgets/common/app_text_field.dart';
import 'package:hivmeet/presentation/widgets/common/hiv_toast.dart';
import 'package:hivmeet/core/services/localization_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    LogService.debug('🔄 DEBUG: _handleLogin DÉMARRÉ avec AuthBlocSimple');

    if (!_formKey.currentState!.validate()) {
      LogService.debug('❌ DEBUG: Validation formulaire échouée');
      return;
    }

    LogService.debug('✅ DEBUG: Validation formulaire OK');
    context.read<AuthBlocSimple>().add(
          LoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );

    LogService.debug('✅ DEBUG: LoginRequested envoyé au AuthBlocSimple');
  }

  @override
  Widget build(BuildContext context) {
    LogService.debug('🔄 DEBUG LoginPage: Début du build');

    return BlocListener<AuthBlocSimple, AuthState>(
      listener: (context, state) {
        LogService.debug(
          '🔄 DEBUG LoginPage: BlocListener state: ${state.runtimeType}',
        );

        if (state is AuthLoading) {
          LogService.debug('🔄 DEBUG LoginPage: AuthLoading détecté');
          setState(() {
            _isLoading = true;
          });
        } else if (state is Authenticated) {
          LogService.debug(
              '✅ DEBUG LoginPage: Authenticated détecté, navigation...');

          // Arrêter le loading
          setState(() {
            _isLoading = false;
          });

          // Naviguer vers la découverte (page principale)
          context.go('/discovery');
          LogService.debug(
              '✅ DEBUG LoginPage: Navigation vers /discovery effectuée');
        } else if (state is EmailVerificationPending) {
          setState(() {
            _isLoading = false;
          });
          context.go('/email-verification');
        } else if (state is AuthError) {
          LogService.debug('LoginPage received an authentication error');

          // Arrêter le loading
          setState(() {
            _isLoading = false;
          });

          // Afficher l'erreur
          final translated = LocalizationService.translate(
            state.message,
            params: const {},
          );

          final message = translated != state.message
              ? translated
              : (state.message.contains('401')
                  ? LocalizationService.translate('auth.errors.unauthorized')
                  : LocalizationService.translate(
                      'auth.errors.authentication_failed',
                    ));

          HIVToast.showError(
            context: context,
            message: message,
          );
        } else if (state is Unauthenticated) {
          LogService.debug('❌ DEBUG LoginPage: Unauthenticated détecté');

          // Arrêter le loading si nécessaire
          setState(() {
            _isLoading = false;
          });
        } else if (state is AuthNetworkError) {
          setState(() {
            _isLoading = false;
          });
          HIVToast.showError(
            context: context,
            message: LocalizationService.translate(
              state.message,
              params: {'attempt': state.retryCount, 'total': 3},
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Titre
                Text(
                  'Bon retour !',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  'Connectez-vous pour continuer',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.slate,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Formulaire
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _emailController,
                        label: 'Email',
                        hintText: 'votre@email.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return LocalizationService.translate(
                              'auth.validation.email_required',
                            );
                          }
                          if (!Validators.isValidEmail(value)) {
                            return LocalizationService.translate(
                              'auth.validation.email_invalid',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      AppTextField(
                        controller: _passwordController,
                        label: 'Mot de passe',
                        hintText: '••••••••',
                        obscureText: true,
                        prefixIcon: Icons.lock_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return LocalizationService.translate(
                              'auth.validation.password_required',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Remember me et mot de passe oublié
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                  activeColor: AppColors.primaryPurple,
                                ),
                                Flexible(
                                  child: Text(
                                    'Se souvenir de moi',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: TextButton(
                              onPressed: () {
                                context.push('/forgot-password');
                              },
                              child: Text(
                                'Mot de passe oublié ?',
                                style: TextStyle(
                                  color: AppColors.primaryPurple,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Bouton de connexion
                      AppButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        text: 'Se connecter',
                        isLoading: _isLoading,
                        type: ButtonType.primary,
                      ),
                      const SizedBox(height: 20),

                      // Séparateur
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppColors.silver,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OU',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.slate,
                                  ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppColors.silver,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Lien vers inscription
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Pas encore de compte ? ',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () {
                              context.go('/register');
                            },
                            child: Text(
                              'S\'inscrire',
                              style: TextStyle(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
