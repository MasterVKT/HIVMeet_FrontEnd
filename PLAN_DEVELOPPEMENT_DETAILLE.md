# 🚀 PLAN DE DÉVELOPPEMENT DÉTAILLÉ - HIVMeet Frontend

**Date:** 20 novembre 2025
**Version:** 1.0
**Durée Totale Estimée:** 6-7 semaines (2 devs) | 13 semaines (1 dev)

---

## 📋 MÉTHODOLOGIE D'EXÉCUTION

### Principes de Développement

1. **Test-Driven Development (TDD)** pour tous les Use Cases
2. **Code Review** avant chaque merge
3. **Commits atomiques** avec messages clairs
4. **Documentation inline** pour code complexe
5. **Refactoring continu** pour éviter dette technique

### Définition of Done (DoD)

Pour chaque tâche:
- ✅ Code implémenté selon Clean Architecture
- ✅ Tests unitaires écrits et passent
- ✅ Documentation code ajoutée
- ✅ Pas d'erreurs d'analyse statique
- ✅ UI testé manuellement (si applicable)
- ✅ Code reviewed et approuvé

---

## 🔥 SPRINT 1: MVP FONCTIONNEL (2 semaines)

**Objectif:** Débloquer les features bloquantes pour rendre l'app utilisable end-to-end

### 📊 Métriques de Succès Sprint 1
- ✅ Flux complet: Auth → Discovery → Match → Conversations → Chat
- ✅ Matches page fonctionnelle avec vraies données
- ✅ Conversations listées correctement
- ✅ Settings sauvegardés en backend
- ✅ Navigation fluide sans duplication code
- ✅ Tests coverage >60% sur code critique

---

### 🎯 TÂCHE 1.1: Matches Page Complète (3 jours)

#### Sous-tâches

**1.1.1 - Créer Get Matches Use Case**
- **Fichier:** `/lib/domain/usecases/match/get_matches.dart`
- **Code:**
```dart
class GetMatches implements UseCase<List<Match>, NoParams> {
  final MatchRepository repository;

  GetMatches(this.repository);

  @override
  Future<Either<Failure, List<Match>>> call(NoParams params) async {
    return await repository.getMatches();
  }
}
```
- **Tests:** `/test/domain/usecases/match/get_matches_test.dart`
- **Estimation:** 0.5 jour

**1.1.2 - Créer Delete Match Use Case**
- **Fichier:** `/lib/domain/usecases/match/delete_match.dart`
- **Code:**
```dart
class DeleteMatch implements UseCase<void, DeleteMatchParams> {
  final MatchRepository repository;

  DeleteMatch(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteMatchParams params) async {
    return await repository.deleteMatch(params.matchId);
  }
}

class DeleteMatchParams extends Equatable {
  final String matchId;
  const DeleteMatchParams({required this.matchId});

  @override
  List<Object> get props => [matchId];
}
```
- **Tests:** `/test/domain/usecases/match/delete_match_test.dart`
- **Estimation:** 0.5 jour

**1.1.3 - Compléter MatchesBloc**
- **Fichier:** `/lib/presentation/blocs/matches/matches_bloc.dart`
- **Modifications:**
  - Intégrer GetMatches use case
  - Intégrer DeleteMatch use case
  - Ajouter filtrage (all/new/active)
  - Ajouter recherche par nom
  - Ajouter gestion erreurs robuste
- **États à ajouter:**
  - `MatchesFiltered` pour filtres actifs
  - `MatchDeleting` pour suppression en cours
  - `MatchDeleted` pour confirmation suppression
- **Estimation:** 1 jour

**1.1.4 - Implémenter Matches Page UI**
- **Fichier:** `/lib/presentation/pages/matches/matches_page.dart`
- **Composants:**
  - Liste matches avec lazy loading
  - Pull-to-refresh
  - Filtre tabs (Tous/Nouveaux/Actifs)
  - Barre de recherche
  - Empty state quand aucun match
  - Swipe to delete avec confirmation
  - Navigation vers chat au tap
- **Widgets à créer:**
  - `MatchCard` - Carte match avec photo + preview message
  - `MatchesFilterBar` - Barre filtres
  - `MatchesSearchBar` - Recherche
- **Estimation:** 1 jour

**1.1.5 - Tests d'Intégration Matches**
- **Fichiers:**
  - `/test/presentation/blocs/matches/matches_bloc_test.dart`
  - `/test/presentation/pages/matches/matches_page_test.dart`
- **Scénarios:**
  - Chargement initial matches
  - Filtrage par statut
  - Recherche par nom
  - Suppression match avec confirmation
  - Gestion erreurs réseau
- **Estimation:** 0.5 jour

**DoD Tâche 1.1:**
- ✅ Use cases créés avec tests
- ✅ MatchesBloc complet avec tests
- ✅ Matches page production-ready
- ✅ Navigation vers chat fonctionnelle
- ✅ Tests coverage >80%

