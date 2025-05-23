import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/injection.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init', // Nom de la fonction d'initialisation
  preferRelativeImports: true, // Préférence pour les imports relatifs
  asExtension: false, // Pas comme une extension
)
Future<void> configureDependencies() => init(getIt);
