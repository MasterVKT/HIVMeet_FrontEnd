import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_bloc_simple.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hivmeet/presentation/pages/splash/splash_page.dart';
import 'package:hivmeet/presentation/pages/onboarding/onboarding_page.dart';
import 'package:hivmeet/presentation/pages/auth/login_page.dart';
import 'package:hivmeet/presentation/pages/auth/register_page.dart';
import 'package:hivmeet/presentation/pages/discovery/discovery_page.dart';
import 'package:hivmeet/presentation/pages/discovery/filters_page.dart';
import 'package:hivmeet/presentation/pages/profile/profile_detail_page.dart'
    as profile;
import 'package:hivmeet/presentation/pages/profile/profile_edit_page.dart';
import 'package:hivmeet/presentation/pages/profile/profile_photos_page.dart';
import 'package:hivmeet/presentation/pages/profile/profile_privacy_page.dart';
import 'package:hivmeet/presentation/pages/profile/profile_notifications_page.dart';
import 'package:hivmeet/presentation/pages/profile/profile_blocked_users_page.dart';
import 'package:hivmeet/presentation/pages/profile/profile_data_page.dart';
import 'package:hivmeet/presentation/pages/profile/public_profile_page.dart';
import 'package:hivmeet/presentation/pages/discovery/profile_detail_page.dart'
    as discovery;
import 'package:hivmeet/domain/entities/match.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/presentation/pages/matches/matches_page.dart';
import 'package:hivmeet/presentation/pages/chat/chat_page.dart';
import 'package:hivmeet/presentation/pages/conversations/conversations_page.dart';

import 'package:hivmeet/presentation/pages/feed/feed_page.dart';
import 'package:hivmeet/presentation/pages/resources/resources_page.dart';
import 'package:hivmeet/presentation/pages/premium/premium_page.dart';
import 'package:hivmeet/presentation/pages/verification/verification_page.dart';
import 'package:hivmeet/presentation/pages/likes_received/likes_received_page.dart';
import 'package:hivmeet/presentation/pages/about/about_page.dart';
import 'package:hivmeet/presentation/pages/legal/privacy_page.dart';
import 'package:hivmeet/presentation/pages/legal/terms_page.dart';
import 'package:hivmeet/presentation/pages/interaction_history/interaction_history_page.dart';
import 'package:hivmeet/presentation/pages/interaction_history/my_likes_page.dart';
import 'package:hivmeet/presentation/pages/interaction_history/my_passes_page.dart';
import 'package:hivmeet/presentation/pages/interaction_history/stats_page.dart';
import 'package:hivmeet/presentation/pages/notifications/notifications_page.dart';
import 'package:hivmeet/core/services/localization_service.dart';

class AppRoutes {
  // Routes principales
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';

  // Routes de navigation principale
  static const String discovery = '/discovery';
  static const String discoveryFilters = '/discovery/filters';
  static const String matches = '/matches';
  static const String conversations = '/conversations';
  static const String chat = '/chat';
  static const String chatDetail = '/chat/:conversationId';
  static const String feed = '/feed';
  static const String resources = '/resources';

  // Routes de profil
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String profilePhotos = '/profile/photos';
  static const String profilePrivacy = '/profile/privacy';
  static const String profileNotifications = '/profile/notifications';
  static const String profileBlockedUsers = '/profile/blocked-users';
  static const String profileData = '/profile/data';
  static const String profileId = '/profile/:id';
  static const String profileDetail = '/profile-detail';

  // Routes de fonctionnalités
  static const String verification = '/verification';
  static const String likesReceived = '/likes-received';
  static const String premium = '/premium';

  // Routes de paramètres et légales
  static const String about = '/about';
  static const String privacy = '/privacy';
  static const String terms = '/terms';

  // Routes d'historique d'interactions
  static const String interactionHistory = '/interaction-history';
  static const String myLikes = '/interaction-history/likes';
  static const String myPasses = '/interaction-history/passes';
  static const String interactionStats = '/interaction-history/stats';

  // Notifications in-app
  static const String notifications = '/notifications';
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      // Vérifier l'authentification pour les routes protégées
      final authBloc = context.read<AuthBlocSimple>();
      final authState = authBloc.state;

      // Routes qui nécessitent une authentification
      final protectedRoutes = [
        AppRoutes.discovery,
        AppRoutes.matches,
        AppRoutes.conversations,
        AppRoutes.chat,
        AppRoutes.feed,
        AppRoutes.resources,
        AppRoutes.profile,
        AppRoutes.premium,
        AppRoutes.verification,
        AppRoutes.likesReceived,
        AppRoutes.interactionHistory,
      ];

      final isProtectedRoute = protectedRoutes
          .any((route) => state.matchedLocation.startsWith(route));

