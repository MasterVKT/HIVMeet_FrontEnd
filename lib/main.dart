// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:hivmeet/core/config/app_config.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/routes.dart';
import 'package:hivmeet/core/config/logging_config.dart';
import 'package:hivmeet/core/realtime/realtime_event.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/core/services/notification_websocket_service.dart';
import 'package:hivmeet/data/services/notification_service.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_bloc_simple.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_state.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_bloc.dart';
import 'package:hivmeet/presentation/blocs/notifications/notifications_bloc.dart';
import 'package:hivmeet/presentation/blocs/notifications/notifications_event.dart';
import 'package:hivmeet/presentation/blocs/unread/unread_cubit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Top-level so the Firebase isolate can reference it
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) =>
    firebaseMessagingBackgroundHandler(message);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser la configuration de logging
  LoggingConfig.init();

  // Filtrer les logs EGL répétitifs
  if (kDebugMode) {
    // Supprimer les logs EGL_emulation qui polluent la console
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  // Initialiser Firebase
  await Firebase.initializeApp();

  // Détecter émulateur vs appareil physique AVANT toute initialisation réseau
  await AppConfig.init();

  // Initialiser les locales supportées pour timeago
  timeago.setLocaleMessages('fr', timeago.FrMessages());
  timeago.setLocaleMessages('en', timeago.EnMessages());

  // Configurer l'injection de dépendances
  await configureDependencies();

  // Initialiser les services
  final localizationService = getIt<LocalizationService>();
  await localizationService.initialize();

  // Configurer Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // Passer les erreurs asynchrones non gérées à Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const HIVMeetApp());
}

class HIVMeetApp extends StatefulWidget {
  const HIVMeetApp({super.key});

  @override
  State<HIVMeetApp> createState() => _HIVMeetAppState();
}

class _HIVMeetAppState extends State<HIVMeetApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notificationWs = getIt<NotificationWebSocketService>();
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        notificationWs.suspend();
        break;
      case AppLifecycleState.resumed:
        notificationWs.resume();
        getIt<RealtimeEventBus>().publish(const RealtimeEvent(
          type: RealtimeEventType.appResumed,
          source: RealtimeSource.local,
        ));
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBlocSimple>(
          create: (context) => getIt<AuthBlocSimple>(),
        ),
        BlocProvider<DiscoveryBloc>(
          create: (context) => getIt<DiscoveryBloc>(),
        ),
        BlocProvider<UnreadCubit>(
          create: (context) => getIt<UnreadCubit>(),
        ),
        BlocProvider<NotificationsBloc>(
          create: (context) => getIt<NotificationsBloc>(),
        ),
      ],
      child: BlocListener<AuthBlocSimple, AuthState>(
        listener: (context, state) {
          final notifService = getIt<NotificationService>();
          final notificationWs = getIt<NotificationWebSocketService>();
          if (state is Authenticated) {
            notifService.setSessionActive(true);
            context.read<NotificationsBloc>().add(const LoadNotifications());
            notifService.initialize();
            // Idempotent : connect() ne fait rien si déjà connecté/en cours,
            // nécessaire car ce listener peut re-recevoir `Authenticated`
            // plusieurs fois pour une même session (voir AuthBlocSimple).
            notificationWs.connect();
          } else if (state is Unauthenticated) {
            notifService.setSessionActive(false);
            context.read<NotificationsBloc>().add(const ClearNotifications());
            notifService.removeTokenFromBackend();
            notificationWs.disconnect();
          }
        },
        child: MaterialApp.router(
          title: 'HIVMeet',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
          localizationsDelegates: [
            // Délégués de localisation Flutter
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr'), // Français
            Locale('en'), // Anglais
          ],
          locale: const Locale('fr'),
          builder: (context, child) {
            if (kDebugMode) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(1.0),
                ),
                child: child!,
              );
            }
            return child!;
          },
        ),
      ),
    );
  }
}