---

### 🎯 TÂCHE 1.2: Conversations Page Complète (2 jours)

#### Sous-tâches

**1.2.1 - Corriger ConversationsBloc**
- **Fichier:** `/lib/presentation/blocs/conversations/conversations_bloc.dart`
- **Modifications critiques:**
  - ❌ Retirer `userId: 'current_user_id'` hardcodé
  - ✅ Injecter `GetCurrentUser` use case pour obtenir vrai userId
  - ✅ Ajouter state `ConversationsError` pour erreurs
  - ✅ Ajouter gestion offline
  - ✅ Ajouter pull-to-refresh
  - ✅ Ajouter filtres (all/unread/archived)
- **Estimation:** 0.5 jour

**1.2.2 - Créer Get Conversations Use Case**
- **Fichier:** `/lib/domain/usecases/messaging/get_conversations.dart`
- **Code:**
```dart
class GetConversations implements UseCase<List<Conversation>, GetConversationsParams> {
  final MessagingRepository repository;

  GetConversations(this.repository);

  @override
  Future<Either<Failure, List<Conversation>>> call(GetConversationsParams params) async {
    return await repository.getConversations(
      userId: params.userId,
      filter: params.filter,
    );
  }
}

class GetConversationsParams extends Equatable {
  final String userId;
  final ConversationFilter filter;

  const GetConversationsParams({
    required this.userId,
    this.filter = ConversationFilter.all,
  });

  @override
  List<Object> get props => [userId, filter];
}

enum ConversationFilter { all, unread, archived }
```
- **Tests:** `/test/domain/usecases/messaging/get_conversations_test.dart`
- **Estimation:** 0.5 jour

**1.2.3 - Implémenter Conversations Page UI**
- **Fichier:** `/lib/presentation/pages/conversations/conversations_page.dart`
- **Composants:**
  - Liste conversations avec pagination
  - Carte conversation (photo, nom, dernier message, badge unread)
  - Pull-to-refresh
  - Tabs filtres (Tous/Non lus/Archivés)
  - Empty state
  - Swipe actions (archive/delete)
  - Indicateur online status
- **Widgets à affiner:**
  - `ConversationCard` - Améliorer avec badges, timestamps
  - `OnlineIndicator` - Point vert/gris
- **Estimation:** 0.75 jour

**1.2.4 - Tests Conversations**
- **Fichiers:**
  - `/test/presentation/blocs/conversations/conversations_bloc_test.dart`
  - `/test/presentation/pages/conversations/conversations_page_test.dart`
- **Scénarios:**
  - Chargement conversations avec vrai userId
  - Filtrage par statut
  - Pull-to-refresh
  - Navigation vers chat
  - Gestion erreurs
- **Estimation:** 0.25 jour

**DoD Tâche 1.2:**
- ✅ UserId dynamique (plus de hardcoded)
- ✅ Conversations listées correctement
- ✅ Filtres fonctionnels
- ✅ Navigation vers chat fluide
- ✅ Tests >80%

---

### 🎯 TÂCHE 1.3: Use Cases Auth Critiques (2 jours)

#### Sous-tâches

**1.3.1 - Verify Email Use Case**
- **Fichier:** `/lib/domain/usecases/auth/verify_email.dart`
- **Code:**
```dart
class VerifyEmail implements UseCase<void, VerifyEmailParams> {
  final AuthRepository repository;

  VerifyEmail(this.repository);

  @override
  Future<Either<Failure, void>> call(VerifyEmailParams params) async {
    return await repository.verifyEmail(params.token);
  }
}

class VerifyEmailParams extends Equatable {
  final String token;
  const VerifyEmailParams({required this.token});

  @override
  List<Object> get props => [token];
}
```
- **Intégration AuthBloc:** Ajouter event `EmailVerificationRequested`
- **Tests:** `/test/domain/usecases/auth/verify_email_test.dart`
- **Estimation:** 0.5 jour

**1.3.2 - Update Password Use Case**
- **Fichier:** `/lib/domain/usecases/auth/update_password.dart`
- **Code:**
```dart
class UpdatePassword implements UseCase<void, UpdatePasswordParams> {
  final AuthRepository repository;

  UpdatePassword(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdatePasswordParams params) async {
    return await repository.updatePassword(
      oldPassword: params.oldPassword,
      newPassword: params.newPassword,
    );
  }
}

class UpdatePasswordParams extends Equatable {
  final String oldPassword;
  final String newPassword;

  const UpdatePasswordParams({
    required this.oldPassword,
    required this.newPassword,
  });

  @override
  List<Object> get props => [oldPassword, newPassword];
}
```
- **UI:** Ajouter page `/lib/presentation/pages/auth/change_password_page.dart`
- **Tests:** `/test/domain/usecases/auth/update_password_test.dart`
- **Estimation:** 0.75 jour

