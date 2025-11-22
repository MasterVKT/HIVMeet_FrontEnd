// lib/presentation/pages/profile/profile_detail_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/presentation/widgets/navigation/app_scaffold.dart';

class ProfileDetailPage extends StatelessWidget {
  const ProfileDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 3, // Profile tab
      appBar: AppBar(
        backgroundColor: AppColors.primaryWhite,
        elevation: 0,
        title: Text(
          'Mon Profil',
          style: GoogleFonts.openSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryPurple,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: AppColors.primaryPurple),
            onPressed: () {
              context.go('/settings');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              size: 80,
              color: AppColors.primaryPurple.withOpacityValues(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Mon Profil',
              style: GoogleFonts.openSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cette page sera implémentée prochainement',
              style: GoogleFonts.openSans(
                fontSize: 16,
                color: AppColors.slate,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.go('/settings');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Paramètres'),
            ),
          ],
        ),
      ),
    );
  }
}
