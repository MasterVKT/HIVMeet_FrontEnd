// lib/presentation/pages/splash/splash_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_bloc_simple.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_event.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_state.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';

const bool _enableVerboseLogs = false;

void _debugLog(Object? message) {
  if (_enableVerboseLogs) {
    debugPrint(message?.toString());
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animationController.forward();

    // Declencher la verification de l'authentification
    context.read<AuthBlocSimple>().add(AppStarted());

    // Navigation forcee apres 10 secondes SEULEMENT si aucun etat n'a ete recu
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        final currentState = context.read<AuthBlocSimple>().state;
        // Seulement forcer la navigation si on est toujours en etat initial
        if (currentState is AuthInitial || currentState is AuthLoading) {
          _debugLog(
              'TIMEOUT: Navigation forcee vers login apres 10s - etat: $currentState');
          _debugLog(
              'WARNING: L\'authentification a pris trop de temps, verifiez le backend');
          context.go('/login');
        } else {
          _debugLog('Navigation forcee annulee - etat recu: $currentState');
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _debugLog('DEBUG SplashPage: build() appele');
    return BlocListener<AuthBlocSimple, AuthState>(
      listener: (context, state) {
        _debugLog('DEBUG SplashPage: BlocListener state change: $state');

        // Ne naviguer qu'une seule fois
        if (_hasNavigated) {
          _debugLog('DEBUG SplashPage: Deja navigue, navigation ignoree');
          return;
        }

        // Ne naviguer que si on est toujours sur la SplashPage
        if (!mounted) {
          _debugLog('DEBUG SplashPage: Widget non monte, navigation ignoree');
          return;
        }

        if (state is Authenticated) {
          _debugLog('DEBUG SplashPage: Authenticated detecte, navigation...');
          _hasNavigated = true;
          context.go('/discovery');
          _debugLog('DEBUG SplashPage: Navigation vers /discovery effectuee');
        } else if (state is Unauthenticated) {
          _debugLog('DEBUG SplashPage: Unauthenticated detecte');
          _hasNavigated = true;
          context.go('/login');
          _debugLog('DEBUG SplashPage: Navigation vers /login effectuee');
        } else if (state is AuthError) {
          _debugLog('DEBUG SplashPage: AuthError detecte: ${state.message}');
          _hasNavigated = true;
          context.go('/login');
          _debugLog('DEBUG SplashPage: Navigation vers /login apres erreur');
        } else if (state is AuthNetworkError) {
          _debugLog(
              'DEBUG SplashPage: AuthNetworkError detecte: ${state.message}');
          // Rester sur splash avec message d'erreur visible - pas de navigation forcee
        }
      },
      child: BlocBuilder<AuthBlocSimple, AuthState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo HIVMeet
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryPurple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nom de l'application
                    Text(
                      'HIVMeet',
                      style: GoogleFonts.openSans(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tagline
                    Text(
                      'Connecter - Soutenir - Grandir',
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        color: AppColors.slate,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Gestion d'etat avec UI appropriee
                    if (state is AuthLoading)
                      Column(
                        children: [
                          const HIVLoader(),
                          const SizedBox(height: 16),
                          Text(
                            'Verification de la connexion...',
                            style: GoogleFonts.openSans(
                              fontSize: 14,
                              color: AppColors.slate,
                            ),
                          ),
                        ],
                      )
                    else if (state is AuthNetworkError)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.wifi_off,
                              size: 32,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.openSans(
                                fontSize: 12,
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                context
                                    .read<AuthBlocSimple>()
                                    .add(AppStarted());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              child: Text('Reessayer',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: () {
                                context.go('/login');
                              },
                              child: Text(
                                'Continuer sans connexion',
                                style: TextStyle(
                                    color: AppColors.slate, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (state is AuthError)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 32,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Erreur d\'authentification',
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.openSans(
                                fontSize: 12,
                                color: AppColors.slate,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                context.go('/login');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              child: Text('Aller a la connexion',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      )
                    else
                      // Etat par defaut - show loader
                      Column(
                        children: [
                          const HIVLoader(),
                          const SizedBox(height: 16),
                          Text(
                            'Initialisation...',
                            style: GoogleFonts.openSans(
                              fontSize: 14,
                              color: AppColors.slate,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 48),

                    // Version de l'app (en bas)
                    Text(
                      'Version 1.0.0',
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        color: AppColors.slate.withOpacityValues(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