**1.3.3 - Delete Account Use Case**
- **Fichier:** `/lib/domain/usecases/auth/delete_account.dart`
- **Code:**
```dart
class DeleteAccount implements UseCase<void, DeleteAccountParams> {
  final AuthRepository repository;

  DeleteAccount(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteAccountParams params) async {
    return await repository.deleteAccount(
      password: params.password,
      reason: params.reason,
    );
  }
}

class DeleteAccountParams extends Equatable {
  final String password;
  final String? reason;

  const DeleteAccountParams({
    required this.password,
    this.reason,
  });

  @override
  List<Object?> get props => [password, reason];
}
```
- **Intégration SettingsBloc:** Remplacer TODO par vrai use case
- **Tests:** `/test/domain/usecases/auth/delete_account_test.dart`
- **Estimation:** 0.75 jour

**DoD Tâche 1.3:**
- ✅ 3 use cases créés avec tests
- ✅ Intégration dans BLoCs respectifs
- ✅ UI pour change password
- ✅ Tests coverage >85%

---

### 🎯 TÂCHE 1.4: Settings Backend Réel (1 jour)

#### Sous-tâches

**1.4.1 - Compléter SettingsRepository**
- **Fichier:** `/lib/data/repositories/settings_repository_impl.dart`
- **Modifications:**
  - ❌ Retirer toutes les données mockées
  - ✅ Implémenter vrais appels SettingsApi
  - ✅ Ajouter persistence locale (SharedPreferences)
  - ✅ Ajouter cache avec TTL
- **Estimation:** 0.5 jour

**1.4.2 - Corriger SettingsBloc**
- **Fichier:** `/lib/presentation/blocs/settings/settings_bloc.dart`
- **Modifications:**
  - ✅ Utiliser vrai repository
  - ✅ Ajouter gestion erreurs réseau
  - ✅ Ajouter états loading/success/error
  - ✅ Implémenter DeleteAccount avec use case
- **Estimation:** 0.25 jour

**1.4.3 - Tests Settings**
- **Fichiers:**
  - `/test/data/repositories/settings_repository_test.dart`
  - `/test/presentation/blocs/settings/settings_bloc_test.dart`
- **Scénarios:**
  - Update notification preferences
  - Update privacy settings
  - Delete account avec confirmation
  - Gestion erreurs backend
- **Estimation:** 0.25 jour

**DoD Tâche 1.4:**
- ✅ Settings sauvegardés en backend
- ✅ Modifications persistées
- ✅ Gestion erreurs robuste
- ✅ Tests >75%

---

### 🎯 TÂCHE 1.5: Refactoring Bottom Navigation (1 jour)

#### Sous-tâches

**1.5.1 - Créer Composant Réutilisable**
- **Fichier:** `/lib/presentation/widgets/navigation/app_scaffold.dart`
- **Code:**
```dart
class AppScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AppScaffold({
    Key? key,
    required this.body,
    required this.currentIndex,
    this.title,
    this.actions,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title != null
          ? AppBar(title: Text(title!), actions: actions)
          : null,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: HIVBottomNavigation(
        currentIndex: currentIndex,
        onTap: (index) => _handleNavigation(context, index),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/discovery');
        break;
      case 1:
        context.go('/matches');
        break;
      case 2:
        context.go('/conversations');
        break;
      case 3:
        context.go('/feed');
        break;
      case 4:
        context.go('/resources');
        break;
    }
  }
}
```
- **Estimation:** 0.5 jour

**1.5.2 - Remplacer dans toutes les pages**
- **Fichiers à modifier:**
  - `discovery_page.dart`
  - `matches_page.dart`
  - `conversations_page.dart`
  - `feed_page.dart`
  - `resources_page.dart`
- **Changement:**
```dart
// Avant
return Scaffold(
  body: ...,
  bottomNavigationBar: HIVBottomNavigation(...),
);

// Après
return AppScaffold(
  currentIndex: 0, // Index de la page courante
  body: ...,
);
```
- **Estimation:** 0.5 jour

**DoD Tâche 1.5:**
- ✅ Composant AppScaffold créé
- ✅ Toutes pages utilisent AppScaffold
- ✅ Navigation fluide
- ✅ Code dupliqué éliminé

---

### 🎯 TÂCHE 1.6: Tests BLoCs Critiques (2 jours)

#### Sous-tâches

**1.6.1 - Tests AuthBloc**
- **Fichier:** `/test/presentation/blocs/auth/auth_bloc_test.dart`
- **Scénarios:**
  - App started → check auth state
  - Login success → Authenticated state
  - Login failure → AuthError state
  - Logout → Unauthenticated state
  - Token refresh success
  - Token refresh failure → logout
- **Estimation:** 0.5 jour