      if (isProtectedRoute) {
        if (authState is! Authenticated) {
          debugPrint(
              'Route protegee accedee sans authentification: ${state.matchedLocation}');
          return AppRoutes.login;
        }
      }

      return null; // Pas de redirection nécessaire
    },
    routes: [
      // Page de démarrage
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),

      // Pages d'onboarding et authentification
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

      // Pages de navigation principale
      GoRoute(
        path: AppRoutes.discovery,
        builder: (context, state) => const DiscoveryPage(),
      ),
      GoRoute(
        path: AppRoutes.discoveryFilters,
        builder: (context, state) => const FiltersPage(),
      ),
      GoRoute(
        path: AppRoutes.matches,
        builder: (context, state) => const MatchesPage(),
      ),
      GoRoute(
        path: AppRoutes.conversations,
        builder: (context, state) => const ConversationsPage(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) {
          // Page de chat par défaut - rediriger vers conversations
          return const ConversationsPage();
        },
      ),
      GoRoute(
        path: AppRoutes.chatDetail,
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId'];
          final conversation =
              state.extra is Conversation ? state.extra as Conversation : null;

          if (conversationId == null || conversationId.isEmpty) {
            return Scaffold(
              body: Center(
                child: Text(LocalizationService.translate(
                  'navigation.page_not_found',
                )),
              ),
            );
          }

          return ChatPage(
            conversationId: conversationId,
            conversation: conversation,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.feed,
        builder: (context, state) => const FeedPage(),
      ),
      GoRoute(
        path: AppRoutes.resources,
        builder: (context, state) => const ResourcesPage(),
      ),

      // Pages de profil
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const profile.ProfileDetailPage(),
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        builder: (context, state) => const ProfileEditPage(),
      ),
      GoRoute(
        path: AppRoutes.profilePhotos,
        builder: (context, state) => const ProfilePhotosPage(),
      ),
      GoRoute(
        path: AppRoutes.profilePrivacy,
        builder: (context, state) => const ProfilePrivacyPage(),
      ),
      GoRoute(
        path: AppRoutes.profileNotifications,
        builder: (context, state) => const ProfileNotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.profileBlockedUsers,
        builder: (context, state) => const ProfileBlockedUsersPage(),
      ),
      GoRoute(
        path: AppRoutes.profileData,
        builder: (context, state) => const ProfileDataPage(),
      ),
      GoRoute(
        path: AppRoutes.profileId,
        builder: (context, state) {
          final userId = state.pathParameters['id'];
          if (userId == null || userId.isEmpty) {
            return Scaffold(
              body: Center(
                child: Text(LocalizationService.translate(
                  'profile.profile_not_found',
                )),
              ),
            );
          }
          return PublicProfilePage(userId: userId);
        },
      ),
      GoRoute(
        path: AppRoutes.profileDetail,
        builder: (context, state) {
          final profile = state.extra as DiscoveryProfile?;
          if (profile == null) {
            return Scaffold(
              body: Center(
                child: Text(LocalizationService.translate(
                  'profile.profile_not_found',
                )),
              ),
            );
          }
          final readOnly = state.uri.queryParameters['readonly'] == 'true';
          return discovery.ProfileDetailPage(
            profile: profile,
            enableActions: !readOnly,
          );
        },
      ),

      // Pages de fonctionnalités
      GoRoute(
        path: AppRoutes.verification,
        builder: (context, state) => const VerificationPage(),
      ),
      GoRoute(
        path: AppRoutes.likesReceived,
        builder: (context, state) => const LikesReceivedPage(),
      ),
      GoRoute(
        path: AppRoutes.premium,
        builder: (context, state) => const PremiumPage(),
      ),
      // Pages de paramètres et légales
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (context, state) => const PrivacyPage(),
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (context, state) => const TermsPage(),
      ),

      // Pages d'historique d'interactions
      GoRoute(
        path: AppRoutes.interactionHistory,
        builder: (context, state) => const InteractionHistoryPage(),
      ),
      GoRoute(
        path: AppRoutes.myLikes,
        builder: (context, state) => const MyLikesPage(),
      ),
      GoRoute(
        path: AppRoutes.myPasses,
        builder: (context, state) => const MyPassesPage(),
      ),
      GoRoute(
        path: AppRoutes.interactionStats,
        builder: (context, state) => const StatsPage(),
      ),

      // Notifications in-app
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              LocalizationService.translate('navigation.page_not_found'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              LocalizationService.translate(
                'navigation.page_not_found_message',
                params: {'path': state.uri.toString()},
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/discovery'),
              child:
                  Text(LocalizationService.translate('navigation.back_home')),
            ),
          ],
        ),
      ),
    ),
  );
}
