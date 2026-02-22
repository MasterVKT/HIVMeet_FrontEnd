# 🚀 Test Rapide - Écran Blanc

## ✅ Correctifs Appliqués

J'ai ajouté plusieurs améliorations pour diagnostiquer et corriger l'écran blanc :

### 1. **Logs de débogage améliorés**
- ✅ Log au début du `build()` de chaque page
- ✅ Log dans `AppScaffold` pour tracer la construction
- ✅ Background explicite (`backgroundColor: Colors.white`) dans `AppScaffold`

### 2. **État par défaut visible**
- ✅ Container avec couleur de fond dans l'état "inconnu" de DiscoveryPage
- ✅ Widget de fallback avec LoadingWidget

### 3. **Widget de debug créé**
- ✅ Fichier `debug_screen.dart` pour tester l'affichage

## 🧪 Test Immédiat

### Option 1 : Hot Reload (Le Plus Rapide)
Si l'app est déjà lancée, faites simplement :
```
r  # Hot reload dans le terminal flutter
```

### Option 2 : Hot Restart
```
R  # Hot restart dans le terminal flutter
```

### Option 3 : Relancer complètement
```bash
flutter run
```

## 📊 Analyser les Logs

Après le lancement, vous devriez voir dans les logs :

```
🔍 DEBUG SplashPage: build() appelé
🔄 DEBUG SplashPage: BlocListener state change: AuthInitial()
🔄 DEBUG SplashPage: BlocListener state change: AuthLoading()
🔄 DEBUG SplashPage: BlocListener state change: Authenticated(...)
✅ DEBUG SplashPage: Authenticated détecté, navigation...
✅ DEBUG SplashPage: Navigation vers /discovery effectuée
🔍 DEBUG DiscoveryPage: build() appelé
🔍 DEBUG AppScaffold: build() appelé - currentIndex: 0
🔄 DEBUG DiscoveryPage: initState()
🔄 DEBUG DiscoveryPage: State change: DiscoveryLoading()
```

### 🔴 Si les logs s'arrêtent à un moment précis :

1. **S'arrête après "Navigation vers /discovery"**
   → Le problème est dans le routing ou DiscoveryPage ne se construit pas

2. **S'arrête après "build() appelé"**
   → Le problème est dans le widget tree (layout, contraintes, etc.)

3. **Aucun log du tout**
   → Le problème est avant même le build (initialization, bloc, etc.)

## 🔧 Tests de Diagnostic Progressifs

### Test 1 : Forcer un écran de debug

Dans `routes.dart`, modifiez temporairement :

```dart
GoRoute(
  path: AppRoutes.discovery,
  builder: (context, state) {
    // TEST: Retourner un widget simple
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Text(
          'DISCOVERY PAGE TEST',
          style: TextStyle(fontSize: 40, color: Colors.white),
        ),
      ),
    );
    // return const DiscoveryPage(); // Restaurer après le test
  },
),
```

**Si cela s'affiche** → Le problème est dans `DiscoveryPage` elle-même
**Si cela ne s'affiche pas** → Le problème est dans le routing/navigation

### Test 2 : Utiliser le DebugScreen

Dans `routes.dart` :

```dart
import 'package:hivmeet/presentation/widgets/debug/debug_screen.dart';

GoRoute(
  path: AppRoutes.discovery,
  builder: (context, state) => const DebugScreen(
    message: 'DISCOVERY\nROUTE ATTEINTE',
    backgroundColor: Colors.green,
  ),
),
```

### Test 3 : Court-circuiter l'authentification

Dans `main.dart`, changez temporairement :

```dart
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.discovery, // Au lieu de splash
    // ... reste du code
```

**Si l'app fonctionne** → Le problème est dans le flux d'authentification
**Si l'écran blanc persiste** → Le problème est dans DiscoveryPage

### Test 4 : Simplifier DiscoveryPage

Dans `discovery_page.dart`, remplacez temporairement le body de `BlocConsumer` :

```dart
builder: (context, state) {
  print('🔄 DEBUG DiscoveryPage: State change: $state');
  
  // TEST SIMPLE
  return Container(
    color: Colors.orange,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'DISCOVERY PAGE',
            style: TextStyle(fontSize: 40, color: Colors.white),
          ),
          SizedBox(height: 20),
          Text(
            'State: $state',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    ),
  );
},
```

## 🎯 Cas Spécifiques

### Cas 1 : Écran blanc sur SplashPage
**Solution** : Le Scaffold de SplashPage a déjà `backgroundColor: Colors.white`, donc le fond est là mais le contenu est peut-être invisible.

Vérifiez :
- Les animations ne bloquent pas le rendu
- Le `SafeArea` ne cache pas le contenu
- Les couleurs de texte sont visibles (pas blanc sur blanc)

### Cas 2 : Écran blanc après navigation vers Discovery
**Solution** : Vérifiez que `AppScaffold` se construit correctement.

Le log devrait montrer :
```
🔍 DEBUG AppScaffold: build() appelé - currentIndex: 0
```

### Cas 3 : Écran blanc uniquement sur émulateur Android
**Solution** : Problème de rendu OpenGL

Essayez :
```bash
flutter run --enable-software-rendering
```

## 📱 Test sur Différents Environnements

### Émulateur Android
```bash
flutter run
```

### Chrome (Web)
```bash
flutter run -d chrome
```

### Windows (Desktop)
```bash
flutter run -d windows
```

Si l'app fonctionne sur un environnement mais pas un autre → Problème spécifique à la plateforme.

## 🆘 Si Rien ne Fonctionne

### Solution d'urgence : Mode Minimal

Créez un fichier `lib/main_minimal.dart` :

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(MinimalApp());
}

class MinimalApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.teal,
        body: Center(
          child: Text(
            'APP MINIMALE\nFONCTIONNE',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 40,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
```

Lancez avec :
```bash
flutter run lib/main_minimal.dart
```

**Si cela fonctionne** → Le problème est dans votre code métier (bloc, auth, etc.)
**Si cela ne fonctionne pas** → Problème avec Flutter SDK ou émulateur

## 📝 Prochaines Étapes

1. ✅ Faites un Hot Reload
2. 📋 Partagez les nouveaux logs complets
3. 🔍 Identifiez à quel moment les logs s'arrêtent
4. 🎯 Appliquez le test correspondant ci-dessus

---

**💡 Astuce** : Utilisez `Ctrl+F` dans le terminal pour rechercher :
- `🔍 DEBUG` → Points d'entrée des widgets
- `🔄 DEBUG` → Changements d'état
- `❌` ou `ERROR` → Erreurs
- `Exception` → Exceptions non gérées
