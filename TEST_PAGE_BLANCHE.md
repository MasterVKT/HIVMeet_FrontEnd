# Guide de Test - Résolution Page Blanche

## 🧪 **Test 1: Application Actuelle** 

### **Lancer l'application et observer :**

```bash
flutter run --verbose
```

### **Indicateurs de Succès :**
1. ✅ **Logo HIVMeet visible** sur fond violet
2. ✅ **Messages dans console** : "AuthState changé: ..."
3. ✅ **Navigation automatique** vers onboarding/login après 3s max
4. ✅ **Texte d'état** visible sous le logo

### **Si ÉCHEC - Procéder au Test 2**

---

## 🔧 **Test 2: Version Simple (Fallback)**

### **Étape 1: Modifier le routeur**

Dans `lib/core/config/routes.dart`, remplacer :

```dart
// AVANT
import 'package:hivmeet/presentation/pages/splash/splash_page.dart';

GoRoute(
  path: AppRoutes.splash,
  builder: (context, state) => const SplashPage(),
),

// APRÈS
import 'package:hivmeet/presentation/pages/splash/simple_splash_page.dart';

GoRoute(
  path: AppRoutes.splash,
  builder: (context, state) => const SimpleSplashPage(),
),
```

### **Étape 2: Relancer l'application**

```bash
flutter run
```

### **Résultat Attendu :**
- ✅ **Logo HIVMeet** sur fond violet
- ✅ **Navigation automatique** vers login après 2 secondes
- ✅ **Page de login** s'affiche

---

## 🚨 **Test 3: Bypass Complet (Dernier Recours)**

### **Si même la version simple ne fonctionne pas :**

Dans `lib/core/config/routes.dart`, changer la route initiale :

```dart
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login', // Direct vers login
    routes: [
      // ... routes existantes
    ],
  );
}
```

---

## 📋 **Diagnostic des Logs**

### **Chercher ces messages dans la console :**

✅ **Succès :**
```
AuthState changé: Unauthenticated
Utilisateur non authentifié, navigation vers onboarding
```

❌ **Problème :**
```
Exception dans _onAppStarted: ...
Navigation forcée vers login après timeout
```

⚠️ **Firebase :**
```
W/Firestore: Stream closed with status: UNAVAILABLE
```

---

## 🔍 **Solutions Selon le Problème**

### **Page Totalement Blanche :**
- ➜ Utiliser **Test 2** (SimpleSplashPage)

### **Logo Visible mais Pas de Navigation :**
- ➜ Vérifier les logs d'état
- ➜ Attendre le timeout (3 secondes)

### **Erreurs Firebase :**
- ➜ Normal avec la configuration récente
- ➜ L'application doit quand même naviguer

### **Problème de Routage :**
- ➜ Utiliser **Test 3** (bypass splash)

---

## 🎯 **Actions Immédiates**

1. **Lancer Test 1** et attendre 5 secondes
2. **Observer les logs** dans la console
3. **Si échec → Test 2** (SimpleSplashPage)
4. **Si échec → Test 3** (Direct login)

**L'objectif est d'avoir au minimum la page de login qui s'affiche !** 