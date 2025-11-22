import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hivmeet/core/services/token_manager.dart';
import 'package:hivmeet/core/services/authentication_service.dart';
import 'package:hivmeet/core/network/api_client.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/core/services/network_connectivity_service.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_bloc_simple.dart';
import 'package:hivmeet/data/datasources/remote/settings_api.dart';
import 'package:hivmeet/data/datasources/remote/messaging_api.dart';
import 'package:hivmeet/data/repositories/message_repository_impl.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';
import 'package:hivmeet/domain/usecases/message/get_conversations.dart';
import 'package:hivmeet/domain/usecases/message/send_message.dart';
import 'package:hivmeet/domain/usecases/message/mark_as_read.dart';
import 'package:hivmeet/domain/usecases/chat/get_messages.dart';
import 'package:hivmeet/domain/usecases/chat/send_text_message.dart';
import 'package:hivmeet/domain/usecases/chat/send_media_message.dart';
import 'package:hivmeet/domain/usecases/chat/mark_message_as_read.dart';
import 'package:hivmeet/domain/usecases/match/get_discovery_profiles.dart';
import 'package:hivmeet/domain/usecases/match/like_profile.dart';
import 'package:hivmeet/domain/usecases/match/dislike_profile.dart';
import 'package:hivmeet/domain/usecases/match/super_like_profile.dart';
import 'package:hivmeet/domain/usecases/match/rewind_swipe.dart';
import 'package:hivmeet/domain/usecases/match/update_filters.dart';
import 'package:hivmeet/domain/usecases/match/get_daily_like_limit.dart';
import 'package:hivmeet/domain/usecases/match/get_matches.dart';
import 'package:hivmeet/domain/usecases/match/delete_match.dart';
import 'package:hivmeet/domain/usecases/match/get_likes_received.dart';
import 'package:hivmeet/domain/usecases/match/get_likes_received_count.dart';
import 'package:hivmeet/domain/usecases/match/activate_boost.dart';
import 'package:hivmeet/domain/usecases/resources/get_resources.dart';
import 'package:hivmeet/domain/usecases/resources/get_feed_posts.dart';
import 'package:hivmeet/domain/usecases/resources/like_post.dart';
import 'package:hivmeet/domain/usecases/resources/comment_post.dart';
import 'package:hivmeet/domain/usecases/resources/add_to_favorites.dart';
import 'package:hivmeet/presentation/blocs/conversations/conversations_bloc.dart';
import 'package:hivmeet/presentation/blocs/chat/chat_bloc.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_bloc.dart';
import 'package:hivmeet/data/repositories/match_repository_impl.dart';
import 'package:hivmeet/data/datasources/remote/matching_api.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';
import 'package:hivmeet/data/datasources/remote/resources_api.dart';
import 'package:hivmeet/data/repositories/resource_repository_impl.dart';
import 'package:hivmeet/domain/repositories/resource_repository.dart';
import 'package:hivmeet/presentation/blocs/resources/resources_bloc.dart';
import 'package:hivmeet/data/datasources/remote/profile_api.dart';
import 'package:hivmeet/data/repositories/profile_repository_impl.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';
import 'package:hivmeet/domain/usecases/profile/get_current_profile.dart';
import 'package:hivmeet/domain/usecases/profile/update_profile.dart';
import 'package:hivmeet/domain/usecases/profile/upload_photo.dart';
import 'package:hivmeet/domain/usecases/profile/delete_photo.dart';
import 'package:hivmeet/domain/usecases/profile/set_main_photo.dart';
import 'package:hivmeet/domain/usecases/profile/reorder_photos.dart';
import 'package:hivmeet/domain/usecases/profile/update_location.dart';
import 'package:hivmeet/domain/usecases/profile/block_user.dart';
import 'package:hivmeet/domain/usecases/profile/unblock_user.dart';
import 'package:hivmeet/domain/usecases/profile/toggle_profile_visibility.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_bloc.dart';
// Note: AuthBloc classique temporairement désactivé
// import 'package:hivmeet/presentation/blocs/auth/auth_bloc.dart';
// import 'package:hivmeet/domain/repositories/auth_repository.dart';
// import 'package:hivmeet/data/repositories/auth_repository_impl.dart';
// import 'package:hivmeet/domain/usecases/auth/get_current_user.dart';
// import 'package:hivmeet/domain/usecases/auth/sign_out.dart';

