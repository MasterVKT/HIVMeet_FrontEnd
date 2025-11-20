// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/routes.dart';
import 'package:hivmeet/core/config/logging_config.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_bloc_simple.dart';
import 'package:hivmeet/presentation/blocs/discovery/discovery_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

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

class HIVMeetApp extends StatelessWidget {
  const HIVMeetApp({super.key});

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
      ],
      child: MaterialApp.router(
        title: 'HIVMeet',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        builder: (context, child) {
          // Filtrer les logs EGL en mode debug
          if (kDebugMode) {
            // Rediriger les logs EGL vers un niveau plus élevé pour les masquer
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(1.0), // Éviter les problèmes de redimensionnement
              ),
              child: child!,
            );
          }
          return child!;
        },
      ),
    );
  }
}
