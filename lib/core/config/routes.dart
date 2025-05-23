import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hivmeet/presentation/pages/auth/login_page.dart';
import 'package:hivmeet/presentation/pages/auth/register_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      // Autres routes à implémenter
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Erreur: Page ${state.uri.toString()} introuvable!'),
      ),
    ),
  );
}

// Placeholder pour le SplashScreen
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
