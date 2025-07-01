// lib/presentation/pages/auth/login_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/core/util/validators.dart';
import 'package:hivmeet/domain/usecases/auth/sign_in.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_bloc.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_event.dart';
import 'package:hivmeet/presentation/widgets/common/app_button.dart';
import 'package:hivmeet/presentation/widgets/common/app_text_field.dart';
import 'package:hivmeet/presentation/widgets/dialogs/hiv_dialogs.dart';

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final signIn = getIt<SignIn>();
      final result = await signIn(
        SignInParams(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
          });
          HIVToast.showError(
            context: context,
            message: failure.message,
          );
        },
        (user) {
          context.read<AuthBloc>().add(LoggedIn(userId: user.id));
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      HIVToast.showError(
        context: context,
        message: 'Une erreur est survenue',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              
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
              const SizedBox(height: AppSpacing.xl),
              
              // Titre
              Text(
                'Bon retour !',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              
              Text(
                'Connectez-vous pour continuer',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.slate,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              
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
                          return 'L\'email est requis';
                        }
                        if (!Validators.isValidEmail(value)) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    
                    AppTextField(
                      controller: _passwordController,
                      label: 'Mot de passe',
                      hintText: '••••••••',
                      obscureText: true,
                      prefixIcon: Icons.lock_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le mot de passe est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    // Remember me et mot de passe oublié
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
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
                            Text(
                              'Se souvenir de moi',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            context.push('/forgot-password');
                          },
                          child: Text(
                            'Mot de passe oublié ?',
                            style: TextStyle(
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Bouton de connexion
                    AppButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      text: 'Se connecter',
                      isLoading: _isLoading,
                      type: ButtonType.primary,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Text(
                            'OU',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                    const SizedBox(height: AppSpacing.lg),
                    
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
    );
  }
}
