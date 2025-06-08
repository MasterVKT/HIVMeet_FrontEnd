// lib/presentation/pages/settings/settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/settings/settings_bloc.dart';
import 'package:hivmeet/presentation/blocs/settings/settings_event.dart';
import 'package:hivmeet/presentation/blocs/settings/settings_state.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_bloc.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_event.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SettingsBloc>()..add(LoadSettings()),
      child: Scaffold(
        backgroundColor: AppColors.primaryWhite,
        appBar: AppBar(
          title: const Text('Paramètres'),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            if (state is SettingsLoaded) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSection(
                      context,
                      'Compte',
                      [
                        _buildTile(
                          icon: Icons.person_outline,
                          title: 'Modifier le profil',
                          onTap: () => context.push('/profile/edit'),
                        ),
                        _buildTile(
                          icon: Icons.lock_outline,
                          title: 'Changer le mot de passe',
                          onTap: () => context.push('/settings/change-password'),
                        ),
                        _buildTile(
                          icon: Icons.email_outlined,
                          title: 'Adresse email',
                          subtitle: state.email,
                          onTap: () => context.push('/settings/change-email'),
                        ),
                      ],
                    ),
                    
                    _buildSection(
                      context,
                      'Confidentialité',
                      [
                        _buildSwitchTile(
                          icon: Icons.visibility_outlined,
                          title: 'Profil visible',
                          subtitle: 'Apparaître dans les suggestions',
                          value: state.isProfileVisible,
                          onChanged: (value) {
                            context.read<SettingsBloc>().add(
                              UpdateProfileVisibility(isVisible: value),
                            );
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.location_on_outlined,
                          title: 'Partager ma localisation',
                          subtitle: 'Afficher la distance',
                          value: state.shareLocation,
                          onChanged: (value) {
                            context.read<SettingsBloc>().add(
                              UpdateLocationSharing(shareLocation: value),
                            );
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.access_time,
                          title: 'Afficher "En ligne"',
                          subtitle: 'Montrer mon statut de connexion',
                          value: state.showOnlineStatus,
                          onChanged: (value) {
                            context.read<SettingsBloc>().add(
                              UpdateOnlineStatusVisibility(showStatus: value),
                            );
                          },
                        ),
                        _buildTile(
                          icon: Icons.block,
                          title: 'Utilisateurs bloqués',
                          onTap: () => context.push('/settings/blocked-users'),
                        ),
                      ],
                    ),
                    
                    _buildSection(
                      context,
                      'Notifications',
                      [
                        _buildSwitchTile(
                          icon: Icons.favorite_outline,
                          title: 'Nouveaux matches',
                          value: state.notifyNewMatches,
                          onChanged: (value) {
                            context.read<SettingsBloc>().add(
                              UpdateNotificationSetting(
                                type: NotificationType.newMatches,
                                enabled: value,
                              ),
                            );
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.message_outlined,
                          title: 'Messages',
                          value: state.notifyMessages,
                          onChanged: (value) {
                            context.read<SettingsBloc>().add(
                              UpdateNotificationSetting(
                                type: NotificationType.messages,
                                enabled: value,
                              ),
                            );
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.star_outline,
                          title: 'Likes reçus',
                          subtitle: 'Premium uniquement',
                          value: state.notifyLikes,
                          onChanged: state.isPremium ? (value) {
                            context.read<SettingsBloc>().add(
                              UpdateNotificationSetting(
                                type: NotificationType.likes,
                                enabled: value,
                              ),
                            );
                          } : null,
                        ),
                        _buildSwitchTile(
                          icon: Icons.campaign_outlined,
                          title: 'Actualités HIVMeet',
                          value: state.notifyNews,
                          onChanged: (value) {
                            context.read<SettingsBloc>().add(
                              UpdateNotificationSetting(
                                type: NotificationType.news,
                                enabled: value,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    
                    _buildSection(
                      context,
                      'Langue et région',
                      [
                        _buildTile(
                          icon: Icons.language,
                          title: 'Langue',
                          subtitle: state.language == 'fr' ? 'Français' : 'English',
                          onTap: () => _showLanguageDialog(context),
                        ),
                        _buildTile(
                          icon: Icons.public,
                          title: 'Pays',
                          subtitle: state.country,
                          onTap: () => context.push('/settings/country'),
                        ),
                      ],
                    ),
                    
                    _buildSection(
                      context,
                      'Support',
                      [
                        _buildTile(
                          icon: Icons.help_outline,
                          title: 'Centre d\'aide',
                          onTap: () => context.push('/help'),
                        ),
                        _buildTile(
                          icon: Icons.bug_report_outlined,
                          title: 'Signaler un problème',
                          onTap: () => context.push('/settings/report-issue'),
                        ),
                        _buildTile(
                          icon: Icons.info_outline,
                          title: 'À propos',
                          onTap: () => context.push('/about'),
                        ),
                        _buildTile(
                          icon: Icons.description_outlined,
                          title: 'Conditions d\'utilisation',
                          onTap: () => context.push('/terms'),
                        ),
                        _buildTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Politique de confidentialité',
                          onTap: () => context.push('/privacy'),
                        ),
                      ],
                    ),
                    
                    _buildSection(
                      context,
                      'Compte',
                      [
                        _buildTile(
                          icon: Icons.logout,
                          title: 'Se déconnecter',
                          textColor: AppColors.error,
                          onTap: () => _showLogoutDialog(context),
                        ),
                        _buildTile(
                          icon: Icons.delete_forever,
                          title: 'Supprimer mon compte',
                          textColor: AppColors.error,
                          onTap: () => context.push('/settings/delete-account'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              );
            }
            
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.slate,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primaryPurple,
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Français'),
              value: 'fr',
              groupValue: 'fr', // TODO: Get current language
              onChanged: (value) {
                Navigator.pop(dialogContext);
                context.read<SettingsBloc>().add(
                  UpdateLanguage(language: value!),
                );
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: 'fr', // TODO: Get current language
              onChanged: (value) {
                Navigator.pop(dialogContext);
                context.read<SettingsBloc>().add(
                  UpdateLanguage(language: value!),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(SignOutRequested());
              context.go('/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}