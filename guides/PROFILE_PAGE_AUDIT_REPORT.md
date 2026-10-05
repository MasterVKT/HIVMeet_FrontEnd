# Rapport d'audit complet de la page Profil

Date d'audit: 2026-08-16  
Portee demandee: analyse et reporting uniquement, sans correction fonctionnelle.  
Perimetre etendu: hub Profil, sous-fonctionnalites atteignables depuis le hub, onboarding `CreateProfile`, page `Settings` residuelle, page `PaymentPage` (supprimee dans cette session), et verification end-to-end des contrats backend Django.  
Fichier produit: `guides/PROFILE_PAGE_AUDIT_REPORT.md`

## 1. Synthese executive

La page Profil est actuellement structuree comme un hub central qui charge le profil courant, affiche les informations principales de l'utilisateur, puis donne acces aux sous-flux suivants: edition du profil, photos, verification, confidentialite, notifications, utilisateurs bloques, premium, likes recus, donnees/compte, pages legales et deconnexion.

Les changements recents sont globalement coherents avec les exigences produit:

- le bouton engrenage n'est plus present dans la page Profil;
- les acces utiles auparavant presents dans Settings sont exposes directement dans le hub Profil;
- l'edition du genre utilisateur n'est plus disponible dans `ProfileEditPage`;
- les champs directs latitude/longitude ne sont plus disponibles dans `ProfileEditPage`;
- le selfie de verification force maintenant `ImageSource.camera`;
- les nouvelles cles i18n Profil sont presentes en FR et EN;
- les fichiers Profil principaux passent l'analyse statique ciblee sans erreur.

Le hub Profil principal compile et ses routes directes sont enregistrees. Cependant, l'audit detecte plusieurs anomalies ou risques a traiter dans une future session de correction:

1. `LikesReceivedPage` affiche maintenant un etat erreur/premium, mais le backend retourne 403 sans timestamp du like.
2. `VerificationPage` supporte PDF pour les documents d'identite et medicaux. Le code mort du wizard de verification (steps + VerificationBloc) a ete supprime dans cette session.
3. Plusieurs sous-pages Profil peuvent rester en loader si les donnees auxiliaires ne sont pas chargees.
4. ~~`CreateProfilePage` ne persiste rien ; `_createProfile()` est un TODO vide.~~ Corrige dans cette session.
5. ~~`PremiumPage` plantera a l'execution car `PremiumBloc` n'est pas enregistre dans `get_it`.~~ Corrige dans cette session.
6. `PaymentPage` a ete supprimee ; la route `/payment` a ete retiree de `AppRouter`.
7. ~~La page Settings existe encore, redondante avec le hub, et `SettingsBloc` est un mock.~~ Corrigé dans cette session.
8. Plusieurs destinations accessibles depuis Profil contiennent encore des textes visibles hardcodes et ne respectent pas totalement l'i18n FR/EN.
9. Des flux recents sont corrects cote UI, mais ne sont pas verrouilles cote domaine/backend: `UpdateProfileEvent` et le repository acceptent encore `gender`, `latitude` et `longitude` si un autre appel frontend les fournit.

Aucune correction n'a ete appliquee pendant l'audit initial de ce rapport.

**Corrections appliquees dans cette session (2026-08-16):**

1. `PremiumBloc` est maintenant enregistre dans `injection.dart` avec son `PremiumRepositoryImpl`, `SubscriptionsApi`, `PaymentService` et un `Dio` dedie aux paiements externes.
2. `CreateProfilePage` implemente desormais `_createProfile()` : upload de la photo principale, mise a jour du profil (bio, interets, ville, pays, type de relation, preferences de recherche), mise a jour de la localisation GPS, puis navigation vers `/discovery`.
3. `PremiumPage` est connectee au flux d'achat : le bouton "S'abonner" emet `PurchasePremium(planId)` au lieu d'afficher un snackbar inactif. Les nouvelles cles `premium.purchase_success` et `premium.purchase_error` ont ete ajoutees en FR/EN.
4. `PaymentPage` et la route `/payment` ont ete supprimees de `AppRouter`.
5. `AboutPage` est desormais localise : le nom d'application utilise `about.app_name` et les fallbacks de version/build sont passes a des chaines vides (localise via `about.version`).
6. Le code mort du wizard de verification (`lib/presentation/blocs/verification/*` et `lib/presentation/pages/verification/steps/*`) a ete supprime dans cette session. La route `/verification` utilise `VerificationPage` avec `ProfileBloc`, qui supporte deja PDF pour identity/medical.

**Nouveaux constats cles depuis la derniere version du rapport (2026-05-17):**

1. Le backend Django a ete lu directement : 17 endpoints Profile/Settings/Premium ont ete verifies dans `d:\Projets\HIVMeet\env\hivmeet_backend`.
2. `LikesReceivedPage` a ete ameliore : il gere maintenant explicitement `MatchesError` avec un CTA premium ou retry. Cependant, le backend retourne 403 premium et la liste ne contient pas la date du like.
3. La route `/profile/:id` a ete corrigee : elle pointe maintenant vers `PublicProfilePage(userId: userId)`, pas vers le profil courant. Le rapport initial indiquait un TODO obsolete.
4. ~~`SettingsPage` a ete nettoyee : les faux textes/TODOs ont ete remplaces par des liens localises vers les sous-flux Profil. Elle reste cependant redondante avec le hub.~~ `SettingsPage`, `SettingsBloc` et etats/evenements associes, la route `/settings` et le test widget obsolete ont ete supprimes dans cette session.
5. `PaymentPage` a ete supprimee et la route `/payment` retiree de `AppRouter` dans cette session.
6. `PremiumBloc` est maintenant enregistre dans `injection.dart` (corrige dans cette session).
7. `CreateProfilePage` implemente `_createProfile()` (corrige dans cette session).
8. `SettingsPage`, `SettingsBloc`, `SettingsRepository`, etats/evenements associes, la route `/settings` et le test widget obsolete ont ete supprimes dans cette session.
9. Le backend upload photo retourne `photo_id`/`url` au lieu de `id`/`photo_url` ; le frontend `_mapPhoto` tolere les deux, mais les documents sont desynchronises.
9. Le backend `delete_photo_view` tente de reassigner `is_main` apres `photo.delete()`, ce qui ne fonctionne pas car l'instance est deja detruite.
10. Les endpoints `export-data` et `delete-account` sont des stubs 202 cote backend.

## 2. Fichiers et surfaces audites

### 2.1 Surfaces directement exposees depuis le hub Profil

- `lib/presentation/pages/profile/profile_detail_page.dart`
- `lib/presentation/pages/profile/profile_edit_page.dart`
- `lib/presentation/pages/profile/profile_photos_page.dart`
- `lib/presentation/pages/profile/profile_privacy_page.dart`
- `lib/presentation/pages/profile/profile_notifications_page.dart`
- `lib/presentation/pages/profile/profile_blocked_users_page.dart`
- `lib/presentation/pages/profile/profile_data_page.dart`
- `lib/presentation/pages/verification/verification_page.dart`
- `lib/presentation/pages/likes_received/likes_received_page.dart`
- `lib/presentation/pages/premium/premium_page.dart`
- `lib/presentation/pages/premium/payment_page.dart` (supprime dans cette session)
- `lib/presentation/pages/about/about_page.dart`
- `lib/presentation/pages/legal/privacy_page.dart`
- `lib/presentation/pages/legal/terms_page.dart`
- `lib/presentation/pages/profile/create_profile.dart`
- ~~`lib/presentation/pages/settings/settings_page.dart`~~ supprime dans cette session

### 2.2 Surfaces d'orchestration, navigation et contrat

