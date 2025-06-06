import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:hivmeet/presentation/pages/splash/splash_page.dart';
import 'package:hivmeet/presentation/pages/onboarding/onboarding_page.dart';
import 'package:hivmeet/presentation/pages/auth/login_page.dart';
import 'package:hivmeet/presentation/pages/auth/register_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String profileCreate = '/profile/create';
  static const String verification = '/verification';
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      // Autres routes à implémenter (home, profile, etc.)
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Erreur: Page ${state.uri.toString()} introuvable!'),
      ),
    ),
  );
}