**1.6.2 - Tests DiscoveryBloc**
- **Fichier:** `/test/presentation/blocs/discovery/discovery_bloc_test.dart`
- **Scénarios:**
  - Load profiles success
  - Swipe right → like sent
  - Swipe right → match found
  - Swipe left → dislike sent
  - Rewind → previous profile restored
  - Daily limit reached
- **Estimation:** 0.5 jour

**1.6.3 - Tests ProfileBloc**
- **Fichier:** `/test/presentation/blocs/profile/profile_bloc_test.dart`
- **Scénarios:**
  - Load profile success
  - Update profile success
  - Upload photo success
  - Delete photo success
  - Set main photo
  - Block user success
- **Estimation:** 0.5 jour

**1.6.4 - Tests MatchesBloc (nouveau)**
- **Fichier:** `/test/presentation/blocs/matches/matches_bloc_test.dart`
- **Scénarios:**
  - Load matches success
  - Filter matches by status
  - Search matches by name
  - Delete match with confirmation
  - Load more matches pagination
- **Estimation:** 0.5 jour

**DoD Tâche 1.6:**
- ✅ Tests unitaires pour 4 BLoCs critiques
- ✅ Coverage >85% sur ces BLoCs
- ✅ Tous les tests passent
- ✅ Mocking propre avec mocktail

---

### 📊 LIVRABLES SPRINT 1

**Code:**
- ✅ Matches page complète et fonctionnelle
- ✅ Conversations page complète
- ✅ 6 Use Cases créés (GetMatches, DeleteMatch, GetConversations, VerifyEmail, UpdatePassword, DeleteAccount)
- ✅ Settings connecté au backend réel
- ✅ AppScaffold réutilisable
- ✅ Tests unitaires BLoCs critiques

**Documentation:**
- ✅ README mis à jour avec nouvelles features
- ✅ Documentation inline pour code complexe

**Démo:**
- ✅ Flux complet: Login → Discovery → Swipe → Match → Voir Matches → Ouvrir Conversation → Chat
- ✅ Settings modifiés et sauvegardés
- ✅ Navigation fluide sans bugs

---

## 🔧 SPRINT 2: ROBUSTESSE & QUALITÉ (2 semaines)

**Objectif:** Stabiliser l'app, ajouter support offline, compléter Use Cases, optimiser performances

### 📊 Métriques de Succès Sprint 2
- ✅ Tous Use Cases Match créés
- ✅ Upload médias fonctionnel avec compression
- ✅ App fonctionne offline avec cache
- ✅ Notifications push complètes
- ✅ Images optimisées (compression automatique)
- ✅ Tests coverage >70% global

---

### 🎯 TÂCHE 2.1: Use Cases Match Complets (3 jours)

#### Sous-tâches

**2.1.1 - Dislike Profile Use Case**
- **Fichier:** `/lib/domain/usecases/match/dislike_profile.dart`
- **Code similaire à** `like_profile.dart`
- **Estimation:** 0.25 jour

**2.1.2 - Rewind Swipe Use Case**
- **Fichier:** `/lib/domain/usecases/match/rewind_swipe.dart`
- **Estimation:** 0.5 jour

**2.1.3 - Get Likes Received Use Case**
- **Fichier:** `/lib/domain/usecases/match/get_likes_received.dart`
- **Estimation:** 0.5 jour

**2.1.4 - Update Filters Use Case**
- **Fichier:** `/lib/domain/usecases/match/update_filters.dart`
- **Estimation:** 0.5 jour

**2.1.5 - Intégration dans DiscoveryBloc**
- **Fichier:** `/lib/presentation/blocs/discovery/discovery_bloc.dart`
- **Modifications:** Utiliser use cases au lieu de repository direct
- **Estimation:** 1 jour

**2.1.6 - Tests Use Cases Match**
- **Fichiers:** Tests pour chaque use case
- **Estimation:** 0.25 jour

**DoD Tâche 2.1:**
- ✅ 4 use cases Match créés
- ✅ DiscoveryBloc utilise use cases
- ✅ Tests >85%

---

### 🎯 TÂCHE 2.2: Media Upload & Compression (2 jours)

#### Sous-tâches

**2.2.1 - Créer MediaRepository**
- **Fichier:** `/lib/data/repositories/media_repository.dart`
- **Fonctionnalités:**
  - Compression images (package: `flutter_image_compress`)
  - Resize automatique
  - Upload Firebase Storage
  - Progress tracking
  - Retry logic
- **Estimation:** 1 jour

