// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:dio/dio.dart' as _i361;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:firebase_messaging/firebase_messaging.dart' as _i892;
import 'package:firebase_storage/firebase_storage.dart' as _i457;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:logger/logger.dart' as _i974;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import 'core/network/api_client.dart' as _i871;
import 'core/services/firebase_service.dart' as _i891;
import 'core/services/localization_service.dart' as _i398;
import 'core/services/token_service.dart' as _i261;
import 'data/datasources/local/auth_local_datasource.dart' as _i851;
import 'data/datasources/remote/auth_api.dart' as _i436;
import 'data/datasources/remote/matching_api.dart' as _i286;
import 'data/datasources/remote/messaging_api.dart' as _i789;
import 'data/datasources/remote/profile_api.dart' as _i193;
import 'data/datasources/remote/resources_api.dart' as _i260;
import 'data/datasources/remote/subscriptions_api.dart' as _i3;
import 'data/repositories/auth_repository_impl.dart' as _i145;
import 'data/repositories/match_repository_impl.dart' as _i246;
import 'data/repositories/message_repository_impl.dart' as _i976;
import 'data/repositories/premium_repository_impl.dart' as _i179;
import 'data/repositories/profile_repository_impl.dart' as _i1059;
import 'data/repositories/resource_repository_impl.dart' as _i663;
import 'data/repositories/settings_repository_impl.dart' as _i413;
import 'data/services/notification_service.dart' as _i753;
import 'data/services/payment_service.dart' as _i108;
import 'domain/repositories/auth_repository.dart' as _i716;
import 'domain/repositories/match_repository.dart' as _i185;
import 'domain/repositories/message_repository.dart' as _i629;
import 'domain/repositories/premium_repository.dart' as _i867;
import 'domain/repositories/profile_repository.dart' as _i172;
import 'domain/repositories/resource_repository.dart' as _i611;
import 'domain/repositories/settings_repository.dart' as _i175;
import 'domain/usecases/auth/get_current_user.dart' as _i1041;
import 'domain/usecases/auth/reset_password.dart' as _i861;
import 'domain/usecases/auth/sign_in.dart' as _i1041;
import 'domain/usecases/auth/sign_out.dart' as _i909;
import 'domain/usecases/auth/sign_up.dart' as _i397;
import 'domain/usecases/match/activate_boost.dart' as _i586;
import 'domain/usecases/match/like_profile.dart' as _i767;
import 'domain/usecases/match/super_like_profile.dart' as _i144;
import 'domain/usecases/profile/get_current_profile.dart' as _i845;
import 'domain/usecases/profile/get_profile.dart' as _i882;
import 'domain/usecases/profile/update_profile.dart' as _i164;
import 'injection_module.dart' as _i212;
import 'presentation/blocs/auth/auth_bloc.dart' as _i34;
import 'presentation/blocs/chat/chat_bloc.dart' as _i810;
import 'presentation/blocs/conversations/conversations_bloc.dart' as _i586;
import 'presentation/blocs/discovery/discovery_bloc.dart' as _i679;
import 'presentation/blocs/feed/feed_bloc.dart' as _i588;
import 'presentation/blocs/matches/matches_bloc.dart' as _i73;
import 'presentation/blocs/premium/premium_bloc.dart' as _i252;
import 'presentation/blocs/profile/profile_bloc.dart' as _i226;
import 'presentation/blocs/register/register_bloc.dart' as _i344;
import 'presentation/blocs/resource_detail/resource_detail_bloc.dart' as _i148;
import 'presentation/blocs/resources/resources_bloc.dart' as _i353;
import 'presentation/blocs/settings/settings_bloc.dart' as _i207;
import 'presentation/blocs/verification/verification_bloc.dart' as _i835;

