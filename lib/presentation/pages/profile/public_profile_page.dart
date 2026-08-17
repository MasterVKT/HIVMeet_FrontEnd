import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/widgets/common/optimized_image.dart';
import 'package:hivmeet/presentation/widgets/common/retry_panel.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';

class PublicProfilePage extends StatefulWidget {
  final String userId;
  final Profile? initialProfile;

  const PublicProfilePage({
    super.key,
    required this.userId,
    this.initialProfile,
  });

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  late Future<Profile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<Profile> _loadProfile() async {
    if (widget.initialProfile != null) return widget.initialProfile!;
    final result = await getIt<ProfileRepository>().getProfile(widget.userId);
    return result.fold(
        (failure) => throw failure.message, (profile) => profile);
  }

  void _retry() {
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryWhite,
      appBar: AppBar(
        title: Text(_tr('profile.public_profile')),
        backgroundColor: AppColors.primaryWhite,
      ),
      body: FutureBuilder<Profile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: HIVLoader());
          }
          final profile = snapshot.data;
          if (snapshot.hasError || profile == null) {
            return RetryPanel(
              messageKey: 'profile.profile_not_found',
              onRetry: _retry,
            );
          }
          return _PublicProfileContent(profile: profile);
        },
      ),
    );
  }
}

class _PublicProfileContent extends StatelessWidget {
  final Profile profile;

  const _PublicProfileContent({required this.profile});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(AppSpacing.md),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: OptimizedImage(
              imageUrl: profile.mainPhotoUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _displayName(profile),
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 8),
        if (_location(profile).isNotEmpty)
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.slate),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _location(profile),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        if (profile.bio.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(profile.bio, style: Theme.of(context).textTheme.bodyLarge),
        ],
        if (profile.interests.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            _tr('profile.interests'),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.interests
                .map((interest) => Chip(label: Text(interest)))
                .toList(),
          ),
        ],
      ],
    );
  }

  String _displayName(Profile profile) {
    final age = profile.user?.age ?? profile.age;
    return age > 0 ? '${profile.displayName}, $age' : profile.displayName;
  }

  String _location(Profile profile) {
    if (profile.city.isNotEmpty && profile.country.isNotEmpty) {
      return '${profile.city}, ${profile.country}';
    }
    return profile.city.isNotEmpty ? profile.city : profile.country;
  }
}

String _tr(String key) => LocalizationService.translate(key);