**2.2.2 - Upload Photo Use Case**
- **Fichier:** `/lib/domain/usecases/profile/upload_photo.dart`
- **Code:**
```dart
class UploadPhoto implements UseCase<Photo, UploadPhotoParams> {
  final ProfileRepository profileRepository;
  final MediaRepository mediaRepository;

  UploadPhoto(this.profileRepository, this.mediaRepository);

  @override
  Future<Either<Failure, Photo>> call(UploadPhotoParams params) async {
    // 1. Compress image
    final compressedResult = await mediaRepository.compressImage(
      params.imageFile,
      quality: 80,
      maxWidth: 1080,
    );

    if (compressedResult.isLeft()) {
      return Left(compressedResult.fold((l) => l, (r) => throw Exception()));
    }

    final compressedFile = compressedResult.getOrElse(() => throw Exception());

    // 2. Upload to storage
    final uploadResult = await mediaRepository.uploadImage(
      compressedFile,
      path: 'profiles/${params.userId}/photos',
      onProgress: params.onProgress,
    );

    if (uploadResult.isLeft()) {
      return Left(uploadResult.fold((l) => l, (r) => throw Exception()));
    }

    final photoUrl = uploadResult.getOrElse(() => '');

    // 3. Save to profile
    return await profileRepository.uploadPhoto(
      userId: params.userId,
      photoUrl: photoUrl,
      caption: params.caption,
    );
  }
}
```
- **Estimation:** 0.5 jour

**2.2.3 - Intégrer dans ProfileBloc**
- **Modifications:**
  - Utiliser UploadPhoto use case
  - Ajouter stream progress upload
  - Afficher progress bar UI
- **Estimation:** 0.5 jour

**DoD Tâche 2.2:**
- ✅ MediaRepository créé
- ✅ Images compressées automatiquement
- ✅ Upload avec progress
- ✅ Tests >75%

---

### 🎯 TÂCHE 2.3: Offline Support (3 jours)

#### Sous-tâches

**2.3.1 - Créer CacheRepository**
- **Fichier:** `/lib/data/repositories/cache_repository.dart`
- **Package:** Utiliser `hive_flutter` (déjà dans pubspec)
- **Fonctionnalités:**
  - Cache profiles découverts
  - Cache conversations
  - Cache messages récents
  - TTL configurable
  - Invalidation automatique
- **Estimation:** 1.5 jour

**2.3.2 - Intégrer Cache dans Repositories**
- **Fichiers à modifier:**
  - `profile_repository_impl.dart` - Cache profiles
  - `match_repository_impl.dart` - Cache discovery profiles
  - `message_repository_impl.dart` - Cache messages
- **Pattern:**
```dart
@override
Future<Either<Failure, Profile>> getProfile(String userId) async {
  try {
    // 1. Check cache first
    final cachedProfile = await cacheRepository.getProfile(userId);
    if (cachedProfile != null && !cachedProfile.isExpired) {
      return Right(cachedProfile);
    }

    // 2. Fetch from API
    final profile = await profileApi.getProfile(userId);

    // 3. Update cache
    await cacheRepository.cacheProfile(profile);

    return Right(profile);
  } on ServerException {
    // 4. Return cached data if offline
    final cachedProfile = await cacheRepository.getProfile(userId);
    if (cachedProfile != null) {
      return Right(cachedProfile);
    }
    return Left(ServerFailure());
  }
}
```
- **Estimation:** 1 jour

**2.3.3 - UI Offline Indicators**
- **Widgets:**
  - `OfflineBanner` - Bannière "Mode hors ligne"
  - `CachedIndicator` - Badge "Données en cache"
- **Intégration:** Ajouter dans AppScaffold
- **Estimation:** 0.5 jour

**DoD Tâche 2.3:**
- ✅ CacheRepository fonctionnel
- ✅ 3 repositories utilisent cache
- ✅ App utilisable offline
- ✅ Indicateurs visuels offline

---

### 🎯 TÂCHE 2.4: Notifications Push Complètes (2 jours)

#### Sous-tâches

**2.4.1 - Créer NotificationsBloc**
- **Fichier:** `/lib/presentation/blocs/notifications/notifications_bloc.dart`
- **Events:**
  - `NotificationReceived`
  - `NotificationTapped`
  - `LoadNotificationHistory`
  - `MarkNotificationAsRead`
  - `ClearAllNotifications`
- **States:**
  - `NotificationsLoaded`
  - `NotificationReceived` (avec badge count)
- **Estimation:** 0.75 jour

**2.4.2 - Service FCM Complet**
- **Fichier:** `/lib/core/services/firebase_messaging_service.dart`
- **Fonctionnalités:**
  - Initialization FCM
  - Handle foreground messages
  - Handle background messages
  - Handle notification tap
  - Deep linking depuis notifications
  - Badge count management
- **Estimation:** 0.75 jour

**2.4.3 - UI Notifications**
- **Fichier:** `/lib/presentation/pages/notifications/notifications_page.dart`
- **Composants:**
  - Liste notifications
  - Badge unread count
  - Mark as read
  - Navigation depuis notification
- **Estimation:** 0.5 jour