// initializes the registration of main-scope dependencies inside of GetIt
Future<_i174.GetIt> init(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) async {
  final gh = _i526.GetItHelper(
    getIt,
    environment,
    environmentFilter,
  );
  final injectionModule = _$InjectionModule();
  await gh.factoryAsync<_i460.SharedPreferences>(
    () => injectionModule.sharedPreferences,
    preResolve: true,
  );
  gh.singleton<_i871.ApiClient>(() => _i871.ApiClient());
  await gh.singletonAsync<_i891.FirebaseService>(
    () {
      final i = _i891.FirebaseService();
      return i.initialize().then((_) => i);
    },
    preResolve: true,
  );
  gh.singleton<_i398.LocalizationService>(() => _i398.LocalizationService());
  gh.lazySingleton<_i59.FirebaseAuth>(() => injectionModule.firebaseAuth);
  gh.lazySingleton<_i974.FirebaseFirestore>(() => injectionModule.firestore);
  gh.lazySingleton<_i457.FirebaseStorage>(
      () => injectionModule.firebaseStorage);
  gh.lazySingleton<_i892.FirebaseMessaging>(
      () => injectionModule.firebaseMessaging);
  gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => injectionModule.secureStorage);
  gh.lazySingleton<_i361.Dio>(() => injectionModule.dio);
  gh.lazySingleton<_i974.Logger>(() => injectionModule.logger);
  gh.lazySingleton<_i175.SettingsRepository>(() => _i413.SettingsRepositoryImpl(
        gh<_i460.SharedPreferences>(),
        gh<_i558.FlutterSecureStorage>(),
      ));
  gh.singleton<_i753.NotificationService>(
      () => _i753.NotificationService(gh<_i892.FirebaseMessaging>()));
  gh.factory<_i207.SettingsBloc>(() =>
      _i207.SettingsBloc(settingsRepository: gh<_i175.SettingsRepository>()));
  gh.singleton<_i108.PaymentService>(
      () => _i108.PaymentService(gh<_i361.Dio>()));
  gh.factory<_i436.AuthApi>(() => _i436.AuthApi(gh<_i871.ApiClient>()));
  gh.factory<_i286.MatchingApi>(() => _i286.MatchingApi(gh<_i871.ApiClient>()));
  gh.factory<_i789.MessagingApi>(
      () => _i789.MessagingApi(gh<_i871.ApiClient>()));
  gh.factory<_i193.ProfileApi>(() => _i193.ProfileApi(gh<_i871.ApiClient>()));
  gh.factory<_i260.ResourcesApi>(
      () => _i260.ResourcesApi(gh<_i871.ApiClient>()));
  gh.factory<_i3.SubscriptionsApi>(
      () => _i3.SubscriptionsApi(gh<_i871.ApiClient>()));
  gh.lazySingleton<_i172.ProfileRepository>(
      () => _i1059.ProfileRepositoryImpl(gh<_i193.ProfileApi>()));
  gh.lazySingleton<_i851.AuthLocalDataSource>(
      () => _i851.AuthLocalDataSourceImpl(
            gh<_i558.FlutterSecureStorage>(),
            gh<_i460.SharedPreferences>(),
          ));
  gh.lazySingleton<_i436.AuthRemoteDataSource>(
      () => _i436.AuthRemoteDataSourceImpl(
            gh<_i59.FirebaseAuth>(),
            gh<_i974.FirebaseFirestore>(),
            gh<_i361.Dio>(),
            gh<_i871.ApiClient>(),
          ));
  gh.lazySingleton<_i185.MatchRepository>(
      () => _i246.MatchRepositoryImpl(gh<_i286.MatchingApi>()));
  gh.factory<_i835.VerificationBloc>(() =>
      _i835.VerificationBloc(profileRepository: gh<_i172.ProfileRepository>()));
  gh.factory<_i845.GetCurrentProfile>(
      () => _i845.GetCurrentProfile(gh<_i172.ProfileRepository>()));
  gh.factory<_i882.GetProfile>(
      () => _i882.GetProfile(gh<_i172.ProfileRepository>()));
  gh.factory<_i164.UpdateProfile>(
      () => _i164.UpdateProfile(gh<_i172.ProfileRepository>()));
  gh.lazySingleton<_i611.ResourceRepository>(
      () => _i663.ResourceRepositoryImpl(gh<_i260.ResourcesApi>()));
  gh.factory<_i588.FeedBloc>(
      () => _i588.FeedBloc(resourceRepository: gh<_i611.ResourceRepository>()));
  gh.factory<_i353.ResourcesBloc>(() =>
      _i353.ResourcesBloc(resourceRepository: gh<_i611.ResourceRepository>()));
  gh.factory<_i148.ResourceDetailBloc>(() => _i148.ResourceDetailBloc(
      resourceRepository: gh<_i611.ResourceRepository>()));
  gh.singleton<_i261.TokenService>(() => _i261.TokenService(
        gh<_i558.FlutterSecureStorage>(),
        gh<_i59.FirebaseAuth>(),
        gh<_i436.AuthApi>(),
        gh<_i871.ApiClient>(),
      ));
  gh.factory<_i226.ProfileBloc>(() => _i226.ProfileBloc(
        getCurrentProfile: gh<_i845.GetCurrentProfile>(),
        updateProfile: gh<_i164.UpdateProfile>(),
        profileRepository: gh<_i172.ProfileRepository>(),
      ));
  gh.factory<_i679.DiscoveryBloc>(
      () => _i679.DiscoveryBloc(matchRepository: gh<_i185.MatchRepository>()));
  gh.factory<_i73.MatchesBloc>(
      () => _i73.MatchesBloc(matchRepository: gh<_i185.MatchRepository>()));
  gh.factory<_i586.ActivateBoost>(
      () => _i586.ActivateBoost(gh<_i185.MatchRepository>()));
  gh.factory<_i767.LikeProfile>(
      () => _i767.LikeProfile(gh<_i185.MatchRepository>()));
  gh.factory<_i144.SuperLikeProfile>(
      () => _i144.SuperLikeProfile(gh<_i185.MatchRepository>()));
  gh.lazySingleton<_i629.MessageRepository>(
      () => _i976.MessageRepositoryImpl(gh<_i789.MessagingApi>()));
  gh.lazySingleton<_i716.AuthRepository>(() => _i145.AuthRepositoryImpl(
        gh<_i436.AuthRemoteDataSource>(),
        gh<_i851.AuthLocalDataSource>(),
      ));
  gh.lazySingleton<_i867.PremiumRepository>(() => _i179.PremiumRepositoryImpl(
        gh<_i3.SubscriptionsApi>(),
        gh<_i108.PaymentService>(),
        gh<_i261.TokenService>(),
      ));
  gh.factory<_i810.ChatBloc>(() => _i810.ChatBloc(
        messageRepository: gh<_i629.MessageRepository>(),
        profileRepository: gh<_i172.ProfileRepository>(),
      ));
  gh.factory<_i586.ConversationsBloc>(() => _i586.ConversationsBloc(
        messageRepository: gh<_i629.MessageRepository>(),
        profileRepository: gh<_i172.ProfileRepository>(),
      ));
  gh.factory<_i252.PremiumBloc>(() =>
      _i252.PremiumBloc(premiumRepository: gh<_i867.PremiumRepository>()));
  gh.factory<_i1041.GetCurrentUser>(
      () => _i1041.GetCurrentUser(gh<_i716.AuthRepository>()));
  gh.factory<_i861.ResetPassword>(
      () => _i861.ResetPassword(gh<_i716.AuthRepository>()));
  gh.factory<_i1041.SignIn>(() => _i1041.SignIn(gh<_i716.AuthRepository>()));
  gh.factory<_i909.SignOut>(() => _i909.SignOut(gh<_i716.AuthRepository>()));
  gh.factory<_i397.SignUp>(() => _i397.SignUp(gh<_i716.AuthRepository>()));
  gh.factory<_i344.RegisterBloc>(() => _i344.RegisterBloc(
        signUp: gh<_i397.SignUp>(),
        authRepository: gh<_i716.AuthRepository>(),
      ));
  gh.factory<_i34.AuthBloc>(() => _i34.AuthBloc(
        getCurrentUser: gh<_i1041.GetCurrentUser>(),
        signOut: gh<_i909.SignOut>(),
        authRepository: gh<_i716.AuthRepository>(),
      ));
  return getIt;
}

class _$InjectionModule extends _i212.InjectionModule {}