- `lib/core/config/routes.dart`
- `lib/presentation/widgets/navigation/app_scaffold.dart`
- `lib/presentation/blocs/profile/profile_bloc.dart`
- `lib/presentation/blocs/profile/profile_event.dart`
- `lib/presentation/blocs/profile/profile_state.dart`
- `lib/presentation/blocs/premium/premium_bloc.dart`
- ~~`lib/presentation/blocs/settings/settings_bloc.dart`~~ supprime dans cette session
- `lib/domain/entities/profile.dart`
- `lib/domain/repositories/profile_repository.dart`
- `lib/domain/usecases/profile/update_profile.dart`
- `lib/data/repositories/profile_repository_impl.dart`
- ~~`lib/data/repositories/settings_repository_impl.dart`~~ supprime dans cette session
- `lib/data/datasources/remote/profile_api.dart`
- `lib/data/datasources/remote/settings_api.dart`
- `lib/injection.dart`
- `assets/translations/fr.json`
- `assets/translations/en.json`
- `guides/PROFILE_BACKEND_SPECIFICATION_FRONTEND.md`
- `API_DOCUMENTATION.md`
- backend Django : `env/hivmeet_backend/profiles/views.py`
- backend Django : `env/hivmeet_backend/profiles/views_premium.py`
- backend Django : `env/hivmeet_backend/profiles/views_settings.py`
- backend Django : `env/hivmeet_backend/profiles/serializers.py`
- backend Django : `env/hivmeet_backend/profiles/urls.py`

### 2.3 Surfaces indirectes observees

- ~~`test/widget_test/settings_page_test.dart`~~ supprime dans cette session
- tests de matching/likes/discovery identifies dans `test/`, mais aucun test dedie a la page Profil actuelle.

## 3. Commandes executees et resultats

### 3.1 Analyse statique ciblee Profil

Commande:

```powershell
& 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe' analyze `
  lib\core\config\routes.dart `
  lib\presentation\pages\profile\profile_detail_page.dart `
  lib\presentation\pages\profile\profile_edit_page.dart `
  lib\presentation\pages\profile\profile_photos_page.dart `
  lib\presentation\pages\profile\profile_privacy_page.dart `
  lib\presentation\pages\profile\profile_notifications_page.dart `
  lib\presentation\pages\profile\profile_blocked_users_page.dart `
  lib\presentation\pages\profile\profile_data_page.dart `
  lib\presentation\pages\verification\verification_page.dart `
  lib\presentation\blocs\profile\profile_bloc.dart `
  lib\presentation\blocs\profile\profile_event.dart `
  lib\presentation\blocs\profile\profile_state.dart `
  lib\data\repositories\profile_repository_impl.dart `
  lib\data\datasources\remote\profile_api.dart `
  lib\data\datasources\remote\settings_api.dart `
  lib\domain\repositories\profile_repository.dart `
  lib\domain\usecases\profile\update_profile.dart
```

Resultat:

- OK.
- `No issues found!`

### 3.2 Analyse statique des destinations secondaires

Commande:

```powershell
& 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe' analyze `
  lib\presentation\pages\likes_received\likes_received_page.dart `
  lib\presentation\pages\premium\premium_page.dart `
  lib\presentation\pages\about\about_page.dart `
  lib\presentation\pages\legal\privacy_page.dart `
  lib\presentation\pages\legal\terms_page.dart `
  lib\presentation\widgets\navigation\app_scaffold.dart `
  ~~lib\presentation\pages\settings\settings_page.dart~~ (supprime dans cette session)
  lib\presentation\pages\profile\create_profile.dart `
  ~~lib\presentation\pages\premium\payment_page.dart~~ (supprime dans cette session)
  ~~lib\presentation\blocs\settings\settings_bloc.dart~~ (supprime dans cette session)
  lib\presentation\blocs\premium\premium_bloc.dart `
  lib\core\config\routes.dart
