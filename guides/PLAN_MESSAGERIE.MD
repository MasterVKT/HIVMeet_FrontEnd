# Plan — Messagerie HIVMeet : audit + harmonisation 100% frontend

## Contexte

Demande : vérifier l'implémentation complète de la messagerie, corriger ce qui ne
fonctionne pas, et **harmoniser le frontend avec le backend** d'après le contrat
`guides/FRONTEND_MESSAGING_API.md` (2026-05-21, « production-ready, post-audit »).

L'audit (lecture seule) révèle que **le chat est aujourd'hui inaccessible** et que
plusieurs surfaces affichent des données factices. La couche données est en grande
partie correcte (`MessageRepositoryImpl` + `MessagingApi` alignés au contrat), mais
la présentation et le mapping d'entités cassent le flux de bout en bout.

### Décisions de périmètre (validées avec l'utilisateur)
- **Appels audio/vidéo (WebRTC) : HORS PÉRIMÈTRE.** On garde le stub `_initiateCall`
  (toast « coming soon »). On ne touche pas aux endpoints `/calls/*`.
- **Bloquer / signaler : À IMPLÉMENTER**, en réutilisant les usecases existants.
- **Média : flux le plus performant et le plus aligné contrat** → on câble le flux
  signed-URL §4.10 → §4.4 (upload client→GCS direct), dont la plomberie repo existe
  déjà (`generateMediaUploadUrl`), tout en **conservant** le multipart §4.11 comme
  repli (pas de suppression = moins de régression).

---

## P0 — Bloquants (le chat ne marche pas sans ça)

### P0.1 — Router `ChatPage` (chat injoignable)
`conversations_page.dart:85` fait déjà `context.push('/chat/${conversation.id}')`,
mais `routes.dart` n'a **aucune** route `/chat/:conversationId` — seulement `/chat`
qui renvoie `ConversationsPage`. Résultat : tap sur une conversation → `errorBuilder`
(« page introuvable »).

- `lib/core/config/routes.dart` :
  - Ajouter `static const String chatDetail = '/chat/:conversationId';`
  - Ajouter une `GoRoute(path: chatDetail, ...)` qui lit `state.pathParameters['conversationId']`
    et `state.extra as Conversation?`, puis construit `ChatPage(conversationId: id, conversation: conv)`.
  - Importer `chat_page.dart` et l'entité `Conversation` (`domain/entities/message.dart`).
  - Ajouter `AppRoutes.chat` à `protectedRoutes` (le `startsWith('/chat')` couvre `/chat/:id`).
- `lib/presentation/pages/conversations/conversations_page.dart:85` :
  passer la conversation enrichie en extra → `context.push('/chat/${conversation.id}', extra: conversation)`.

### P0.2 — `isMe` codé en dur (tous les messages côté « autre »)
`chat_page.dart:375-376` : `final isMe = message.senderId == 'current_user_id'` →
toujours `false`. **Tous** les messages s'affichent comme reçus.
- `chat_page.dart` : `final isMe = message.isMine;`
- `chat_bloc.dart` : sur les messages optimistes (`_onSendTextMessage` ~164,
  `_onSendMediaMessage` ~224), ajouter `isMine: true` pour un rendu correct avant
  l'écho serveur. (Les messages WS posent déjà `isMine` via `senderId == currentUserId`.)

### P0.3 — En-tête ChatPage toujours vide
`MatchFoundModal` (discovery) navigue vers `/conversations`, jamais vers `ChatPage`
avec un profil. Donc `widget.matchedProfile` est **toujours null** → nom/photo/online
de l'en-tête cassés. On alimente l'en-tête depuis la `Conversation` (passée en extra).
- Enrichir l'entité `Conversation` (`lib/domain/entities/message.dart`) :
  ajouter `otherUserId`, `otherUserName`, `otherUserPhotoUrl`, `isOnline`, `lastActive`.
  Mettre à jour constructeur, `props`, `fromJson`/`toJson` (champs `other_user.*`).
- Mapper réel (`lib/data/repositories/message_repository_impl.dart` `_mapJsonToConversation`
  257-286) : lire `other_user.{user_id, display_name, main_photo_url, is_online, last_active}`
  (garder `participantIds` pour compat).
