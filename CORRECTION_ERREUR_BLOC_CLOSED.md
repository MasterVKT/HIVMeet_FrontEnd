# Correction Erreur "Bad state: Cannot add events after calling close"

**Date**: 28 Décembre 2025
**Problème**: Erreur au lancement de l'application
**Erreur**: `Bad state: Cannot add new events after calling close`

## 🐛 Problème Identifié

### Symptôme
Lors du lancement de l'application, une erreur se produit :
```
Bad state: Cannot add new events after calling close
```

### Cause Racine

Les **listeners de streams** (`_statusSubscription`, `_userSubscription`, `_errorSubscription`) continuent à recevoir des événements et à appeler `add(AppStarted())` **même après que le Bloc soit fermé** (`close()` a été appelé).

**Scénario problématique** :
```
1. AuthBlocSimple est créé
2. Les listeners sont configurés (_initializeAuthListeners)
3. L'utilisateur navigue ou l'app se ferme
4. Le Bloc est fermé (close() appelé)
5. ❌ Un stream émet encore un événement (status/user change)
6. ❌ Le listener appelle add(AppStarted())
7. ❌ ERREUR: Cannot add events after calling close
```

### Pourquoi Ça Arrive ?

Les **StreamSubscriptions** ne sont pas automatiquement annulées quand le Bloc se ferme. Elles continuent à écouter les streams de `AuthenticationService` jusqu'à ce que `cancel()` soit explicitement appelé dans la méthode `close()`.

Si un événement arrive **entre** le moment où `close()` est appelé et le moment où les subscriptions sont annulées, le listener tente d'ajouter un événement à un Bloc fermé → **ERREUR**.

## ✅ Solution Implémentée

### Protection `isClosed` Ajoutée

**Dans `_handleAuthStatusChangeInternal`** :
```dart
void _handleAuthStatusChangeInternal(AuthenticationStatus status) {
    developer.log(
        '🔄 Changement de status interne: $status -> déclenchement AppStarted',
        name: 'AuthBloc');
    
    // ✅ Vérifier que le Bloc n'est pas fermé avant d'ajouter un événement
    if (!isClosed) {
      add(AppStarted());
    } else {
      developer.log('⚠️ Bloc fermé, événement AppStarted ignoré', name: 'AuthBloc');
    }
}
```

**Dans `_handleUserChangeInternal`** :
```dart
void _handleUserChangeInternal(domain.User? user) {
    developer.log(
        '👤 Changement utilisateur interne: ${user?.email} -> déclenchement AppStarted',
        name: 'AuthBloc');
    
    // ✅ Vérifier que le Bloc n'est pas fermé avant d'ajouter un événement
    if (!isClosed) {
      add(AppStarted());
    } else {
      developer.log('⚠️ Bloc fermé, événement AppStarted ignoré', name: 'AuthBloc');
    }
}
```

**Dans le listener d'erreurs** :
```dart
_errorSubscription = _authService.errorStream.listen(
    (error) {
        developer.log('❌ LISTENER ERROR: $error', name: 'AuthBloc');
        // ✅ Vérifier avant d'ajouter l'événement
        if (!isClosed) {
            add(AppStarted());
        }
    },
    onError: (error) {
        developer.log('❌ Erreur error stream: $error', name: 'AuthBloc');
    },
);
```

## 🔍 Explication Technique

### La Propriété `isClosed`

Tous les Blocs héritent de la propriété `isClosed` :
- `false` : Le Bloc est actif et accepte les événements
- `true` : Le Bloc est fermé, appeler `add()` lève une exception

### Pourquoi Cette Vérification Est Nécessaire

**Sans la vérification** :
```dart
// ❌ ERREUR potentielle
_statusSubscription = _authService.statusStream.listen(
    (status) {
        add(AppStarted());  // ❌ Peut échouer si Bloc fermé
    },
);
```

**Avec la vérification** :
```dart
// ✅ SÉCURISÉ
_statusSubscription = _authService.statusStream.listen(
    (status) {
        if (!isClosed) {  // ✅ Vérifier d'abord
            add(AppStarted());
        }
    },
);
```

### Alternative : Annuler les Subscriptions Plus Tôt

Une autre approche (que nous utilisons déjà) est d'annuler les subscriptions dans `close()` :

```dart
@override
Future<void> close() {
    _statusSubscription?.cancel();
    _userSubscription?.cancel();
    _errorSubscription?.cancel();
    return super.close();
}
```

**MAIS** il existe toujours une **race condition** :
```
Thread 1: close() appelé → cancel() en cours
Thread 2: Stream émet → listener déclenché → add() appelé
         → Bloc déjà fermé → ERREUR
```

La vérification `if (!isClosed)` est donc une **protection supplémentaire nécessaire**.

## 🎯 Flux Corrigé

