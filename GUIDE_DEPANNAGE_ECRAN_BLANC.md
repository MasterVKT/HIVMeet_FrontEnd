# 🔍 Guide de Dépannage - Écran Blanc

## 🚨 Problème : Écran blanc au lancement de l'application

### 📋 Étapes de Diagnostic Rapide

#### Option A : Script Automatique (Recommandé)

**Windows** :
```bash
cd d:\Projets\HIVMeet\hivmeet
diagnostic_ecran_blanc.bat
```

Cela va :
1. Vérifier Flutter
2. Nettoyer le build
3. Récupérer les dépendances
4. Lancer l'app avec logs détaillés

#### Option B : Commandes Manuelles

```bash
# 1. Nettoyer
flutter clean

# 2. Récupérer les dépendances
flutter pub get

# 3. Lancer avec logs
flutter run
```

### 🔍 Analyse des Logs

Une fois l'app lancée, **recherchez ces patterns dans les logs** :

#### ✅ Logs Normaux (App fonctionne)
```
I/flutter: 🔍 DEBUG SplashPage: build() appelé
I/flutter: 🔄 DEBUG SplashPage: BlocListener state change: AuthLoading()
I/flutter: 🔄 DEBUG SplashPage: BlocListener state change: Authenticated(...)
I/flutter: ✅ DEBUG SplashPage: Navigation vers /discovery effectuée
I/flutter: 🔍 DEBUG DiscoveryPage: build() appelé
I/flutter: 🔍 DEBUG AppScaffold: build() appelé - currentIndex: 0
```

#### ❌ Problèmes Courants

**1. Bloc bloqué en AuthLoading**
```
I/flutter: 🔄 DEBUG SplashPage: BlocListener state change: AuthLoading()
// ... plus rien après
```
**Solution** : Problème d'authentification Firebase ou backend inaccessible

**2. Exception non gérée**
```
Exception: ...
StateError: ...
```
**Solution** : Lire l'exception complète et chercher le fichier/ligne mentionné

**3. Pas de logs du tout**
```
// Rien ne s'affiche
```
**Solution** : Problème de compilation ou de démarrage Flutter

**4. Navigation bloquée**
```
I/flutter: ✅ DEBUG SplashPage: Navigation vers /discovery effectuée
// ... mais pas de log DiscoveryPage
```
**Solution** : Problème dans DiscoveryPage ou routes

### 🛠️ Solutions par Symptôme

#### Symptôme 1 : Écran Blanc sur SplashPage

**Vérification** :
```dart
// Dans splash_page.dart, le Scaffold a-t-il un backgroundColor ?
Scaffold(
  backgroundColor: Colors.white,  // ✅ Doit être présent
  body: ...
)
```

**Fix** :
Si manquant, l'app affiche un écran noir/blanc par défaut.

#### Symptôme 2 : Écran Blanc après Navigation

**Vérification** :
```
I/flutter: ✅ DEBUG SplashPage: Navigation vers /discovery effectuée
// Mais écran blanc
```

**Causes possibles** :
1. `DiscoveryPage` ne se construit pas
2. `AppScaffold` a un problème
3. Widget retourne `null` ou vide

**Fix** :
Vérifiez que DiscoveryPage retourne bien un Scaffold avec contenu.

#### Symptôme 3 : Écran Blanc avec Erreur Bloc

**Log typique** :
```
Bad state: Cannot add new events after calling close
```

**Solution** :
Vérifiez que tous les Blocs sont enregistrés comme `Factory` dans `injection.dart` :
```dart
// ✅ CORRECT
getIt.registerFactory<MonBloc>(() => MonBloc(...));

// ❌ INCORRECT
getIt.registerLazySingleton<MonBloc>(() => MonBloc(...));
```

#### Symptôme 4 : Timeout après 10 secondes

**Log typique** :
```
⏱️ TIMEOUT: Navigation forcée vers login après 10s
```

**Cause** : L'authentification Firebase prend trop de temps ou échoue

**Solutions** :
1. Vérifier que Firebase est configuré
2. Vérifier la connexion internet
3. Vérifier que le backend est accessible

### 🔧 Correctifs d'Urgence

#### Fix 1 : Forcer l'affichage de Discovery directement

**Dans `routes.dart`** :
```dart
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.discovery, // Au lieu de splash
    // ...
  );
}
```

⚠️ Ceci contourne l'authentification - **à utiliser uniquement pour tester** !

#### Fix 2 : Widget de Debug Minimaliste

**Remplacer temporairement dans `routes.dart`** :
```dart
GoRoute(
  path: AppRoutes.splash,
  builder: (context, state) => Scaffold(
    backgroundColor: Colors.blue,
    body: Center(
      child: Text(
        'APP FONCTIONNE',
        style: TextStyle(fontSize: 40, color: Colors.white),
      ),
    ),
  ),
),
```

Si cela s'affiche → Le problème est dans `SplashPage`

#### Fix 3 : Désactiver temporairement le BlocListener

**Dans `splash_page.dart`**, remplacer :
```dart
return BlocListener<AuthBlocSimple, AuthState>(
  listener: (context, state) {
    // ... logique de navigation
  },
  child: Scaffold(...),
);
```

Par :
```dart
return Scaffold(
  backgroundColor: Colors.white,
  body: Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.favorite, size: 80, color: Colors.purple),
        SizedBox(height: 20),
        Text('HIVMeet', style: TextStyle(fontSize: 40)),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => context.go('/login'),
          child: Text('Aller à Login'),
        ),
      ],
    ),
  ),
);
```

### 📊 Checklist de Vérification

Cochez ce qui fonctionne :

- [ ] Flutter est installé et à jour (`flutter doctor`)
- [ ] `flutter clean` et `flutter pub get` exécutés
- [ ] Firebase est initialisé dans `main.dart`
- [ ] Les logs `DEBUG SplashPage: build()` apparaissent
- [ ] Le SplashPage a un `backgroundColor`
- [ ] L'état `AuthLoading` apparaît dans les logs
- [ ] La navigation vers `/discovery` est effectuée
- [ ] `DiscoveryPage: build()` apparaît dans les logs
- [ ] Aucune erreur/exception dans les logs

**Si tout est coché** → L'app devrait fonctionner

**Si un élément n'est pas coché** → C'est là qu'est le problème !

### 🆘 Besoin d'Aide Supplémentaire

Si l'écran reste blanc après ces étapes, **partagez** :

1. **Logs complets** de `flutter run` (du début à la fin)
2. **Capture d'écran** de l'écran blanc
3. **Réponses à ces questions** :
   - À quel moment l'écran devient-il blanc ? (immédiatement, après 2s, après navigation)
   - Avez-vous vu le logo HIVMeet s'afficher brièvement ?
   - Y a-t-il des erreurs dans les logs ?
   - Quand avez-vous remarqué le problème pour la première fois ?

### 📝 Informations Système Utiles

```bash
flutter --version
flutter doctor -v
```

---

**🎯 Action Immédiate** : Lancez `diagnostic_ecran_blanc.bat` et partagez les logs !
