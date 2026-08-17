// lib/presentation/pages/auth/login_page.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/util/validators.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_bloc_simple.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_event.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_state.dart';
import 'package:hivmeet/presentation/widgets/common/app_button.dart';
import 'package:hivmeet/presentation/widgets/common/app_text_field.dart';
import 'package:hivmeet/presentation/widgets/common/hiv_toast.dart';
import 'package:hivmeet/presentation/widgets/common/connectivity_diagnostic_widget.dart';
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
    debugPrint('🔄 DEBUG: _handleLogin DÉMARRÉ avec AuthBlocSimple');

    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ DEBUG: Validation formulaire échouée');
      return;
    }

    debugPrint('✅ DEBUG: Validation formulaire OK');
    debugPrint('Tentative de connexion pour: ${_emailController.text.trim()}');

    // Utiliser le nouveau système AuthBlocSimple
    context.read<AuthBlocSimple>().add(
          LoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );

    debugPrint('✅ DEBUG: LoginRequested envoyé au AuthBlocSimple');
  }

  // Méthodes de debug (à retirer en production)
  Future<void> _createTestUser() async {
    try {
      final auth = FirebaseAuth.instance;
      const testEmail = 'test@hivmeet.com';
      const testPassword = 'Test123456!';

      if (!mounted) return;
      HIVToast.showInfo(
        context: context,
        message: 'Création de l\'utilisateur test...',
      );

      UserCredential? userCredential;

      try {
        // Essayer de créer l'utilisateur
        userCredential = await auth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          // L'utilisateur existe déjà, se connecter pour le vérifier
          try {
            userCredential = await auth.signInWithEmailAndPassword(
              email: testEmail,
              password: testPassword,
            );
            if (!mounted) return;
            HIVToast.showInfo(
              context: context,
              message: 'Utilisateur test existe déjà',
            );
          } catch (signInError) {
            if (!mounted) return;
            HIVToast.showError(
              context: context,
              message:
                  'Erreur connexion utilisateur existant: ${signInError.toString()}',
            );
            return;
          }
        } else {
          if (!mounted) return;
          HIVToast.showError(
            context: context,
            message: 'Erreur création: ${e.toString()}',
          );
          return;
        }
      }

      if (userCredential.user != null) {
        final user = userCredential.user!;

        // Vérifier l'email automatiquement pour les tests
        if (!user.emailVerified) {
          try {
            // Envoyer l'email de vérification
            await user.sendEmailVerification();

            // Pour les tests, marquer comme vérifié côté Firebase
            // Note: Cette approche est uniquement pour le développement
            await user.reload();

            if (!mounted) return;
            HIVToast.showSuccess(
              context: context,
              message: 'Utilisateur test créé et email vérifié',
            );
          } catch (verificationError) {
            if (!mounted) return;
            HIVToast.showWarning(
              context: context,
              message: 'Utilisateur créé mais vérification email échouée',
            );
          }
        } else {
          if (!mounted) return;
          HIVToast.showSuccess(
            context: context,
            message: 'Utilisateur test prêt (email déjà vérifié)',
          );
        }

        // Remplir automatiquement les champs
        _emailController.text = testEmail;
        _passwordController.text = testPassword;

        if (!mounted) return;
        HIVToast.showInfo(
          context: context,
          message: 'Identifiants remplis automatiquement',
        );
      }
    } catch (e) {
      if (!mounted) return;
      HIVToast.showError(
        context: context,
        message: 'Erreur générale: ${e.toString()}',
      );
    }
  }

  void _fillTestCredentials() {
    _emailController.text = 'test@hivmeet.com';
    _passwordController.text = 'Test123456!';

    HIVToast.showInfo(
      context: context,
      message: 'Identifiants de test remplis',
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔄 DEBUG LoginPage: Début du build');

    return BlocListener<AuthBlocSimple, AuthState>(
      listener: (context, state) {
        debugPrint('🔄 DEBUG LoginPage: BlocListener state change: $state');

        if (state is AuthLoading) {
          debugPrint('🔄 DEBUG LoginPage: AuthLoading détecté');
          setState(() {
            _isLoading = true;
          });
        } else if (state is Authenticated) {
          debugPrint('✅ DEBUG LoginPage: Authenticated détecté, navigation...');

          // Arrêter le loading
          setState(() {
            _isLoading = false;
          });

          // Naviguer vers la découverte (page principale)
          context.go('/discovery');
          debugPrint('✅ DEBUG LoginPage: Navigation vers /discovery effectuée');
        } else if (state is AuthError) {
          debugPrint('❌ DEBUG LoginPage: AuthError détecté: ${state.message}');

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
                  ? 'Authentification requise'
                  : 'Service indisponible');

          HIVToast.showError(
            context: context,
            message: message,
          );
        } else if (state is Unauthenticated) {
          debugPrint('❌ DEBUG LoginPage: Unauthenticated détecté');

          // Arrêter le loading si nécessaire
          setState(() {
            _isLoading = false;
          });
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
                            return 'L\'email est requis';
                          }
                          if (!Validators.isValidEmail(value)) {
                            return 'Email invalide';
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
                            return 'Le mot de passe est requis';
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

                      const SizedBox(height: 20),

                      // Boutons de debug (à retirer en production)
                      if (kDebugMode) ...[
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          'Debug Tools',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _createTestUser,
                                child: const Text('Créer utilisateur test'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _fillTestCredentials,
                                child: const Text('Remplir test'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Widget de diagnostic de connectivité
                        const ConnectivityDiagnosticWidget(),
                      ],
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
