import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryWhite,
      appBar: AppBar(
        title: Text(_tr('profile.about')),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.data?.version ?? '';
          final buildNumber = snapshot.data?.buildNumber ?? '';

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
                  _tr('about.app_name'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _tr(
                    'about.version',
                    params: {'version': version, 'build': buildNumber},
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.slate,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _MissionCard(),
                const SizedBox(height: AppSpacing.md),
                const _BenefitsCard(),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  _tr('about.copyright'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.slate,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: _tr('about.contact_support'),
                      icon: const Icon(Icons.email_outlined),
                      onPressed: () => _launch('mailto:support@hivmeet.com'),
                    ),
                    IconButton(
                      tooltip: _tr('about.open_website'),
                      icon: const Icon(Icons.language),
                      onPressed: () => _launch('https://hivmeet.com'),
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

class _MissionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tr('about.mission_title'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _tr('about.mission_body'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _BenefitTile(
            icon: Icons.security,
            title: _tr('about.privacy_title'),
            subtitle: _tr('about.privacy_subtitle'),
          ),
          const Divider(height: 1),
          _BenefitTile(
            icon: Icons.verified_user,
            title: _tr('about.verified_title'),
            subtitle: _tr('about.verified_subtitle'),
          ),
          const Divider(height: 1),
          _BenefitTile(
            icon: Icons.support,
            title: _tr('about.support_title'),
            subtitle: _tr('about.support_subtitle'),
          ),
        ],
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

Future<void> _launch(String value) async {
  final uri = Uri.parse(value);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

String _tr(String key, {Map<String, dynamic>? params}) =>
    LocalizationService.translate(key, params: params);