```

Resultat:

- OK au sens compilation/analyse bloquante.
- 4 infos non bloquantes, toutes liees a `Radio` deprecie (`groupValue`/`onChanged`) dans `premium_page.dart` et `create_profile.dart`;
  - `likes_received_page.dart`: usages de `withOpacity` deprecies (constat initial).
  - ~~`settings_page.dart`: usage de `withOpacity` deprecie (constat initial).~~ Fichier supprime dans cette session.
  - Aucune erreur bloquante dans les nouvelles surfaces (`CreateProfile`, `SettingsBloc`, `PremiumBloc`, routes). `PaymentPage` a ete supprimee.

### 3.3 Analyse statique globale de `lib`

Commande:

```powershell
& 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe' analyze lib
```

Resultat:

- Exit code 0.
- 298 infos detectees, principalement preexistantes: `avoid_print`, `deprecated_member_use`, `use_build_context_synchronously`, etc.
- Aucun warning/error bloquant sur l'ensemble de `lib`.

### 3.4 Validation des traductions

Commandes:

```powershell
Get-Content -Raw assets\translations\fr.json | ConvertFrom-Json | Out-Null
Get-Content -Raw assets\translations\en.json | ConvertFrom-Json | Out-Null
```

Resultat:

- OK.
- Les deux fichiers JSON sont valides.

Commande de parite des cles `profile`:

```powershell
$fr=(Get-Content -Raw assets\translations\fr.json | ConvertFrom-Json).profile.PSObject.Properties.Name
$en=(Get-Content -Raw assets\translations\en.json | ConvertFrom-Json).profile.PSObject.Properties.Name
```

Resultat:

- OK.
- `profile-i18n-key-parity-ok`

### 3.5 Test widget proche de Settings

Commande:

```powershell
& 'C:\flutter\bin\flutter.bat' test test\widget_test\settings_page_test.dart
```

Resultat:

- ~~Non concluant.~~ Le test et le fichier ont ete supprimes dans cette session.

## 4. Architecture observee du flux Profil

### 4.1 Chargement global

`ProfileDetailPage` cree un `ProfileBloc` local et lance `LoadProfile`. Le handler `_onLoadProfile`:

1. emet `ProfileLoading`;
2. charge le profil courant via `GetCurrentProfile`;
3. tente ensuite de charger:
   - statut premium;
   - details de verification;
   - preferences de confidentialite;
   - preferences de notifications;
   - utilisateurs bloques;
4. ignore silencieusement les echecs des donnees auxiliaires;
5. emet un `ProfileLoaded`.

Ce modele donne un hub riche en une seule passe, mais il augmente le cout reseau de la page principale et masque les echecs partiels. Les sous-pages dependent ensuite de la presence de ces donnees dans `ProfileLoaded`.

### 4.2 Mutations

Les mutations passent par `ProfileBloc`:

- edition profil: `UpdateProfileEvent`;
- upload photo: `UploadPhoto`;
- suppression photo: `DeletePhoto`;
- photo principale: `SetMainPhoto`;
- preferences privacy: `SavePrivacyPreferences`;
- preferences notifications: `SaveNotificationPreferences`;
- deblocage utilisateur: `UnblockUser`;
- export donnees: `RequestDataExport`;
- suppression compte: `RequestAccountDeletion`;
- verification documents: `SubmitVerificationDocuments`.

La plupart des mutations rechargent un snapshot complet via `_reloadAfterAction`, ce qui correspond a la recommandation du guide backend. Certaines mutations remplacent seulement une section locale.

### 4.3 Navigation

Les routes directes utilisees par `ProfileDetailPage` sont toutes declarees dans `AppRouter`:

- `/profile/edit`
- `/profile/photos`
- `/verification`
- `/profile/privacy`
- `/profile/notifications`
- `/profile/blocked-users`
- `/premium`
- `/likes-received`
- `/profile/data`
- `/about`
- `/privacy`
- `/terms`
- `/`

La page Settings residuelle contient encore des liens non declares:

- `/settings/change-password`
- `/settings/change-email`
- `/settings/country`
- `/help`
- `/settings/report-issue`

## 5. Inventaire exhaustif du hub Profil principal

### 5.1 AppBar

Element observe:

- titre: `profile.title`;
- plus aucun bouton engrenage;
- pas d'action secondaire.

Etat attendu:

- page Profil lisible comme point d'entree central;
- suppression du bouton Settings conforme a la demande.

Etat observe:

- conforme.
- aucune reference restante a `settings_outlined` ou `context.go('/settings')` dans les pages Profil auditees.

Risque:

- faible.
- ~~la route `/settings` existe toujours, mais n'est plus exposee par le hub Profil.~~ La route `/settings` et le point d'entree Settings ont ete supprimes dans cette session.

### 5.2 Etat de chargement et erreur

Element observe:

- `ProfileLoading` et `ProfileInitial` affichent `HIVLoader`.
- Si aucun `ProfileLoaded` n'est disponible, la page principale affiche `_ErrorPanel` avec bouton `common.retry`.

Etat attendu:

- l'utilisateur doit pouvoir reessayer si le profil ne se charge pas.

Etat observe:

- conforme pour la page principale.
- meilleur que plusieurs sous-pages, qui affichent seulement un loader si `loaded == null`.

Risque:

- faible sur le hub principal.
- moyen sur les sous-pages.

### 5.3 RefreshIndicator

Element observe:

- pull-to-refresh envoie `LoadProfile`.

Etat attendu:

- rafraichissement du profil et des donnees auxiliaires.

Etat observe:

- conforme.
- `LoadProfile` recharge profil, premium, verification, privacy, notifications et blocages.

Risque:

- faible fonctionnellement;
- moyen cote performance, car le hub recharge aussi des sections qui ne sont pas toutes visibles en detail.

### 5.4 En-tete profil

Elements observes:

- photo principale via `OptimizedImage`;
- nom d'affichage via `_displayName`;
- age via `profile.user?.age ?? profile.age`;
- localisation via `_locationText`;
- badge verification;
- badge premium/free.

Etat attendu:

- afficher une identite minimale, respectueuse et non stigmatisante.
- ne pas exposer de localisation precise si masquee.

Etat observe:

- logique correcte globalement.
- `displayLocation` retourne `city` si `showExactLocation == true`, sinon `country`.
- le mapping repository definit `showExactLocation` comme inverse de `hide_exact_location`, donc il respecte l'intention backend.
- `OptimizedImage` gere les URLs vides par placeholder.

Anomalie i18n indirecte:

- `OptimizedImage` affiche le texte hardcode `Pas de photo`, sans cle i18n.
- Ce widget impacte le hub Profil et les photos/blocages.

Risque:

- faible fonctionnellement;
- moyen pour i18n.

### 5.5 Metriques

Elements observes:

- nombre d'interets;
- nombre de photos;
- visibilite visible/masquee.

Etat attendu:

- reflete l'etat courant du profil.

Etat observe:

- conforme pour les champs presents dans `Profile`.
- la visibilite vient de `profile.privacySettings.profileDiscoverable`, pas directement de `loaded.privacyPreferences`.

Risque:

- faible apres reload complet.
- en cas de divergence backend entre `/me/` et `/user-settings/privacy-preferences`, la metrique suit `/me/`.

### 5.6 Section Profil

Actions:

- Modifier le profil -> `/profile/edit`
- Photos -> `/profile/photos`
- Verification -> `/verification`

Etat observe:

- routes declarees.
- navigation techniquement valide.

Risques:

- voir sections 6, 7 et 8 pour les anomalies propres a chaque sous-page.

### 5.7 Section Confidentialite et securite

Actions:

- Confidentialite -> `/profile/privacy`
- Notifications -> `/profile/notifications`
- Utilisateurs bloques -> `/profile/blocked-users`

Etat observe:

- routes declarees.
- navigation techniquement valide.

Risques:

- chargement concurrent/redondant des donnees auxiliaires;
- loader potentiellement infini si preferences absentes;
- voir sections 9, 10 et 11.

### 5.8 Section Premium et donnees

Actions:

- Premium -> `/premium`
- Likes recus -> `/likes-received`
- Donnees et compte -> `/profile/data`

Etat observe:

- routes declarees.
- le texte de la tuile Likes recus informe si premium requis.

Risques:

- la tuile Likes recus reste cliquable meme quand `canSeeLikers` est false;
- la destination peut devenir vide en cas de 403 ou erreur;
- `PremiumPage` est tres minimale et le bouton subscribe est toujours desactive car `_selectedPlan` reste vide.

### 5.9 Section Aide et informations

Actions:

- A propos -> `/about`
- Politique de confidentialite -> `/privacy`
- Conditions d'utilisation -> `/terms`

Etat observe:

- routes declarees.
- les pages existent.

Risques:

- les trois pages contiennent beaucoup de texte hardcode et ne respectent pas l'i18n FR/EN;
- contenu legal date de janvier 2025 et semble statique;
- boutons email/site de `AboutPage` sont TODO et non fonctionnels.

### 5.10 Section Acces au compte

Action:

- Se deconnecter -> dialogue de confirmation -> `LoggedOut` sur `AuthBlocSimple` -> `context.go('/')`.

Etat attendu:

- confirmer puis sortir de la session.

Etat observe:

- conforme structurellement.
- `AuthBlocSimple` est fourni globalement dans `main.dart`; le contexte de Profil peut donc trouver le bloc global.

Risque:

- faible.
- il serait preferable de rediriger explicitement vers une route d'auth/login apres emission de l'etat, mais le splash `/` peut gerer la suite.

## 6. Audit de `ProfileEditPage`

### 6.1 Champs visibles

Champs presents:

- bio;
- ville;
- pays;
- interets;
- tranche d'age;
- distance maximale;
- genres recherches;
- types de relation recherches.

Champs absents conformement a la demande:

- genre utilisateur;
- latitude;
- longitude.

Etat observe:

- conforme a l'exigence UI.
- `UpdateProfileEvent` emis par cette page ne transmet pas `gender`, `latitude` ou `longitude`.

### 6.2 Validation

Validations presentes:

- bio <= `AppLimits.maxBioLength`;
- interets <= `AppLimits.maxInterests`;
- chaque interet <= 50 caracteres;
- age min <= age max;
- distance via slider bornee par `AppLimits.minDistance` et `AppLimits.maxDistance`.

Etat observe:

- conforme au contrat backend pour bio, interets, ages et distance.
- ville/pays ont `maxLength: 100`, conforme au guide.

### 6.3 Payload envoye

Payload construit via `UpdateProfileEvent`:

- `bio`;
- `city`;
- `country`;
- `interests`;
- `relationshipTypesSought`;
- `searchPreferences` avec age min/max, distance, genres recherches, types de relation.

Mapping repository:

- `age_min_preference`;
- `age_max_preference`;
- `distance_max_km`;
- `genders_sought`;
- `relationship_types_sought`;
- `interests`;
- `city`;
- `country`;
- `bio`.

Etat observe:

- conforme au guide backend pour l'edition partielle.

### 6.4 Risques detectes

Risque PE-1: labels des genres recherches non localises dynamiquement.

- Preuve: `Gender.getLabel(value)` est appele sans locale.
- `Gender.getLabel` utilise `locale = 'fr'` par defaut.
- Impact: en locale anglaise, les chips de genre peuvent rester en francais.
- Severite: moyenne i18n.
- Recommandation: brancher `LocalizationService.currentLocale` ou des cles i18n par genre.

Risque PE-2: l'interdiction d'edition du genre n'est verrouillee qu'au niveau UI.

- Preuve: `UpdateProfileEvent`, `UpdateProfileParams` et `ProfileRepository.updateProfile` acceptent encore `gender`.
- Impact: un autre ecran ou un futur appel frontend pourrait encore envoyer `gender`.
- Severite: moyenne produit/securite fonctionnelle.
- Recommandation: retirer ou ignorer `gender` dans le flux update cote frontend, et demander au backend d'ignorer/refuser `gender` sur `PATCH /user-profiles/me/` si le genre doit etre definitif.

Risque PE-3: latitude/longitude restent supportees par les couches internes.

- Preuve: `UpdateProfileEvent`, `UpdateProfileParams`, `ProfileRepository.updateProfile`, `UpdateLocation` et `updateLocation` repository acceptent toujours latitude/longitude.
- Impact: correct pour un futur flux geolocalisation, mais contraire a l'intention si une UI manuelle reapparait.
- Severite: faible a moyenne.
- Recommandation: conserver seulement pour un flux geolocalisation/map picker controle, pas pour des champs texte.

## 7. Audit de `ProfilePhotosPage`

### 7.1 Actions visibles

Actions:

- afficher les photos;
- ajouter une photo via galerie;
- definir une photo principale;
- supprimer une photo avec confirmation.

Etat observe:

- la limite photo utilise premium status:
  - gratuit: `AppLimits.maxPhotosGratuit`;
  - premium: `AppLimits.maxPhotosPremium`;
- upload limite aux images JPG/JPEG/PNG;
- taille max 5 MB;
- premiere photo envoyee avec `isMain: true`;
- set-main et delete utilisent `photo.id` si disponible.

### 7.2 Conformite backend

- Upload: `POST /user-profiles/me/photos/` avec champ `file`, conforme.
- Set main: `PUT /user-profiles/me/photos/{photo_id}/set-main/`, conforme.
- Delete: `DELETE /user-profiles/me/photos/{photo_id}/`, conforme.
- Rechargement apres mutation: conforme via `_reloadAfterAction`.

### 7.3 Risques detectes

Risque PP-1: reload double apres action photo.

- Preuve: `ProfileBloc._reloadAfterAction` recharge deja le snapshot complet, puis `ProfilePhotosPage` relance `LoadProfile` dans le listener `ProfileActionSuccess`.
- Impact: double appel reseau apres upload/suppression/set-main, latence et consommation inutiles.
- Severite: faible a moyenne.
- Recommandation: supprimer le `LoadProfile` supplementaire cote page lorsque le bloc fournit deja `loadedState`.

Risque PP-2: placeholder image hardcode.

- Preuve: `OptimizedImage` affiche `Pas de photo`.
- Impact: i18n incomplet.
- Severite: faible a moyenne.
- Recommandation: remplacer par une cle commune localisee.

## 8. Audit de `VerificationPage`

### 8.1 Elements visibles

Elements:

- statut de verification;
- code de verification;
- champ texte du code utilise;
- document d'identite;
- document medical;
- selfie avec code;
- bouton de soumission.

Etat observe:

- la page charge `ProfileBloc` puis `LoadProfile`;
- le code de verification est pre-rempli depuis `verification.verificationCode`;
- identity et medical utilisent `FilePicker.pickFiles` avec `allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf']`;
- selfie utilise maintenant explicitement `ImageSource.camera`;
- la soumission envoie `identityDocument`, `medicalDocument`, `selfieWithCode`, `selfieCode`.
- les fichiers du wizard de verification alternatif (`lib/presentation/pages/verification/steps/*`) et le `VerificationBloc` mort ont ete supprimes dans cette session.

