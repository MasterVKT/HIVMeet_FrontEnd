# 🔍 Diagnostic Écran Blanc v2 - Après Modifications

## 🎯 Contexte
L'écran blanc est réapparu après des modifications, alors que la solution précédente fonctionnait.

## 🔍 Points de vérification

### 1. Vérifier si le widget s'affiche réellement

Recherchez dans les logs :
- ✅ `🔄 DEBUG SplashPage: BlocListener state change:` → Le SplashPage reçoit-il les changements d'état ?
- ✅ `🔄 DEBUG EmptyStateWidget: build` → Le widget s'affiche-t-il ?
- ✅ `🔄 DEBUG DiscoveryPage: State change:` → La page Discovery est-elle atteinte ?

### 2. Problèmes possibles courants

#### A. Scaffold manquant
**Symptôme** : Widget affiché mais écran complètement blanc (pas de fond)
```dart
// ❌ MAUVAIS
return Column(...)

// ✅ BON
return Scaffold(
  body: Column(...)
)
```

#### B. Overflow ou contrainte non respectée
**Symptôme** : Widget ne se construit pas, RenderBox error
- Cherchez `RenderBox` ou `overflow` dans les logs
- Ajoutez `SingleChildScrollView` si nécessaire

#### C. Navigation bloquée
**Symptôme** : Reste bloqué sur SplashPage
- Vérifiez si `_hasNavigated` reste `false`
- Vérifiez si l'état `Authenticated` est émis

#### D. EmptyStateWidget avec contraintes invalides
**Symptôme** : Widget ne s'affiche pas malgré NoMoreProfiles
```dart
// Si dans un Column sans Expanded
return Expanded(
  child: EmptyStateWidget(...)
)
```

#### E. Problème de couleur (blanc sur blanc)
**Symptôme** : Widget présent mais invisible
- Vérifier que `backgroundColor` n'est pas blanc partout
- Vérifier les couleurs de texte

### 3. Commandes de diagnostic

#### Test 1 : Vérifier l'état de l'authentification
```dart
// Ajouter temporairement dans SplashPage
print('🔍 DEBUG: AuthState actuel: ${context.read<AuthBlocSimple>().state}');
```

#### Test 2 : Forcer la navigation
```dart
// Dans SplashPage.initState(), après un délai court
Future.delayed(Duration(seconds: 3), () {
  print('🔍 FORCE: Navigation vers /discovery');
  context.go('/discovery');
});
```

#### Test 3 : Vérifier si Discovery se charge
```dart
// Dans DiscoveryPage.build()
print('🔍 DEBUG DiscoveryPage: Widget building...');
return Container(
  color: Colors.red, // Temporaire pour visualiser
  child: Center(child: Text('TEST', style: TextStyle(fontSize: 40))),
);
```

### 4. Quick Fixes à tester

#### Fix 1 : Ajouter un fond de couleur à Scaffold
```dart
Scaffold(
  backgroundColor: Colors.white, // ou AppColors.primaryWhite
  body: ...
)
```

#### Fix 2 : Wrapper EmptyStateWidget dans SafeArea
```dart
return SafeArea(
  child: EmptyStateWidget(...)
)
```

#### Fix 3 : Ajouter des contraintes explicites
```dart
return Container(
  constraints: BoxConstraints(
    minHeight: MediaQuery.of(context).size.height,
  ),
  child: EmptyStateWidget(...)
)
```

## 📋 Checklist de diagnostic

Cochez ce qui fonctionne :

- [ ] SplashPage s'affiche avec le logo HIVMeet
- [ ] Logs `BlocListener state change` apparaissent
- [ ] État `Authenticated` est émis
- [ ] Navigation vers `/discovery` est effectuée
- [ ] DiscoveryPage.initState() est appelé
- [ ] DiscoveryBloc émet un état (Loading, Loaded, NoMoreProfiles)
- [ ] Widget final (cartes ou EmptyState) se construit

**Si un point ne fonctionne pas**, c'est là que se situe le problème !

## 🚨 Actions immédiates

### Si l'écran reste blanc sur SplashPage :
1. Vérifiez que Firebase est initialisé
2. Vérifiez que AuthBloc est créé correctement
3. Ajoutez un fond de couleur visible au Scaffold

### Si l'écran est blanc sur DiscoveryPage :
1. Vérifiez que le widget retourne un Scaffold
2. Vérifiez qu'il n'y a pas d'overflow
3. Testez avec un widget simple (Container rouge) temporairement

### Si EmptyStateWidget ne s'affiche pas :
1. Vérifiez les contraintes de layout
2. Ajoutez SingleChildScrollView au parent
3. Vérifiez les couleurs (pas de blanc sur blanc)

## 🔄 Test de régression

Pour identifier ce qui a cassé :

```bash
# Voir les derniers commits
git log --oneline -10

# Voir les fichiers modifiés
git status

# Voir les différences d'un fichier spécifique
git diff lib/presentation/pages/discovery/discovery_page.dart
```

## 💡 Solution temporaire d'urgence

Si vous avez besoin de débloquer rapidement :

```dart
// Dans main.dart, remplacer initialLocation
initialLocation: AppRoutes.discovery, // Au lieu de splash

// Ou forcer dans SplashPage
@override
void initState() {
  super.initState();
  // Navigation immédiate pour tester
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.go('/discovery');
  });
}
```

---

**🎯 Prochaine étape : Partagez les logs actuels pour un diagnostic précis !**