- `chat_page.dart` : remplacer le paramètre `matchedProfile` (jamais passé) par
  `Conversation? conversation`. L'en-tête, l'avatar du « typing », le « view profile »
  et block/report lisent `conversation.otherUserName / otherUserPhotoUrl / otherUserId / isOnline / lastActive`.

### P0.4 — Aperçu du dernier message vide
Le contrat : `last_message.content_preview` (pas `content`).
`_mapJsonToMessage` (message_repository_impl 292) lit seulement `json['content']`.
- `content: (json['content'] ?? json['content_preview'] ?? '') as String`.

---

## P1 — Harmonisation temps réel & robustesse

### P1.1 — Parsing message WS incomplet
`chat_bloc.dart` `_onWsMessageReceived` (406-442) : type **codé en dur** `MessageType.text`
et dédup par `message_id` seul. Le contrat impose `client_message_id` comme clé de
dédup (écho de l'expéditeur) et `message_type` peut être media.
- Parser `message_type` → `MessageType`, lire `media_url`/`media_type`/`media_thumbnail_url`.
- Dédupliquer par `client_message_id` **et** `message_id` (évite le doublon quand
  l'écho WS précède la réponse REST du message optimiste).

### P1.2 — `presence.update` ignoré
`_onWsPresenceUpdate` (459-465) ne fait rien → statut « en ligne » figé.
- Ajouter `bool? otherIsOnline` (+ `DateTime? otherLastActive`) à `ChatLoaded`
  (`chat_state.dart`, `copyWith`, `props`).
- `_onWsPresenceUpdate` : émettre `copyWith(otherIsOnline: event.isOnline)`.
- En-tête : `state.otherIsOnline ?? conversation?.isOnline ?? false`.

### P1.3 — Crash potentiel `MessageModel.isRead`
`message_model.g.dart:29` lit `json['is_read'] as bool` (requis, sans défaut) →
exception quand le backend l'omet (le contrat ne renvoie pas `is_read`).
`MessageModel` est vivant via `match_model.dart` (last_message).
- `lib/data/models/message_model.dart` : annoter `@JsonKey(defaultValue: false)` sur
  `isRead` (idem `isDelivered`), puis régénérer (`dart run build_runner build --delete-conflicting-outputs`).

### P1.4 — Code mort (après confirmation grep = 0 import)
- `lib/data/repositories/messaging_repository.dart` (jamais enregistré/utilisé).
- `lib/data/models/conversation_model.dart` + `.g.dart` (doublon non utilisé).
- `ConversationModel` dans `message_model.dart` (non utilisé).
> Suppression seulement si grep confirme aucun import. Sinon, laisser et noter.

---

## P2 — Fonctionnalités demandées

### P2.1 — Bloquer / signaler depuis le chat
Aujourd'hui `chat_page._showBlockDialog` / `_showReportDialog` (644-650) sont vides ;
les dialogues de `discovery/profile_detail_page.dart` le sont aussi (TODO). Mais les
endpoints réels existent :
- **Block** : `BlockUser` usecase (`domain/usecases/profile/block_user.dart`) →
  `profile_repository_impl.blockUser` → settings API. **Fonctionnel, à réutiliser.**
- **Report** : `auth_api.reportUser` → `POST /auth/report-user` **existe** mais aucun
  usecase ne l'enveloppe (`reportProfile` repo profil est un stub vers un endpoint
  inexistant). Créer un usecase `ReportUser` + méthode repo qui appelle `auth_api.reportUser`.

Implémentation :
- Injecter `BlockUser` (+ nouveau `ReportUser`) dans `ChatBloc` ; ajouter events
  `BlockUserEvent` / `ReportUserEvent` (utilisent `conversation.otherUserId`).
- `chat_page` : implémenter les deux dialogues (titre/message i18n, motif pour report) ;
  succès → toast + `context.pop()` (block dissout le match).

### P2.2 — Envoi média : flux signed-URL (§4.10 → §4.4)
Plomberie déjà présente : `MessagingApi.generateMediaUploadUrl`,
`MessageRepositoryImpl.generateMediaUploadUrl`, usecase `GenerateMediaUploadUrl`.
Manque l'orchestration + l'envoi du message référencé.
- `MessagingApi` : ajouter `sendMessageWithMediaPath({conversationId, type,
  mediaFilePathOnStorage, clientMessageId, content?})` → `POST /conversations/{id}/messages/`
  avec `type` + `media_file_path_on_storage` (champ §4.4).
- `MessageRepositoryImpl.sendMessage` (branche `mediaFile != null`) : orchestrer
  (1) `generateMediaUploadUrl` → (2) `PUT` binaire vers `upload_url` avec un **Dio brut**
  (sans baseUrl ni interceptor d'auth — ne jamais envoyer le Bearer à GCS) →
  (3) `sendMessageWithMediaPath(file_path_on_storage)`. En cas d'échec d'une étape,
  remonter le `Failure` (le rollback optimiste existe déjà dans `ChatBloc`).
- **Conserver** `MessagingApi.sendMediaMessage` (multipart §4.11) comme repli.
- 402/403 (premium requis) → déjà mappés (`PremiumFailure`) → afficher prompt premium.

### P2.3 — Suppression de conversation
Le contrat n'expose **aucun** endpoint « delete conversation » (seulement delete
**message** §4.7). `conversations_page._confirmDeleteConversation` (388-392) affiche
« Fonctionnalité non implémentée ».
- Créer `BACKEND_MESSAGING_DELETE_CONVERSATION.md` (racine) décrivant l'endpoint requis
  (méthode, path, payload, codes). Garder l'UI honnête (message i18n) en attendant.

---

## i18n (FR + EN — `assets/translations/{fr,en}.json`)
Ajouter les clés des nouveaux dialogues : `chat.block_confirm_title`,
`chat.block_confirm_message`, `chat.report_dialog_title`, `chat.report_dialog_message`,
`chat.report_reason_*`, `chat.block_success`, `chat.report_success`, `chat.action_error`.
Réutiliser `common.cancel` / `common.block` / `common.report`. Toute chaîne neuve passe
par `LocalizationService.translate` (pas de texte en dur).

---

## Fichiers à modifier (synthèse)
| Fichier | Changements |
|---|---|
| `lib/core/config/routes.dart` | route `/chat/:conversationId` + import ChatPage/Conversation + protectedRoutes |
| `lib/presentation/pages/conversations/conversations_page.dart` | `push(..., extra: conversation)` ; nom/photo réels via entité ; delete honnête |
| `lib/presentation/pages/chat/chat_page.dart` | `isMe = message.isMine` ; en-tête depuis `conversation` ; block/report ; param `conversation` |
| `lib/domain/entities/message.dart` | enrichir `Conversation` (other_user) |
| `lib/data/repositories/message_repository_impl.dart` | mapper other_user + content_preview ; orchestration média signed-URL |
| `lib/data/datasources/remote/messaging_api.dart` | `sendMessageWithMediaPath` |
| `lib/presentation/blocs/chat/chat_bloc.dart` | WS parse type/média + dédup client_message_id ; presence→state ; isMine optimiste ; events block/report |
| `lib/presentation/blocs/chat/chat_state.dart` | champs `otherIsOnline`/`otherLastActive` |
| `lib/data/models/message_model.dart` (+ régénérer `.g.dart`) | `isRead`/`isDelivered` defaultValue:false |
| `domain/usecases/.../report_user.dart` (+ repo/api wiring) | nouveau usecase Report |
| `assets/translations/{fr,en}.json` | clés block/report/delete |
| `BACKEND_MESSAGING_DELETE_CONVERSATION.md` | demande backend |
| (P1.4) suppressions code mort | si grep = 0 import |

---

## Vérification (bout en bout)
1. `flutter analyze` (0 erreur) ; `dart run build_runner build --delete-conflicting-outputs` après P1.3.
2. `flutter test` (au moins ne pas casser l'existant ; ajouter test mapper Conversation/other_user si rapide).
3. Manuel (émulateur Android, backend dev) :
   - Login → onglet Messages → liste affiche **nom + photo + aperçu** réels (plus « Participant {id} »).
   - Tap conversation → **le chat s'ouvre** (plus « page introuvable »), en-tête correct.
   - Envoyer texte → bulle **à droite** (isMe), passe `sending`→`sent`.
   - L'autre tape → indicateur « typing » ; statut en ligne se met à jour (WS presence).
   - Envoyer média (compte premium) → upload signed-URL → bulle média ; compte non-premium → prompt premium (402/403).
   - Menu ⋮ → Bloquer (match dissous, retour liste) ; Signaler (motif → succès).
   - Pagination : remonter charge les messages plus anciens (`before_message_id`).