### 8.2 Conformite backend

Conforme:

- lecture du statut: `GET /user-profiles/me/verification/`;
- generation URL signee par document;
- PUT vers URL signee avec content-type;
- soumission des chemins via `/submit-documents/`;
- envoi de `selfie_code_used`.

Non conforme:

- aucun ecart majeur detecte sur le contrat de documents ; PDF est supporte pour identity/medical.

### 8.3 Risques detectes

Risque PV-1: ~~PDF impossible pour document d'identite et document medical.~~ Resolu : `FilePicker` avec extensions `jpg/jpeg/png/pdf` est utilise.

Risque PV-2: absence d'etat erreur visible si le chargement initial echoue.

- Preuve: si `_loadedFrom(state)` retourne `null`, la page affiche `Scaffold(body: Center(child: HIVLoader()))`.
- Impact: apres un `ProfileError` sans `loadedState`, l'utilisateur peut rester sur un loader permanent, avec seulement un toast temporaire.
- Severite: moyenne.
- Recommandation: afficher un panneau d'erreur avec retry, comme le hub Profil.

Risque PV-3: documents selectionnes conserves apres soumission reussie.

- Preuve: `_identity`, `_medical`, `_selfie` sont des champs d'etat locaux. Un `ProfileActionSuccess` reinitialise les trois a `null` dans le `BlocConsumer` de `VerificationPage`.
- Impact: apres succes, le bouton de soumission est desactive car `_canSubmit` retourne `false` (statut `pending_review` ou documents absents).
- Severite: faible.
- Recommandation: verifier que le desactivation du bouton est suffisante ; sinon forcer un rechargement du profil.

Risque PV-4: absence de progression et statut par document.

- Preuve: la page affiche seulement une carte statut globale.
- Impact: upload de 3 fichiers via URLs signees peut sembler bloque.
- Severite: faible a moyenne.
- Recommandation: afficher progression ou etape courante, surtout pour documents medicaux volumineux.

## 9. Audit de `ProfilePrivacyPage`

### 9.1 Elements visibles

Elements:

- profil visible dans la decouverte;
- afficher le statut en ligne;
- afficher la distance;
- bouton sauvegarder.

Etat observe:

- la page cree un `ProfileBloc` et ajoute `LoadProfile` puis `LoadPrivacyPreferences`;
- sauvegarde via `SavePrivacyPreferences`.

### 9.2 Conformite backend

- Endpoint GET/PUT `/user-settings/privacy-preferences`, conforme.
- Payload contient:
  - `profile_visibility`;
  - `show_online_status`;
  - `show_distance`;
  - `profile_discoverable`.
- La page synchronise `profile_visibility` et `profileDiscoverable` quand le switch principal change, ce qui evite une contradiction connue du backend.

### 9.3 Risques detectes

Risque PR-1: evenement `LoadPrivacyPreferences` potentiellement ignore.

- Preuve: la page enchaine `..add(LoadProfile())..add(LoadPrivacyPreferences())`.
- Le handler `_onLoadPrivacyPreferences` retourne immediatement si `_currentLoaded == null`.
- Impact: selon l'ordre/concurrence des events Bloc, le second event peut ne rien faire; la page depend alors du chargement auxiliaire inclus dans `LoadProfile`.
- Severite: moyenne.
- Recommandation: charger les preferences apres `ProfileLoaded`, ou faire un event dedie qui n'exige pas `_currentLoaded`.

Risque PR-2: loader permanent si les preferences privacy ne sont pas disponibles.

- Preuve: si `loaded != null` mais `prefs == null`, la page retourne un loader.
- `LoadProfile` ignore silencieusement les echecs de privacy.
- Impact: erreur partielle backend = page sans message durable.
- Severite: moyenne.
- Recommandation: afficher erreur/retry ou fallback depuis `profile.privacySettings`.

## 10. Audit de `ProfileNotificationsPage`

### 10.1 Elements visibles

Elements:

- nouveaux matches;
- messages;
- likes recus;
- mises a jour de l'application;
- offres et nouveautes;
- ne pas deranger;
- bouton sauvegarder.

Etat observe:

- page cree `ProfileBloc`, ajoute `LoadProfile` puis `LoadNotificationPreferences`;
- sauvegarde via `SaveNotificationPreferences`;
- `do_not_disturb_settings.enabled` est modifie en conservant les autres cles.

### 10.2 Conformite backend

- GET/PUT `/user-settings/notification-preferences`, conforme.
- Le repository envoie l'objet complet, conforme a la recommandation backend.

### 10.3 Risques detectes