**DoD Tâche 2.4:**
- ✅ NotificationsBloc créé
- ✅ FCM fully functional
- ✅ Notifications page complète
- ✅ Deep linking fonctionnel

---

### 🎯 TÂCHE 2.5: Widgets Manquants (2 jours)

#### Sous-tâches

**2.5.1 - PhotoGrid Widget**
- **Fichier:** `/lib/presentation/widgets/profile/photo_grid.dart`
- **Features:**
  - Grille 2x3 photos
  - Drag & drop reorder
  - Set main photo
  - Delete photo
  - Upload placeholder
- **Estimation:** 0.75 jour

**2.5.2 - MatchesGrid Widget**
- **Fichier:** `/lib/presentation/widgets/matches/matches_grid.dart`
- **Features:**
  - Grille matches avec photos
  - Badge "New" pour nouveaux matches
  - Tap pour ouvrir chat
- **Estimation:** 0.5 jour

**2.5.3 - OnlineIndicator Widget**
- **Fichier:** `/lib/presentation/widgets/common/online_indicator.dart`
- **Features:**
  - Point vert si online
  - Point gris si offline
  - Timestamp last active
- **Estimation:** 0.25 jour

**2.5.4 - VerificationBadge Widget**
- **Fichier:** `/lib/presentation/widgets/common/verification_badge.dart`
- **Features:**
  - Icône badge vérifié
  - Tooltip "Profil vérifié"
  - Animation subtile
- **Estimation:** 0.25 jour

**2.5.5 - InterestsChips Widget**
- **Fichier:** `/lib/presentation/widgets/profile/interests_chips.dart`
- **Features:**
  - Chips intérêts
  - Sélection/désélection
  - Limite à 3 intérêts
- **Estimation:** 0.25 jour

**DoD Tâche 2.5:**
- ✅ 5 widgets créés
- ✅ Utilisés dans pages appropriées
- ✅ Responsive et accessibles

---

### 📊 LIVRABLES SPRINT 2

**Code:**
- ✅ 8 Use Cases Match créés
- ✅ MediaRepository avec compression
- ✅ CacheRepository avec offline support
- ✅ NotificationsBloc complet
- ✅ 5 widgets réutilisables

**Qualité:**
- ✅ Tests coverage >70%
- ✅ Pas d'erreurs analyse statique
- ✅ Performance améliorée (compression images)

**Démo:**
- ✅ Upload photo rapide avec compression visible
- ✅ App fonctionne offline (mode avion)
- ✅ Notifications push reçues et tapables
- ✅ UI enrichie avec nouveaux widgets

---

## 🚀 SPRINT 3: FEATURES AVANCÉES & POLISH (2 semaines)

**Objectif:** Finaliser features avancées, optimiser performances, préparer production

### 📊 Métriques de Succès Sprint 3
- ✅ Use Cases Resources créés
- ✅ Analytics tracking actif
- ✅ Crashlytics configuré
- ✅ CallBloc basique fonctionnel
- ✅ Deep linking complet
- ✅ Tests E2E critiques
- ✅ App production-ready

---

### 🎯 TÂCHE 3.1: Use Cases Resources (2 jours)

#### Sous-tâches

**3.1.1 - Get Resources Use Case**
- **Fichier:** `/lib/domain/usecases/resources/get_resources.dart`
- **Estimation:** 0.5 jour

**3.1.2 - Get Feed Posts Use Case**
- **Fichier:** `/lib/domain/usecases/resources/get_feed_posts.dart`
- **Estimation:** 0.5 jour

**3.1.3 - Like Post Use Case**
- **Fichier:** `/lib/domain/usecases/resources/like_post.dart`
- **Estimation:** 0.25 jour

**3.1.4 - Comment Post Use Case**
- **Fichier:** `/lib/domain/usecases/resources/comment_post.dart`
- **Estimation:** 0.25 jour

**3.1.5 - Intégration FeedBloc/ResourcesBloc**
- **Modifications:** Utiliser use cases
- **Estimation:** 0.5 jour

**DoD Tâche 3.1:**
- ✅ 4 use cases Resources créés
- ✅ BLoCs utilisent use cases
- ✅ Tests >80%

---

### 🎯 TÂCHE 3.2: Analytics & Crashlytics (2 jours)

#### Sous-tâches

**3.2.1 - Créer AnalyticsRepository**
- **Fichier:** `/lib/data/repositories/analytics_repository.dart`
- **Package:** `firebase_analytics`
- **Events à tracker:**
  - User signup
  - User login
  - Profile created
  - Profile updated
  - Photo uploaded
  - Swipe action (like/dislike)
  - Match found
  - Message sent
  - Subscription purchased
  - Resource viewed
- **Estimation:** 1 jour

**3.2.2 - Intégrer Analytics dans App**
- **Fichiers à modifier:**
  - `auth_bloc.dart` - Track login/signup
  - `discovery_bloc.dart` - Track swipes/matches
  - `profile_bloc.dart` - Track profile updates
  - `premium_bloc.dart` - Track purchases
