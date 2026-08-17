import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_bloc.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_event.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_state.dart';
import 'package:hivmeet/presentation/widgets/common/hiv_toast.dart';
import 'package:hivmeet/presentation/widgets/common/optimized_image.dart';
import 'package:hivmeet/presentation/widgets/common/retry_panel.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';

class ProfileBlockedUsersPage extends StatelessWidget {
  const ProfileBlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(LoadBlockedUsers()),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            HIVToast.showError(context: context, message: _tr(state.message));
          }
          if (state is ProfileActionSuccess) {
            HIVToast.showSuccess(context: context, message: _tr(state.message));
          }
        },
        builder: (context, state) {
          final loaded = _loadedFrom(state);
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Scaffold(body: Center(child: HIVLoader()));
          }
          if (loaded == null) {
            return Scaffold(
              body: RetryPanel(
                messageKey: 'profile.blocked_load_error',
                onRetry: () =>
                    context.read<ProfileBloc>().add(LoadBlockedUsers()),
              ),
            );
          }
          final users = loaded.blockedUsers;
          return Scaffold(
            backgroundColor: AppColors.primaryWhite,
            appBar: AppBar(
              title: Text(_tr('profile.blocked_users')),
              backgroundColor: AppColors.primaryWhite,
            ),
            body: users.isEmpty
                ? Center(child: Text(_tr('profile.no_blocked_users')))
                : ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: ClipOval(
                            child: OptimizedImage(
                              imageUrl: user.profilePhotoUrl ?? '',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        title: Text(user.displayName),
                        trailing: TextButton(
                          onPressed: () => context.read<ProfileBloc>().add(
                                UnblockUser(userId: user.userId),
                              ),
                          child: Text(_tr('profile.unblock')),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

ProfileLoaded? _loadedFrom(ProfileState state) {
  if (state is ProfileLoaded) return state;
  if (state is ProfileActionSuccess) return state.loadedState;
  if (state is ProfileError) return state.loadedState;
  if (state is ProfileSectionLoading) return state.previousState;
  return null;
}

String _tr(String key) => LocalizationService.translate(key);
