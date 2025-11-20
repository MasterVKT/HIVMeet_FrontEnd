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

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animationController.forward();

    // Déclencher la vérification de l'authentification
    context.read<AuthBlocSimple>().add(AppStarted());

    // Navigation forcée après 5 secondes SEULEMENT si aucun état n'a été reçu
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        final currentState = context.read<AuthBlocSimple>().state;
        // Seulement forcer la navigation si on est toujours en état initial
        if (currentState is AuthInitial || currentState is AuthLoading) {
          print(
              'Navigation forcée vers login après timeout - état: $currentState');
          context.go('/login');
        } else {
          print('Navigation forcée annulée - état reçu: $currentState');
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
    return BlocListener<AuthBlocSimple, AuthState>(
      listener: (context, state) {
        print('🔄 DEBUG SplashPage: BlocListener state change: $state');
        if (state is Authenticated) {
          print('✅ DEBUG SplashPage: Authenticated détecté, navigation...');
          context.go('/discovery');
          print('✅ DEBUG SplashPage: Navigation vers /discovery effectuée');
        } else if (state is Unauthenticated) {
          print('❌ DEBUG SplashPage: Unauthenticated détecté');
          context.go('/login');
          print('✅ DEBUG SplashPage: Navigation vers /login effectuée');
        } else if (state is AuthError) {
          print('❌ DEBUG SplashPage: AuthError détecté: ${state.message}');
          context.go('/login');
          print('✅ DEBUG SplashPage: Navigation vers /login après erreur');
        } else if (state is AuthNetworkError) {
          print(
              '🌐 DEBUG SplashPage: AuthNetworkError détecté: ${state.message}');
          // Rester sur splash avec message d'erreur visible - pas de navigation forcée
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
                      'Connecter • Soutenir • Grandir',
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        color: AppColors.slate,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Gestion d'état avec UI appropriée
                    if (state is AuthLoading)
                      Column(
                        children: [
                          const HIVLoader(),
                          const SizedBox(height: 16),
                          Text(
                            'Vérification de la connexion...',
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
                              child: Text('Réessayer',
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
                              child: Text('Aller à la connexion',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      )
                    else
                      // État par défaut - show loader
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