- **Estimation:** 0.5 jour

**3.2.3 - Configurer Crashlytics**
- **Fichier:** `main.dart` (déjà présent)
- **Améliorations:**
  - Custom error keys (userId, screen, action)
  - Breadcrumbs navigation
  - Non-fatal errors tracking
- **Estimation:** 0.5 jour

**DoD Tâche 3.2:**
- ✅ AnalyticsRepository créé
- ✅ Events critiques trackés
- ✅ Crashlytics avec contexte riche

---

### 🎯 TÂCHE 3.3: CallBloc & WebRTC Basique (4 jours)

#### Sous-tâches

**3.3.1 - Créer CallBloc**
- **Fichier:** `/lib/presentation/blocs/call/call_bloc.dart`
- **Events:**
  - `InitiateCall`
  - `AnswerCall`
  - `DeclineCall`
  - `EndCall`
  - `ToggleMute`
  - `ToggleVideo`
  - `ToggleSpeaker`
- **States:**
  - `CallIdle`
  - `CallInitiating`
  - `CallRinging`
  - `CallConnected`
  - `CallEnded`
- **Estimation:** 1 jour

**3.3.2 - Service WebRTC**
- **Fichier:** `/lib/core/services/webrtc_service.dart`
- **Package:** `flutter_webrtc`
- **Fonctionnalités:**
  - Create offer SDP
  - Create answer SDP
  - Add ICE candidates
  - Handle media streams
  - Audio/Video toggle
- **Estimation:** 1.5 jour

**3.3.3 - UI Appel**
- **Fichier:** `/lib/presentation/pages/call/call_page.dart`
- **Composants:**
  - Incoming call screen
  - Calling screen
  - In-call screen
  - Controls (mute, video, speaker, end)
- **Estimation:** 1 jour

**3.3.4 - Tests Call**
- **Fichier:** `/test/presentation/blocs/call/call_bloc_test.dart`
- **Scénarios:**
  - Initiate call
  - Answer call
  - Decline call
  - Toggle mute/video
- **Estimation:** 0.5 jour

**DoD Tâche 3.3:**
- ✅ CallBloc créé
- ✅ WebRTC service fonctionnel
- ✅ UI appel complète
- ✅ Tests >70%

---

### 🎯 TÂCHE 3.4: Deep Linking (1 jour)

#### Sous-tâches

**3.4.1 - Configuration Deep Links**
- **Android:** `AndroidManifest.xml`
- **iOS:** `Info.plist`
- **URLs:**
  - `hivmeet://profile/{userId}`
  - `hivmeet://match/{matchId}`
  - `hivmeet://chat/{conversationId}`
  - `hivmeet://resource/{resourceId}`
- **Estimation:** 0.5 jour

**3.4.2 - Gestion Deep Links dans App**
- **Fichier:** `/lib/core/config/deep_link_handler.dart`
- **Intégration:** go_router redirect
- **Estimation:** 0.5 jour

**DoD Tâche 3.4:**
- ✅ Deep links configurés
- ✅ Navigation depuis liens externe
- ✅ Gestion auth required

---

### 🎯 TÂCHE 3.5: Optimisations Performance (2 jours)

#### Sous-tâches

**3.5.1 - Optimisation Images**
- **Modifications:**
  - Utiliser `CachedNetworkImage` partout
  - Lazy loading grilles
  - Placeholder optimisés
  - Fade-in animations
- **Estimation:** 0.75 jour

**3.5.2 - Optimisation BLoCs**
- **Modifications:**
  - Debouncing search inputs
  - Throttling scroll events
  - Cancel subscriptions properly
  - Dispose streams
- **Estimation:** 0.5 jour

**3.5.3 - Optimisation Navigation**
- **Modifications:**
  - Preload pages adjacentes
  - Cache routes
  - Optimistic navigation
- **Estimation:** 0.5 jour

**3.5.4 - Bundle Size Optimization**
- **Actions:**
  - Analyser bundle size
  - Tree shaking
  - Code splitting
  - Remove unused dependencies
- **Estimation:** 0.25 jour

**DoD Tâche 3.5:**
- ✅ Temps chargement pages <1s
- ✅ Scroll fluide 60 FPS
- ✅ Bundle size réduit >20%

---

### 🎯 TÂCHE 3.6: Tests End-to-End (3 jours)

#### Sous-tâches

**3.6.1 - Tests E2E Auth Flow**
- **Fichier:** `/integration_test/auth_flow_test.dart`
- **Scénarios:**
  - Register → Verify → Login → Logout
  - Forgot password
  - Social login (Google/Apple)
- **Estimation:** 1 jour

