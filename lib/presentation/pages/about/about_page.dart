// lib/presentation/pages/about/about_page.dart

import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryWhite,
      appBar: AppBar(
        title: const Text('À propos'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.data?.version ?? '1.0.0';
          final buildNumber = snapshot.data?.buildNumber ?? '1';
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xl),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'HIVMeet',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Version $version ($buildNumber)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.slate,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notre mission',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'HIVMeet est une plateforme de rencontre inclusive et sécurisée dédiée aux personnes vivant avec le VIH. Notre objectif est de créer un espace où chacun peut trouver l\'amour, l\'amitié et le soutien sans jugement ni stigmatisation.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.security),
                        title: const Text('Confidentialité garantie'),
                        subtitle: const Text('Vos données sont protégées et cryptées'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.verified_user),
                        title: const Text('Profils vérifiés'),
                        subtitle: const Text('Option de vérification pour plus de sécurité'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.support),
                        title: const Text('Support communautaire'),
                        subtitle: const Text('Ressources et soutien disponibles'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  '© 2025 HIVMeet. Tous droits réservés.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.slate,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.email_outlined),
                      onPressed: () {
                        // TODO: Open email
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.language),
                      onPressed: () {
                        // TODO: Open website
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}