final GetIt getIt = GetIt.instance;

/// Configuration manuelle des dépendances pour éviter les problèmes circulaires
Future<void> configureDependencies() async {
  // 1. Services externes (pas de dépendances)
  getIt.registerSingleton<FlutterSecureStorage>(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  );

  getIt.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);

  // 2. Services de base (dépendances simples)
  getIt.registerSingleton<LocalizationService>(LocalizationService());

  getIt.registerSingleton<NetworkConnectivityService>(
    NetworkConnectivityService(),
  );

  // 3. TokenManager sans ApiClient d'abord
  getIt.registerSingleton<TokenManager>(
    TokenManager(getIt<FlutterSecureStorage>()),
  );

  // 4. API Client avec TokenManager
  getIt.registerSingleton<ApiClient>(
    ApiClient(getIt<TokenManager>()),
  );

  // 5. Injection tardive de l'ApiClient dans TokenManager
  getIt<TokenManager>().setApiClient(getIt<ApiClient>());

  // 6. Service d'authentification (système principal)
  getIt.registerSingleton<AuthenticationService>(
    AuthenticationService(
      getIt<FirebaseAuth>(),
      getIt<TokenManager>(),
      getIt<ApiClient>(),
    ),
  );

  // 7. BLoC simple utilisant AuthenticationService directement
  getIt.registerFactory<AuthBlocSimple>(
    () => AuthBlocSimple(getIt<AuthenticationService>()),
  );

  // 8. APIs
  getIt.registerSingleton<SettingsApi>(
    SettingsApi(getIt<ApiClient>()),
  );

  getIt.registerSingleton<MessagingApi>(
    MessagingApi(getIt<ApiClient>()),
  );

  getIt.registerSingleton<ResourcesApi>(
    ResourcesApi(getIt<ApiClient>()),
  );

  getIt.registerSingleton<MatchingApi>(
    MatchingApi(getIt<ApiClient>()),
  );

  getIt.registerSingleton<ProfileApi>(
    ProfileApi(getIt<ApiClient>()),
  );

  // 9. Repositories
  getIt.registerSingleton<MessageRepository>(
    MessageRepositoryImpl(getIt<MessagingApi>()),
  );

  getIt.registerSingleton<ResourceRepository>(
    ResourceRepositoryImpl(getIt<ResourcesApi>()),
  );

  // 10. Repositories - Utiliser le vrai repository
  getIt.registerSingleton<MatchRepository>(
    MatchRepositoryImpl(getIt<MatchingApi>()),
  );

  getIt.registerSingleton<ProfileRepository>(
    ProfileRepositoryImpl(getIt<ProfileApi>()),
  );

  // 10.5. Use Cases pour Messages/Conversations
  getIt.registerSingleton<GetConversations>(
    GetConversations(getIt<MessageRepository>()),
  );

  getIt.registerSingleton<SendMessage>(
    SendMessage(getIt<MessageRepository>()),
  );

  getIt.registerSingleton<MarkAsRead>(
    MarkAsRead(getIt<MessageRepository>()),
  );

  // 10.6. Use Cases pour Chat
  getIt.registerSingleton<GetMessages>(
    GetMessages(getIt<MessageRepository>()),
  );

  getIt.registerSingleton<SendTextMessage>(
    SendTextMessage(getIt<MessageRepository>()),
  );

  getIt.registerSingleton<SendMediaMessage>(
    SendMediaMessage(getIt<MessageRepository>()),
  );

  getIt.registerSingleton<MarkMessageAsRead>(
    MarkMessageAsRead(getIt<MessageRepository>()),
  );

  // 10.7. Use Cases pour Match/Discovery
  getIt.registerSingleton<GetDiscoveryProfiles>(
    GetDiscoveryProfiles(getIt<MatchRepository>()),
  );

  getIt.registerSingleton<LikeProfile>(
    LikeProfile(getIt<MatchRepository>()),
  );

  getIt.registerSingleton<DislikeProfile>(
    DislikeProfile(getIt<MatchRepository>()),
  );

  getIt.registerSingleton<SuperLikeProfile>(
    SuperLikeProfile(getIt<MatchRepository>()),
  );

  getIt.registerSingleton<RewindSwipe>(
    RewindSwipe(getIt<MatchRepository>()),
  );

  getIt.registerSingleton<UpdateFilters>(
    UpdateFilters(getIt<MatchRepository>()),
  );

  getIt.registerSingleton<GetDailyLikeLimit>(
    GetDailyLikeLimit(getIt<MatchRepository>()),
  );

  getIt.registerSingleton<GetMatches>(
    GetMatches(getIt<MatchRepository>()),
  );

  getIt.registerSingleton<DeleteMatch>(
    DeleteMatch(getIt<MatchRepository>()),
  );

  getIt.registerSingleton<GetLikesReceived>(
    GetLikesReceived(getIt<MatchRepository>()),
  );

  getIt.registerSingleton<GetLikesReceivedCount>(
    GetLikesReceivedCount(getIt<MatchRepository>()),
  );

  getIt.registerSingleton<ActivateBoost>(
    ActivateBoost(getIt<MatchRepository>()),
  );

  // 10.8. Use Cases pour Resources/Feed
  getIt.registerSingleton<GetResources>(
    GetResources(getIt<ResourceRepository>()),
  );

  getIt.registerSingleton<GetFeedPosts>(
    GetFeedPosts(getIt<ResourceRepository>()),
  );

  getIt.registerSingleton<LikePost>(
    LikePost(getIt<ResourceRepository>()),
  );

  getIt.registerSingleton<CommentPost>(
    CommentPost(getIt<ResourceRepository>()),
  );

  getIt.registerSingleton<AddToFavorites>(
    AddToFavorites(getIt<ResourceRepository>()),
  );

  // 10.9. Use Cases pour Profile
  getIt.registerSingleton<GetCurrentProfile>(
    GetCurrentProfile(getIt<ProfileRepository>()),
  );

  getIt.registerSingleton<UpdateProfile>(
    UpdateProfile(getIt<ProfileRepository>()),
  );

  getIt.registerSingleton<UploadPhoto>(
    UploadPhoto(getIt<ProfileRepository>()),
  );

  getIt.registerSingleton<DeletePhoto>(
    DeletePhoto(getIt<ProfileRepository>()),
  );

  getIt.registerSingleton<SetMainPhoto>(
    SetMainPhoto(getIt<ProfileRepository>()),
  );

  getIt.registerSingleton<ReorderPhotos>(
    ReorderPhotos(getIt<ProfileRepository>()),
  );

  getIt.registerSingleton<UpdateLocation>(
    UpdateLocation(getIt<ProfileRepository>()),
  );

  getIt.registerSingleton<BlockUser>(
    BlockUser(getIt<ProfileRepository>()),
  );

  getIt.registerSingleton<UnblockUser>(
    UnblockUser(getIt<ProfileRepository>()),
  );

  getIt.registerSingleton<ToggleProfileVisibility>(
    ToggleProfileVisibility(getIt<ProfileRepository>()),
  );

  // 11. BLoCs
  getIt.registerFactory<ConversationsBloc>(
    () => ConversationsBloc(
      getConversations: getIt<GetConversations>(),
      sendMessage: getIt<SendMessage>(),
      markAsRead: getIt<MarkAsRead>(),
    ),
  );

  getIt.registerFactory<DiscoveryBloc>(
    () => DiscoveryBloc(
      getDiscoveryProfiles: getIt<GetDiscoveryProfiles>(),
      likeProfile: getIt<LikeProfile>(),
      dislikeProfile: getIt<DislikeProfile>(),
      superLikeProfile: getIt<SuperLikeProfile>(),
      rewindSwipe: getIt<RewindSwipe>(),
      updateFilters: getIt<UpdateFilters>(),
      getDailyLikeLimit: getIt<GetDailyLikeLimit>(),
    ),
  );

  getIt.registerFactory<ResourcesBloc>(
    () => ResourcesBloc(
      getResources: getIt<GetResources>(),
      addToFavorites: getIt<AddToFavorites>(),
    ),
  );

  getIt.registerFactory<ChatBloc>(
    () => ChatBloc(
      getMessages: getIt<GetMessages>(),
      sendTextMessage: getIt<SendTextMessage>(),
      sendMediaMessage: getIt<SendMediaMessage>(),
      markMessageAsRead: getIt<MarkMessageAsRead>(),
      authService: getIt<AuthenticationService>(),
    ),
  );

  getIt.registerFactory<ProfileBloc>(
    () => ProfileBloc(
      getCurrentProfile: getIt<GetCurrentProfile>(),
      updateProfile: getIt<UpdateProfile>(),
      uploadPhoto: getIt<UploadPhoto>(),
      deletePhoto: getIt<DeletePhoto>(),
      setMainPhoto: getIt<SetMainPhoto>(),
      reorderPhotos: getIt<ReorderPhotos>(),
      updateLocation: getIt<UpdateLocation>(),
      blockUser: getIt<BlockUser>(),
      unblockUser: getIt<UnblockUser>(),
      toggleProfileVisibility: getIt<ToggleProfileVisibility>(),
      profileRepository: getIt<ProfileRepository>(),
    ),
  );

  // 12. BLoCs pour les autres pages (enregistrement temporaire)
  // TODO: Implémenter les repositories et use cases appropriés
  // Pour l'instant, on commente les blocs complexes pour éviter l'écran blanc

  // Note: Les blocs suivants nécessitent des repositories qui ne sont pas encore implémentés
  // Ils seront réactivés une fois que les repositories seront créés

  /*
  getIt.registerFactory<DiscoveryBloc>(
    () => DiscoveryBloc(matchRepository, profileRepository),
  );

  getIt.registerFactory<MatchesBloc>(
    () => MatchesBloc(matchRepository),
  );

  getIt.registerFactory<ConversationsBloc>(
    () => ConversationsBloc(messageRepository, profileRepository),
  );

  getIt.registerFactory<ProfileBloc>(
    () => ProfileBloc(getCurrentProfile, updateProfile, profileRepository),
  );

  getIt.registerFactory<SettingsBloc>(
    () => SettingsBloc(settingsRepository),
  );

  getIt.registerFactory<ResourcesBloc>(
    () => ResourcesBloc(resourceRepository),
  );

  getIt.registerFactory<PremiumBloc>(
    () => PremiumBloc(premiumRepository),
  );
  */

  // Note: Tous les blocs nécessitent des repositories qui ne sont pas encore implémentés
  // Ils seront réactivés une fois que les repositories seront créés

  /*
  getIt.registerFactory<FeedBloc>(
    () => FeedBloc(resourceRepository),
  );

  getIt.registerFactory<ChatBloc>(
    () => ChatBloc(messageRepository, profileRepository),
  );
  */

  // Note: Les repositories, use cases et BLoCs classiques sont désactivés
  // pour éviter les dépendances complexes. Le nouveau AuthBlocSimple utilise AuthenticationService.
}