Risque PN-1: meme risque d'evenement ignore que privacy.

- Preuve: `LoadNotificationPreferences` exige `_currentLoaded != null`.
- Impact: dependance au chargement auxiliaire de `LoadProfile`.
- Severite: moyenne.
- Recommandation: event autonome ou lancement apres `ProfileLoaded`.

Risque PN-2: loader permanent si notifications absentes.

- Preuve: si `loaded != null` mais `prefs == null`, la page retourne un loader.
- `LoadProfile` ignore silencieusement l'echec notification.
- Impact: page bloquee sans message durable.
- Severite: moyenne.

Risque PN-3: texte DND hardcode.

- Preuve: subtitle `22:00 - 07:00 UTC`.
- Impact: ne reflute pas les heures venant de `do_not_disturb_settings` si elles changent; non i18n.
- Severite: faible a moyenne.
- Recommandation: construire le libelle depuis `start_time_utc` et `end_time_utc`, avec cle i18n.

## 11. Audit de `ProfileBlockedUsersPage`

### 11.1 Elements visibles

Elements:

- liste utilisateurs bloques;
- avatar;
- nom;
- bouton debloquer;
- etat vide.

Etat observe:

- page cree `ProfileBloc`, ajoute `LoadProfile` puis `LoadBlockedUsers`;
- `UnblockUser` appelle le backend puis recharge la liste.

### 11.2 Conformite backend

- GET `/user-settings/blocks`, conforme.
- DELETE `/user-settings/blocks/{user_id}`, conforme.

### 11.3 Risques detectes

Risque PB-1: meme risque d'evenement ignore que privacy/notifications.

- Preuve: `LoadBlockedUsers` exige `_currentLoaded != null`.
- Impact: la liste depend du chargement auxiliaire global.
- Severite: moyenne.

Risque PB-2: avatar vide.

- Preuve: `OptimizedImage(imageUrl: user.profilePhotoUrl ?? '')`.
- Impact: rendu acceptable grace au placeholder, mais texte placeholder hardcode.
- Severite: faible.

## 12. Audit de `ProfileDataPage`

### 12.1 Elements visibles

Elements:

- exporter mes donnees;
- demande de suppression du compte;
- confirmation avant suppression.

Etat observe:

- page charge `LoadProfile`;
- export appelle `RequestDataExport`;
- suppression appelle `RequestAccountDeletion`;
- retours success/error passent par toast.

### 12.2 Conformite backend

- Endpoint GET `/user-settings/export-data` declare dans `views_settings.py`, mais `export_data_view` est un stub qui retourne HTTP 202 avec `{"message": "Export request received"}` sans declencher aucune tache asynchrone ou envoi d'email.
- Endpoint POST `/user-settings/delete-account` declare, mais `delete_account_view` est un stub qui retourne HTTP 202 avec `{"message": "Account deletion request received"}` sans desactiver/supprimer reellement l'utilisateur.
- Le guide frontend suppose que ces endpoints accusent reception seulement, ce qui masque le fait que l'action n'est jamais executee cote backend.

### 12.3 Risques detectes

Risque PD-1: les actions export/suppression ne sont pas reellement effectuees.

- Preuve: `export_data_view` et `delete_account_view` sont des fonctions stub dans `profiles/views_settings.py`.
- Impact: l'utilisateur recoit un message de succes alors que rien n'est traite. Non conforme au RGPD et aux attentes fonctionnelles.
- Severite: elevee.
- Recommandation: implementer la logique backend reelle (asynchrone via Celery ou tache similaire) ou, a minima, marquer clairement l'etat en attente cote frontend.

Risque PD-2: pas d'etat de progression ou de desactivation pendant la requete.

- Impact: double clic possible sur export/suppression.
- Severite: faible.
- Recommandation: etat loading local ou bloc action-in-progress.

Risque PD-3: le message backend brut peut etre affiche tel quel.

- Preuve: repository retourne `response.data?['message']` puis la page appelle `_tr(state.message)`.
- Si le message n'est pas une cle i18n, `LocalizationService` retourne la chaine entree.
- Impact: acceptable fonctionnellement, mais messages backend non localises possibles.
- Severite: faible.

## 13. Audit de `CreateProfilePage` (onboarding)

### 13.1 Elements visibles

Elements:

- formulaire wizard en plusieurs etapes (genre, orientation, photos, bio, localisation, preferences, etc.);
- bouton "Cree mon profil" a la derniere etape.

Etat observe:

- UI complete et localisee;
- validations presentes sur plusieurs champs;
- le bouton final appelle `_createProfile()`;
- `_createProfile()` est implemente dans cette session : upload photo principale, update profil, update localisation, navigation vers `/discovery` via `BlocListener` sur `ProfileActionSuccess`.

### 13.2 Conformite backend

- Appels backend effectues via `ProfileBloc`:
  - `UploadMainPhoto` (ou endpoint photo principal);
  - `UpdateProfile` avec les champs onboarding;
  - `UpdateLocation` pour la geolocalisation.
- La route cible `/discovery` existe dans `AppRouter`.

### 13.3 Risques detectes

Risque CP-1: ~~le profil n'est pas reellement cree.~~ Resolu dans cette session.

Risque CP-2: choix radio deprecies.

- Preuve: analyse statique reporte 2 usages de `groupValue`/`onChanged` deprecies sur `Radio`.
- Impact: avertissements non bloquants, mais le widget sera retire a terme.
- Severite: faible.
- Recommandation: migrer vers `RadioGroup` (Flutter >= 3.32).

## 14. Audit de `LikesReceivedPage`

### 14.1 Elements visibles

Elements:

- titre "Qui m'a like";
- grille des profils qui ont like;
- etat vide;
- navigation vers un detail profil.

Etat observe (version actuelle, corrigee depuis le rapport initial):

- page cree `MatchesBloc` et lance `LoadLikesReceived`;
- `MatchesBloc` emet `LikesReceivedLoading`, `LikesReceivedLoaded` ou `MatchesError`;
- la page gere maintenant explicitement `MatchesError`;
- elle distingue l'erreur premium (`PremiumRequiredFailure`) avec un CTA explicite;
- les autres erreurs affichent un message et un bouton retry;
- la navigation detail utilise `/profile-detail?readonly=true` avec `extra: profile`.

### 14.2 Conformite backend

- Endpoint: GET `/user-profiles/likes-received/` dans `profiles/views_premium.py`.
- Le backend retourne 403 avec `{"detail": "Premium required to view who liked you"}` si l'utilisateur n'est pas premium.
- La reponse ne contient pas la date/heure du like, ce qui empeche d'afficher un tri ou un "Nouveau".
- Le hub Profil affiche "Disponible avec Premium" si `canSeeLikers` est false, mais laisse la navigation active.

### 14.3 Risques detectes

Risque LR-1: navigation possible meme sans premium.

- Preuve: la tuile Likes recus dans `ProfileDetailPage` est toujours cliquable.
- Impact: l'utilisateur peut atteindre `LikesReceivedPage`, declencher l'appel, recevoir 403, puis voir le panneau premium. C'est acceptable UX mais genere un appel inutile.
- Severite: faible.
- Recommandation: desactiver la tuile ou l'ouvrir directement sur un upsell premium sans appeler le backend.

Risque LR-2: textes hardcodes et non i18n.

- Preuve: titre, etat vide et plusieurs labels sont en dur.
- Impact: locale EN non respectee.
- Severite: moyenne.

Risque LR-3: la reponse backend ne fournit pas la date du like.

