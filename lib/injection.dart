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
import 'package:hivmeet/presentation/blocs/conversations/conversations_bloc.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_bloc.dart';
import 'package:hivmeet/data/repositories/match_repository_impl.dart';
import 'package:hivmeet/data/datasources/remote/matching_api.dart';
import 'package:hivmeet/domain/repositories/match_repository.dart';
import 'package:hivmeet/data/datasources/remote/resources_api.dart';
import 'package:hivmeet/data/repositories/resource_repository_impl.dart';
import 'package:hivmeet/domain/repositories/resource_repository.dart';
import 'package:hivmeet/presentation/blocs/resources/resources_bloc.dart';
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

  // 11. BLoCs
  getIt.registerFactory<ConversationsBloc>(
    () => ConversationsBloc(
      getConversations: getIt<GetConversations>(),
      sendMessage: getIt<SendMessage>(),
      markAsRead: getIt<MarkAsRead>(),
    ),
  );

  getIt.registerFactory<DiscoveryBloc>(
    () => DiscoveryBloc(matchRepository: getIt<MatchRepository>()),
  );

  getIt.registerFactory<ResourcesBloc>(
    () => ResourcesBloc(getIt<ResourceRepository>()),
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