**3.6.2 - Tests E2E Discovery → Match → Chat**
- **Fichier:** `/integration_test/matching_flow_test.dart`
- **Scénarios:**
  - Load discovery → Swipe → Match → Open chat → Send message
  - Super like → Match
  - Rewind
- **Estimation:** 1 jour

**3.6.3 - Tests E2E Premium**
- **Fichier:** `/integration_test/premium_flow_test.dart`
- **Scénarios:**
  - View plans → Select → Payment → Activated
  - Use boost
  - Use super like
- **Estimation:** 1 jour

**DoD Tâche 3.6:**
- ✅ 3 suites E2E
- ✅ Tous tests passent
- ✅ CI/CD intégré

---

### 📊 LIVRABLES SPRINT 3

**Code:**
- ✅ 4 Use Cases Resources
- ✅ AnalyticsRepository
- ✅ CallBloc + WebRTC
- ✅ Deep linking
- ✅ Optimisations performances

**Qualité:**
- ✅ Tests E2E critiques
- ✅ Crashlytics configuré
- ✅ Analytics tracking

**Production:**
- ✅ App production-ready
- ✅ Performance optimisée
- ✅ Monitoring actif

---

## 📈 STRATÉGIE D'EXÉCUTION

### Ordre de Priorité des Tâches

**CRITIQUE (Bloquant MVP):**
1. ✅ Matches Page (Sprint 1)
2. ✅ Conversations Page (Sprint 1)
3. ✅ Settings Backend (Sprint 1)

**HAUTE (Qualité & Robustesse):**
4. ✅ Use Cases critiques (Sprint 1-2)
5. ✅ Media Upload (Sprint 2)
6. ✅ Offline Support (Sprint 2)
7. ✅ Notifications (Sprint 2)

**MOYENNE (Features Avancées):**
8. ✅ Resources Use Cases (Sprint 3)
9. ✅ Analytics (Sprint 3)
10. ✅ CallBloc (Sprint 3)

**BASSE (Polish):**
11. ✅ Deep Linking (Sprint 3)
12. ✅ Optimisations (Sprint 3)

### Gestion des Risques

**Risque: Manque de temps**
- **Mitigation:** Prioriser strictement, MVP d'abord
- **Fallback:** Reporter Sprint 3 features avancées

**Risque: Bugs critiques découverts**
- **Mitigation:** Tests unitaires systématiques
- **Fallback:** Buffer 20% temps pour bugfix

**Risque: APIs backend changent**
- **Mitigation:** Vérifier alignment avec backend
- **Fallback:** Adapter rapidement via repositories

---

## 🎯 DÉFINITION DE "PRODUCTION READY"

L'application est considérée production-ready si:

**Fonctionnel:**
- ✅ Flux complet Auth → Discovery → Match → Chat fonctionne
- ✅ Toutes pages principales complètes (0 placeholder)
- ✅ Pas de crashs sur flows critiques

**Qualité:**
- ✅ Tests coverage >70% global
- ✅ Tests E2E critiques passent
- ✅ 0 erreurs analyse statique
- ✅ Performance acceptable (loading <2s, scroll fluide)

**Monitoring:**
- ✅ Analytics tracking actif
- ✅ Crashlytics configuré
- ✅ Error reporting fonctionnel

**Sécurité:**
- ✅ Tokens sécurisés
- ✅ Données sensibles chiffrées
- ✅ Pas de secrets hardcodés

---

## 📅 TIMELINE RECOMMANDÉ

### Avec 2 Développeurs (6-7 semaines)

**Semaines 1-2:** Sprint 1 (MVP)
**Semaines 3-4:** Sprint 2 (Robustesse)
**Semaines 5-6:** Sprint 3 (Features Avancées)
**Semaine 7:** Buffer & Polish

### Avec 1 Développeur (13 semaines)

**Semaines 1-4:** Sprint 1 (MVP) - Double durée
**Semaines 5-8:** Sprint 2 (Robustesse) - Double durée
**Semaines 9-12:** Sprint 3 (Features Avancées) - Double durée
**Semaine 13:** Buffer & Polish

---

## 🚀 PROCHAINES ÉTAPES IMMÉDIATES

**Aujourd'hui:**
1. ✅ Valider ce plan avec stakeholders
2. ✅ Créer board Jira/Trello avec toutes tâches
3. ✅ Setup environnement de test

**Demain:**
4. ✅ Commencer Tâche 1.1 (Matches Page)
5. ✅ Daily standup routine

**Cette semaine:**
6. ✅ Compléter Tâche 1.1 + 1.2
7. ✅ Code review process
8. ✅ Premier déploiement staging

---

**Plan créé par:** Claude (IA)
**Date:** 20 novembre 2025
**Prêt pour exécution:** ✅ OUI

Ce plan est conçu pour être exécuté par moi-même (Claude) de manière optimale, avec des tâches atomiques, des estimations réalistes, et une approche méthodique garantissant un maximum de réussite.