- Preuve: `LikesReceivedView` renvoie seulement les profils via un serializer standard, sans champ `liked_at`.
- Impact: impossible d'ordonner chronologiquement ou d'afficher "Aujourd'hui".
- Severite: moyenne.
- Recommandation: backend -- ajouter `liked_at` (timestamp de l'interaction Like) dans la reponse de `/user-profiles/likes-received/`.

Risque LR-4: le detail profil est presente en mode readonly.

- Preuve: navigation via `/profile-detail?readonly=true` avec `extra: profile`.
- Impact: l'utilisateur ne peut pas liker en retour depuis Likes recus; il doit revenir en arriere et utiliser Discovery.
- Severite: faible a moyenne.
- Recommandation: permettre l'action "Like back" depuis le detail readonly, ou utiliser une page publique dediee.

## 15. Audit de `PremiumPage`

### 15.1 `PremiumPage`

Etat observe:

- page declaree dans la route `/premium`;
- cree `PremiumBloc` via `getIt<PremiumBloc>()`;
- affiche les plans disponibles;
- permet de changer de plan (bouton "Changer d'abonnement") via le backend;
- le bouton "S'abonner" / "Subscribe now" est desactive car aucun plan n'est selectionne (`_selectedPlan` vide);
- ce bouton affiche seulement un snackbar `premium.checkout_unavailable`.

Conformite backend:

- `GET /subscriptions/plans/` pour lister les plans.
- `POST /subscriptions/change/` pour changer de plan actif.
- `GET /subscriptions/status/` pour le statut courant.

Risques:

- `PremiumBloc` n'est **pas** enregistre dans `lib/injection.dart` (il apparait uniquement dans un bloc commente). L'appel `getIt<PremiumBloc>()` plantera a l'execution avec `ArgumentError: Object/factory with type PremiumBloc is not registered inside GetIt.`.
- Severite: elevee.
- Recommandation: enregistrer `PremiumBloc` dans `injection.dart` avec ses dependances, ou instancier le bloc localement dans `PremiumPage`.

### 15.2 `PaymentPage` (supprimee dans cette session)

Etat observe (apres correction):

- le fichier `lib/presentation/pages/premium/payment_page.dart` a ete supprime;
- la route `/payment` a ete retiree de `AppRouter`;
- la route `/settings`, la page `SettingsPage` et `SettingsBloc` ont egalement ete supprimes;
- le flux d'achat est desormais entierement gere par `PremiumPage` + `PurchasePremium` via `PremiumBloc`.

Conformite backend:

- MyCoolPay est toujours hardcode dans `PaymentService` cote backend, mais le frontend n'appelle plus de page de paiement separee.

Risques:

- plus d'ecran mort ni de simulation de paiement;
- i18n complete non encore necessaire car la page n'existe plus.
- Severite: resolu.
- Recommandation: Aucune action frontend requise. Si un checkout dedie est necessaire a l'avenir, le recreer avec i18n et contrat backend valide.

## 16. Audit des pages legales et About

### 16.1 About

Etat observe:

- page accessible depuis Profil;
- affiche version app via `PackageInfo`;
- mission et benefices;
- boutons email/site fonctionnels (lancement URL).

Risques:

- nom d'application `HIVMeet` et fallbacks de version/build etaient hardcodes avant cette session;
- correction appliquee: `about.app_name` ajoute en FR/EN, fallbacks version/build passes a chaines vides.
- copyright statique 2026 reste present mais est localise via `about.copyright`.

Severite:

- faible (resolu pour les chaines visibles).

### 16.2 Privacy et Terms

Etat observe:

- pages accessibles depuis Profil;
- contenu HTML statique en francais;
- pas de localisation EN;
- date "Janvier 2025";
- contenu sensible pour une app VIH, mais generique.

Risques:

- i18n incomplet;
- contenu legal potentiellement non valide/obsolete selon juridiction;
- pas de versioning legal dynamique.

Severite:

- moyenne, surtout avant publication.

## 17. Audit de la page Settings residuelle (supprimee dans cette session)

Etat observe:

- ~~`/settings` reste declaree dans `AppRouter` et protegee par auth.~~ Supprime dans cette session.
- le hub Profil ne propose plus de navigation vers `/settings`.
- ~~`SettingsPage` a ete nettoyee : elle affiche maintenant des tuiles localisees redirigeant vers les sous-flux Profil existants (`/profile/edit`, `/profile/notifications`, `/profile/privacy`, `/profile/data`, `/about`, `/privacy`, `/terms`).~~ `SettingsPage`, `SettingsBloc`, etat/evenements et le test `settings_page_test.dart` ont ete supprimes.
- la route `/settings` a ete retiree de `AppRouter` et de `protectedRoutes`.
- la page n'existe plus ; le hub Profil reste le seul point d'entree.

Risques:

- aucun.

Severite:

- resolu.

Recommandation:

- Aucune action requise. Le hub Profil couvre toutes les fonctionnalites.

## 18. Audit i18n

### 18.1 Ce qui est conforme

- Les nouvelles cles Profil existent en FR et EN:
  - `support_legal`;
  - `about`;
  - `about_subtitle`;
  - `privacy_policy`;
  - `privacy_policy_subtitle`;
  - `terms`;
  - `terms_subtitle`;
  - `account_access`;
  - `sign_out`;
  - `sign_out_subtitle`;
  - `sign_out_confirm`;
  - `take_selfie`.
- Les fichiers JSON sont valides.
- Les cles `profile` sont en parite FR/EN.

### 18.2 Non-conformites i18n observees

Surfaces accessibles depuis Profil avec textes hardcodes:

- `CreateProfilePage`: UI localisee, mais fonctionnellement inactive (aucun rapport direct i18n).
- `AboutPage`: le nom d'application `HIVMeet` et les fallbacks de version/build etaient hardcodes ; corriges dans cette session avec `about.app_name` et des fallbacks vides.
- `LikesReceivedPage`: titre, etats vides, labels.
- `PremiumPage`: partiellement i18n mais page minimale.
- `AboutPage`: contenu complet hardcode.
- `PrivacyPage`: contenu HTML hardcode.
- `TermsPage`: contenu HTML hardcode.
- `AppScaffold`: labels bottom navigation hardcodes.
- `OptimizedImage`: texte `Pas de photo`.
- `ProfileNotificationsPage`: `22:00 - 07:00 UTC`.
- `Gender.getLabel`: labels FR/EN stockes dans l'entite, mais appel depuis edit sans locale.

Severite globale:

- moyenne.

Recommandation:

- extraire les textes visibles vers `assets/translations/fr.json` et `assets/translations/en.json`;
- brancher les labels de genre sur la locale courante;
- eviter les contenus legaux hardcodes dans les widgets.

## 19. Audit securite, confidentialite et sensibilite VIH

Points positifs:

- la page Profil n'affiche pas le statut medical ou des donnees VIH;
- les documents de verification ne sont pas affiches apres selection au-dela du nom de fichier local;
- le selfie force maintenant la camera;
- les chemins `file_path_on_storage` et `upload_url` ne sont pas affiches;
- pas de logging direct detecte dans les fichiers Profil audites.

Risques:

- les documents selectionnes restent references en memoire locale dans `VerificationPage` jusqu'a destruction de la page;
- la page affiche les noms de fichiers locaux selectionnes, ce qui peut reveler des informations sensibles si le nom du fichier contient un diagnostic ou un type de document;
- les textes legaux sont generiques et ne documentent pas finement les risques specifiques a une communaute VIH;
- ~~`SettingsPage` contient un faux email, ce qui peut induire en erreur.~~ `SettingsPage` supprimee dans cette session.

Recommandations:

- masquer ou simplifier les noms de fichiers sensibles;
- reinitialiser les fichiers apres soumission;
- renforcer les pages legales avant release;
- conserver l'approche camera-only pour le selfie.

## 20. Conformite au contrat backend Profil (end-to-end)

L'analyse ci-dessous compare chaque endpoint backend Django avec les serializers, paths, status codes et le comportement reel observe dans `env/hivmeet_backend/profiles/`.

| # | Endpoint backend Django | Path declare | Serializer / vue | Statut frontend | Ecart critique |
|---|-------------------------|--------------|------------------|-----------------|----------------|
| 1 | `GET /user-profiles/me/` | `me/` | `ProfileSerializer` | Fonctionne. | Aucun ecart majeur. |
| 2 | `PATCH /user-profiles/me/` | `me/` | `ProfileUpdateSerializer` | Fonctionne. | Le backend accepte `gender`, `latitude`, `longitude` ; il devrait les ignorer/refuser si le genre ne doit plus etre modifiable. |
| 3 | `POST /user-profiles/me/photos/` | `me/photos/` | `PhotoUploadSerializer` | Fonctionne avec tolerance. | Le backend retourne `photo_id`/`url` ; le frontend s'attendait historiquement a `id`/`photo_url`. Le mapping `_mapPhoto` tolere les deux, mais la doc est desynchronisee. |
| 4 | `PUT /user-profiles/me/photos/{id}/set-main/` | `me/photos/<int:photo_id>/set-main/` | view fonction | Fonctionne. | Aucun ecart majeur. |
| 5 | `DELETE /user-profiles/me/photos/{id}/` | `me/photos/<int:photo_id>/` | `delete_photo_view` | Fonctionne partiellement. | Bug backend : apres `photo.delete()`, le code tente `other_photo.is_main = True` sur l'instance `photo` deja detruite au lieu d'une autre photo. Corriger par `Photo.objects.filter(...).update(is_main=True)` ou reselection. |
| 6 | `GET /user-profiles/premium-status/` | `premium-status/` | `PremiumStatusView` | Fonctionne. | Docstring indique `/profiles/premium-status/` mais l'URL reelle est `/user-profiles/premium-status/`. A harmoniser. |
| 7 | `POST /user-profiles/likes/` | `likes/` | `LikesReceivedView` | Fonctionne. | Endpoint de like, pas d'ecart dans ce perimetre. |
| 8 | `GET /user-profiles/likes-received/` | `likes-received/` | `LikesReceivedView` | Fonctionne partiellement. | Retourne 403 pour non-premium ; la liste ne contient pas `liked_at`. |
| 9 | `GET /user-profiles/me/verification/` | `me/verification/` | `VerificationStatusView` | Fonctionne. | Aucun ecart majeur. |
| 10 | `POST /user-profiles/me/verification/generate-upload-url/` | `me/verification/generate-upload-url/` | view fonction | Fonctionne. | Genere URL signee Firebase Storage. Aucun ecart. |
| 11 | `POST /user-profiles/me/verification/submit-documents/` | `me/verification/submit-documents/` | `submit_verification_documents_view` | Fonctionne partiellement. | Met `user.verification_status = 'pending'` meme si les documents (`identity_document`, `medical_document`, `selfie_with_code`) sont incomplets. Le frontend pourrait afficher "soumis" alors que le backend n'a pas tous les fichiers. |
| 12 | `GET/PUT /user-settings/privacy-preferences/` | `privacy-preferences/` | `PrivacyPreferencesView` | Fonctionne partiellement. | GET merge les defauts (OK). PUT remplace le JSON brut sans validation par un serializer ; retourne l'objet mis a jour. Aucun ecart bloquant. |
| 13 | `GET/PUT /user-settings/notification-preferences/` | `notification-preferences/` | `NotificationPreferencesView` | Fonctionne partiellement. | GET merge les defauts. PUT remplace le JSON brut sans validation par un serializer ; absence de validation des cles ou types. |
| 14 | `GET /user-settings/blocks/` + `DELETE /user-settings/blocks/<int:user_id>/` | `blocks/` | `BlockedUsersView` / `UnblockUserView` | Fonctionne. | Aucun ecart majeur. |
| 15 | `GET /user-settings/export-data/` | `export-data/` | `export_data_view` | Ne fonctionne pas reellement. | Stub 202, aucune tache declenchee. |
| 16 | `POST /user-settings/delete-account/` | `delete-account/` | `delete_account_view` | Ne fonctionne pas reellement. | Stub 202, aucune suppression. |
| 17 | `GET /user-profiles/<int:user_id>/public/` | `<int:user_id>/public/` | `PublicProfileView` | Fonctionne. | Endpoint public utilise par `PublicProfilePage` ; non dedie au scope Profil mais utile depuis Likes recus. |

### 20.1 Synthese des ecarts backend a corriger

1. **Photo delete : bug logique** dans `delete_photo_view`.
2. **Likes received :** ajouter `liked_at` dans la reponse ; gerer 403 cote frontend comme upsell premium.
3. **Verification submit :** verifier que les 3 documents sont fournis avant de passer `verification_status` a `pending`.
4. **Notification preferences :** valider le payload avec un serializer et retourner l'objet mis a jour.
5. **Export / Delete account :** implementer la logique reelle ou marquer l'etat en attente.
6. **Docstring premium-status :** corriger le path indique dans la docstring de `PremiumStatusView`.

### 20.2 Synthese des ecarts frontend a corriger

1. `LikesReceivedPage` i18n complete.
2. `VerificationPage` autoriser PDF pour identity/medical.
3. `PremiumBloc` enregistrement dans `injection.dart`.
4. `PaymentPage` supprimee (resolu).
5. `CreateProfilePage` implementation reelle.
6. ~~`SettingsPage` / `SettingsBloc` nettoyage.~~ Resolu : page, bloc, etat/evenements, route `/settings` et test obsolete supprimes dans cette session.

## 21. Matrice des fonctionnalites Profil et sous-flux

Chaque fonctionnalite est classee selon trois categories :

- **Fonctionne completement** : UI, navigation, contrat backend, persistance et retour utilisateur sont operationnels sans ecart majeur.
- **Fonctionne partiellement** : le flux principal est visible ou partiellement operationnel, mais un ou plusieurs ecarts (backend, i18n, persistance, robustesse) degradent l'experience.
- **Ne fonctionne pas** : la fonctionnalite est inutilisable, factice, ou mene a une erreur/effet de bord non gerable.

| # | Fonctionnalite | Classification | Gaps precis | Etapes de remediation |
|---|----------------|----------------|-------------|----------------------|
| 1 | Hub Profil principal (chargement, header, metriques, navigation) | **Fonctionne completement** | Placeholder image non i18n (`Pas de photo` dans `OptimizedImage`). | Ajouter une cle i18n pour le placeholder. |
| 2 | Modifier le profil (`ProfileEditPage`) | **Fonctionne partiellement** | Genre/lat/lng retires de l'UI mais encore acceptes par les couches internes et potentiellement le backend ; labels de genre non localises dynamiquement. | Retirer `gender`/`latitude`/`longitude` du flux `UpdateProfile` ; brancher `Gender.getLabel` sur la locale courante ; demander au backend d'ignorer ces champs. |
| 3 | Photos profil (`ProfilePhotosPage`) | **Fonctionne partiellement** | Double reload apres chaque action ; bug backend `delete_photo_view` qui reassigne `is_main` sur l'instance detruite. | Supprimer le `LoadProfile` redondant cote page ; corriger la vue backend avec `Photo.objects.filter(...).update(is_main=True)`. |
| 4 | Verification (`VerificationPage`) | **Fonctionne partiellement** | UI accepte seulement JPG/JPEG/PNG alors que le backend autorise PDF ; pas d'erreur/retry si chargement initial echoue ; documents locaux conserves apres soumission ; backend passe `verification_status='pending'` meme si documents incomplets. | Utiliser un file picker pour identity/medical acceptant images + PDF ; afficher panneau erreur/retry ; reinitialiser les fichiers apres soumission ; backend -- verifier presence des 3 documents avant de passer pending. |
| 5 | Confidentialite (`ProfilePrivacyPage`) | **Fonctionne partiellement** | Event `LoadPrivacyPreferences` potentiellement ignore si `_currentLoaded` est nul ; loader permanent si prefs absentes. | Rendre l'event autonome ou le declencher apres `ProfileLoaded` ; afficher erreur/retry ou fallback depuis `profile.privacySettings`. |
| 6 | Notifications (`ProfileNotificationsPage`) | **Fonctionne partiellement** | Meme risque d'event ignore ; loader permanent ; plage DND hardcodee `22:00 - 07:00 UTC` ; backend PUT remplace JSON brut sans validation. | Meme remediation que privacy ; construire le libelle DND depuis `start_time_utc`/`end_time_utc` ; backend -- ajouter un serializer de validation. |
| 7 | Utilisateurs bloques (`ProfileBlockedUsersPage`) | **Fonctionne partiellement** | Event `LoadBlockedUsers` depend de `_currentLoaded` ; placeholder image non i18n. | Meme remediation que privacy ; corriger le placeholder. |
| 8 | Donnees et compte (`ProfileDataPage`) | **Ne fonctionne pas** | `export_data_view` et `delete_account_view` cote backend sont des stubs 202 : aucune donnee n'est exportee et aucun compte n'est supprime. L'utilisateur recoit un succes factice. | Implementer la logique backend reelle (Celery/asynchrone) ou afficher un etat "en attente de traitement" cote frontend. Ajouter un etat loading anti double-clic. |
| 9 | Likes recus (`LikesReceivedPage`) | **Fonctionne partiellement** | Gestion erreur amelioree, mais backend 403 premium et absence de `liked_at` ; navigation possible sans premium (appel inutile) ; textes non i18n. | Desactiver la tuile ou ouvrir un upsell sans appel API ; backend -- ajouter `liked_at` ; extraire toutes les chaines vers ARB. |
| 10 | Premium (`PremiumPage`) | **Fonctionne partiellement** | `PremiumBloc` est desormais enregistre dans `injection.dart` ; le bouton subscribe emet `PurchasePremium`. Reste a valider l'integration payment backend complete. | Valider le flux de paiement reussi et les erreurs cote backend. |
| 11 | Paiement (`PaymentPage`) | **Resolu** | Page supprimee dans cette session ; le flux premium passe par `PremiumPage` + `PurchasePremium`. | Aucune action requise. |
| 12 | Pages legales (`About`, `Privacy`, `Terms`) | **Fonctionne partiellement** | Routes et structure OK ; `AboutPage` est maintenant localise (app name, version fallbacks) ; contenu legal HTML (`Privacy`/`Terms`) reste hardcode en francais. | Extraire le contenu HTML legal vers les fichiers ARB et versionner. |
| 13 | Profil public (`/profile/:id`) | **Fonctionne completement** | Route corrigee vers `PublicProfilePage(userId: userId)`. | Aucune action requise. |
| 14 | Deconnexion depuis Profil | **Fonctionne completement** | Dialogue + emission `LoggedOut` + navigation `/`. | Aucune action requise. |
| 15 | Onboarding `CreateProfilePage` | **Fonctionne** | `_createProfile()` implemente dans cette session : upload photo, update profil, update localisation, navigation `/discovery`. | Ajouter des tests widget/bloc et valider le cas d'erreur reseau. |
| 16 | Settings residuelle (`SettingsPage` + `SettingsBloc`) | **Resolu** | Page, bloc, etat/evenements, route `/settings` et test obsolete supprimes dans cette session. | Aucune action requise. |

## 22. Liste priorisee des corrections recommandees pour une future session

### Priorite elevee

1. **Corriger les stubs backend export/delete :** l'utilisateur recoit un succes factice.
2. ~~**Corriger `VerificationPage` :** autoriser PDF pour identity/medical et afficher erreur/retry.~~ Resolu / code mort supprime dans cette session.
3. **i18n AboutPage :** le nom d'application et les fallbacks de version sont desormais localises (resolu dans cette session).

### Priorite moyenne

4. **Corriger `LikesReceivedPage` :** i18n complete, eviter appel inutile si non premium, afficher `liked_at` si backend le fournit.
5. **Corriger les sous-pages Privacy/Notifications/Blocked :** events autonomes, erreurs durables.
6. **Finaliser i18n des destinations Profil :** LikesReceived, Privacy, Terms, AppScaffold labels, OptimizedImage placeholder, DND notification, labels de genre.
7. **Verrouiller l'immutabilite du genre :** retirer `gender` du flux update et demander au backend de l'ignorer/refuser.
8. **Corriger le bug backend photo delete :** reassignation de `is_main` sur instance detruite.

### Priorite faible

9. Supprimer le double reload de `ProfilePhotosPage`.
10. Remplacer `withOpacity` par `withValues` dans les surfaces auditees.
11. Ajouter des tests widget/bloc pour `CreateProfile` et `PremiumPage`.
12. Ameliorer `VerificationPage` : panneau erreur/retry durable et progression d'upload.
13. Ajouter tests dedies au hub Profil et sous-flux.

## 23. Tests recommandes a creer

Il n'existe pas de test dedie au hub Profil actuel. Les tests recommandes:

1. Widget test `ProfileDetailPage`:
   - affiche sections attendues;
   - ne contient pas bouton settings;
   - routes des tuiles appelees correctement.

2. Widget test `ProfileEditPage`:
   - absence de champ genre;
   - absence de champs latitude/longitude;
   - sauvegarde sans `gender`, `latitude`, `longitude`.

3. Widget test `VerificationPage`:
   - selfie utilise camera;
   - identity/medical acceptent PDF et images;
   - erreur initiale affiche retry;
   - bouton submit desactive tant que documents/code incomplets.

4. Bloc tests `ProfileBloc`:
   - `LoadProfile` hydrate profile/premium/verification/privacy/notifications/blocked;
   - echecs auxiliaires sont representes sans bloquer l'UI;
   - `SavePrivacyPreferences` recharge ou synchronise correctement le profil.

5. Widget test `LikesReceivedPage`:
   - loading;
   - loaded vide;
   - loaded avec profils;
   - `MatchesError`;
   - cas premium required.

6. Route tests:
   - toutes les routes exposees depuis Profil resolvent une page attendue;
   - `/profile/:id` affiche `PublicProfilePage` avec le bon `userId`.

7. DI test:
   - `PremiumBloc` et `CreateProfile` dependences sont resolubles via `getIt`.

## 24. Conclusion

Le hub Profil principal est fonctionnel dans sa structure actuelle et respecte les deux exigences recentes les plus visibles: suppression de l'engrenage Settings et suppression de l'edition du genre/coordonnees GPS directes dans l'ecran d'edition. Le selfie camera-only est egalement en place. La route `/profile/:id` a ete corrigee et pointe desormais vers un vrai profil public.

L'audit end-to-end du backend Django a toutefois revele des problemes de securite et de conformite plus profonds: suppression photo mal implementee, verification acceptant des documents incomplets, preferences notification sans validation, export/suppression de compte factices, et likes recus sans timestamp.

Les fonctionnalites les plus bloquantes pour une release sont : `ProfileDataPage` avec backend stub. `CreateProfilePage`, `PremiumBloc`/`PremiumPage`, la suppression de `PaymentPage`, la suppression de `SettingsPage`/`SettingsBloc`/route `/settings`, le support PDF de `VerificationPage` (deja present ; code mort du wizard supprime), et l'i18n de `AboutPage` ont ete corriges dans cette session.

Recommandation de suite: traiter d'abord la correction prioritaire elevee restante (`ProfileDataPage` backend stub), puis stabiliser les sous-pages Privacy/Notifications/Blocked et l'i18n restante, enfin ajouter des tests widget/bloc dedies au hub Profil. Le backend stub export/delete est documente dans `BACKEND_PROFILE_DATA_EXPORT_DELETE.md`.
