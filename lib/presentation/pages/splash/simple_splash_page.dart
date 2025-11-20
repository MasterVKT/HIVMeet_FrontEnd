// lib/presentation/pages/splash/simple_splash_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';

class SimpleSplashPage extends StatefulWidget {
  const SimpleSplashPage({super.key});

  @override
  State<SimpleSplashPage> createState() => _SimpleSplashPageState();
}

class _SimpleSplashPageState extends State<SimpleSplashPage> {
  @override
  void initState() {
    super.initState();

    // Navigation forcée après 2 secondes
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        print('🔄 Navigation forcée vers login depuis SimpleSplashPage');
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryWhite,
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

              // Indicateur de chargement
              const CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
              ),
              const SizedBox(height: 16),
              Text(
                'Chargement...',
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: AppColors.slate,
                ),
              ),

              const SizedBox(height: 48),

              // Version de l'app
              Text(
                'Version 1.0.0',
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: AppColors.slate.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