### Scénario Normal (Bloc Actif)
```
Stream émet un événement
    → Listener déclenché
    → Vérifie: !isClosed = true ✅
    → add(AppStarted()) exécuté
    → Événement traité normalement
```

### Scénario de Fermeture (Bloc Fermé)
```
close() appelé → isClosed = true
    ↓
Stream émet un événement (pendant cancel())
    → Listener déclenché
    → Vérifie: !isClosed = false ❌
    → add(AppStarted()) IGNORÉ
    → Log: "⚠️ Bloc fermé, événement AppStarted ignoré"
    → Pas d'erreur ✅
```

## 🛡️ Protections Complètes Maintenant en Place

### 1. Debouncing (500ms)
Évite les appels répétés trop rapprochés de `AppStarted`

### 2. Flag de Traitement
Empêche le traitement concurrent de plusieurs `AppStarted`

### 3. Vérification `isClosed` (NOUVEAU)
Empêche l'ajout d'événements à un Bloc fermé

### 4. Annulation des Subscriptions
Les subscriptions sont annulées dans `close()`

## 📊 Logs de Débogage Attendus

**Avec cette correction, si un événement arrive après fermeture** :
```
🔄 Changement de status interne: disconnected -> déclenchement AppStarted
⚠️ Bloc fermé, événement AppStarted ignoré
```

**Au lieu de** :
```
🔄 Changement de status interne: disconnected -> déclenchement AppStarted
❌ Unhandled Exception: Bad state: Cannot add new events after calling close
```

## 🔄 Cycle de Vie Complet du Bloc

```
1. CRÉATION
   → AuthBlocSimple()
   → _initializeAuthListeners()
   → Subscriptions actives

2. UTILISATION
   → Événements reçus et traités
   → États émis
   → UI réagit

3. NAVIGATION/FERMETURE
   → Widget dispose() appelé
   → BlocProvider.close() appelé
   → AuthBlocSimple.close() appelé
   → isClosed = true
   → Subscriptions annulées (cancel())
   
   ⚠️ ZONE DANGEREUSE (race condition)
   → Pendant cancel(), streams peuvent encore émettre
   → Listeners vérifient !isClosed avant add()
   → Si fermé, événements ignorés ✅

4. FIN
   → Toutes ressources libérées
   → Aucune fuite mémoire
```

## 🧪 Test de Validation

### Test 1 : Navigation Rapide
```bash
# Lancer l'app
flutter run

# Naviguer rapidement entre pages
# (Force la création/destruction de BlocProviders)
```
**Résultat attendu** : Pas d'erreur "Cannot add events after calling close"

### Test 2 : Hot Restart Pendant Authentification
```bash
# Lancer l'app
flutter run

# Pendant que l'authentification est en cours, faire hot restart
R
```
**Résultat attendu** : Pas d'erreur, redémarrage propre

### Test 3 : Fermeture Pendant Changement d'État
```bash
# Se connecter
# Immédiatement après, revenir en arrière (pop)
```
**Résultat attendu** : Navigation fluide, pas d'erreur

## 📝 Modifications Apportées

### Fichier Modifié
- `lib/presentation/blocs/auth/auth_bloc_simple.dart`

### Méthodes Modifiées
1. `_handleAuthStatusChangeInternal` - Ajout vérification `!isClosed`
2. `_handleUserChangeInternal` - Ajout vérification `!isClosed`
3. Listener d'erreurs - Ajout vérification `!isClosed`

### Ajouts
- 3 vérifications `if (!isClosed)` avant chaque `add()`
- Logs informatifs quand un événement est ignoré

## ⚠️ Bonnes Pratiques

### À Faire TOUJOURS
```dart
// ✅ Vérifier isClosed avant add() dans les callbacks asynchrones
if (!isClosed) {
    add(MonEvent());
}
```

### À Éviter
```dart
// ❌ add() sans vérification dans un stream listener
_stream.listen((data) {
    add(MonEvent());  // Peut échouer si Bloc fermé
});
```

## 🎓 Leçons Apprises

### 1. Race Conditions avec Streams
Les streams asynchrones peuvent émettre des événements **après** la fermeture d'un Bloc. Toujours vérifier `isClosed`.

### 2. Lifecycle du Bloc
Le cycle de vie d'un Bloc n'est pas instantané. Entre `close()` et la libération complète, il y a une fenêtre où des problèmes peuvent survenir.

### 3. Défense en Profondeur
Plusieurs couches de protection (debounce, flags, isClosed) sont nécessaires pour un système robuste.

## ✅ Résumé

**Problème** : Erreur "Cannot add events after calling close" causée par des listeners qui tentent d'ajouter des événements à un Bloc fermé.

**Solution** : Ajout de vérifications `if (!isClosed)` avant tous les appels à `add()` dans les listeners.

**Résultat** : Le Bloc ignore proprement les événements reçus après sa fermeture, sans lever d'exception.

---
*Correction appliquée le 28 Décembre 2025*
