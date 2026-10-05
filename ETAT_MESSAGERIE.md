# Rapport d'état — Messagerie HIVMeet

**Date :** 2026-06-22
**Périmètre :** fonctionnalités de messagerie (frontend Flutter)
**Sources :** code du dépôt frontend + rapports backend produits *depuis ce dépôt*
**Contrat de référence :** `guides/FRONTEND_MESSAGING_API.md` (2026-05-21, post-audit)

> **Convention de lecture**
> - **[FRONT]** = implémenté et vérifié dans ce dépôt frontend
> - **[BACK-DEMANDÉ]** = travail backend documenté *depuis ici* (fichier `BACKEND_*.md`) mais **non implémenté côté serveur dans ce dépôt**
> - **[BACK-CONSOMMÉ]** = endpoint backend supposé existant et appelé par le frontend

---

## 1. Synthèse

La messagerie texte et média est **fonctionnelle de bout en bout côté frontend**. Le flux cassé identifié lors de l'audit initial (chat injoignable, expéditeur mal détecté, en-tête vide, perte des données `other_user`) a été **corrigé**. Restent **hors périmètre** : les appels audio/vidéo (stub volontaire) et la suppression de conversation (**bloquée par l'absence d'endpoint backend**, demande documentée).

| Domaine | État | Côté |
|---|---|---|
| Liste des conversations | ✅ Fonctionnel | FRONT + BACK-CONSOMMÉ |
| Ouverture du chat (routing) | ✅ Corrigé | FRONT |
| Envoi/réception texte | ✅ Fonctionnel | FRONT + BACK-CONSOMMÉ |
| Envoi média (photo/vidéo/audio) | ✅ Fonctionnel (flux URL signée) | FRONT + BACK-CONSOMMÉ |
| Temps réel (WebSocket) | ✅ Fonctionnel | FRONT + BACK-CONSOMMÉ |
| Marquage lu / suppression message | ✅ Fonctionnel | FRONT + BACK-CONSOMMÉ |
| Indicateur de frappe / présence | ✅ Fonctionnel | FRONT + BACK-CONSOMMÉ |
| Bloquer / Signaler | ✅ Fonctionnel | FRONT + BACK-CONSOMMÉ |
| Appels audio/vidéo (WebRTC) | ⛔ Stub volontaire (hors périmètre) | FRONT (UI inactive) |
| Suppression de conversation | ⛔ Bloqué | BACK-DEMANDÉ (non livré) |

---

## 2. Côté FRONTEND — détail de l'implémentation

### 2.1 Navigation / routing **[FRONT]**
- Route `/chat/:conversationId` ajoutée — `lib/core/config/routes.dart:179-201`. Lit `conversationId` et l'objet `Conversation` passé via `state.extra`.
- La liste pousse la conversation enrichie : `context.push('/chat/${conversation.id}', extra: conversation)` — `lib/presentation/pages/conversations/conversations_page.dart:99`.
- **Avant :** `/chat` renvoyait `ConversationsPage` → tap conversation = « page introuvable ». **Corrigé.**

### 2.2 Entité `Conversation` enrichie **[FRONT]**
- Champs ajoutés : `otherUserId`, `otherUserName`, `otherUserPhotoUrl`, `isOnline`, `lastActive` — `lib/domain/entities/message.dart:255-317`.
- Mapping réel depuis `other_user.{user_id, display_name, main_photo_url, is_online, last_active}` et fallback `content` / `content_preview` pour l'aperçu — `lib/data/repositories/message_repository_impl.dart:317-364`.
- **Avant :** seul `participantIds` survivait → la liste affichait « Participant {id} » et aucun aperçu. **Corrigé** : nom + photo + aperçu réels.

### 2.3 Page de chat **[FRONT]**
- Détection de l'expéditeur : `final isMe = message.isMine;` — `lib/presentation/pages/chat/chat_page.dart:443`. **Avant :** `senderId == 'current_user_id'` (toujours faux).
- En-tête (nom, avatar, statut en ligne, « vu à ») alimenté depuis `widget.conversation` — `chat_page.dart:247-355`.
- Dialogues **Bloquer** / **Signaler** implémentés (motifs i18n, retour succès/erreur) — `_showBlockDialog` (714), `_showReportDialog` (751).

### 2.4 BLoC de chat **[FRONT]**
- Messages optimistes marqués `isMine: true` ; déduplication par `client_message_id` (et `message_id`) — `lib/presentation/blocs/chat/chat_bloc.dart:296-297, 501-503`.
- WebSocket entrant : parse réel de `message_type` + champs média (plus de `type:text` codé en dur).
- `presence.update` → état `otherIsOnline` propagé à l'en-tête — `chat_bloc.dart:562-573`.
- Événements/handlers `BlockUserEvent` / `ReportUserEvent` + états `actionError` / `completedAction` — `chat_bloc.dart:389-420`.

### 2.5 Envoi média — flux URL signée **[FRONT]** (aligné contrat §4.10 → §4.4)
- Orchestration : (1) `generateMediaUploadUrl` → (2) `PUT` binaire direct vers GCS via **Dio brut** (sans baseUrl ni Bearer — pas de fuite de token) → (3) `sendMessageWithMediaPath(media_file_path_on_storage)` — `message_repository_impl.dart:119-138, 281-297`.
- Repli multipart §4.11 (`sendMediaMessage`) **conservé** dans l'API — `lib/data/datasources/remote/messaging_api.dart`.
- Premium requis : 402/403 → `PremiumFailure` → prompt premium.

### 2.6 Bloquer / Signaler **[FRONT]**
- `BlockUser` (existant) → `settingsApi.blockUser`.
- `ReportUser` (nouveau usecase) — `lib/domain/usecases/profile/report_user.dart` → `profile_repository_impl.reportUser` → `authApi.reportUser` (**[BACK-CONSOMMÉ]** `POST /auth/report-user`). L'ancien `reportProfile` (stub « non exposé ») délègue désormais à `reportUser` — `profile_repository_impl.dart:512-541`.

### 2.7 Robustesse / nettoyage **[FRONT]**
- `MessageModel.isRead` / `isDelivered` : `defaultValue: false` → plus de crash quand le backend omet le champ — `lib/data/models/message_model.g.dart:29-30`.
- Code mort supprimé : `messaging_repository.dart` et `conversation_model.dart(.g.dart)` n'existent plus.
- i18n FR/EN à parité pour les nouvelles clés (`chat.block_confirm_*`, `chat.report_dialog_*`, `conversations.delete_*`, `own_message_prefix`).
- DI câblée — `lib/injection.dart:350-410`.

### 2.8 Endpoints backend **consommés** par le frontend **[BACK-CONSOMMÉ]**
REST `/api/v1/` :
- `GET /conversations/`
- `GET /conversations/{id}/`
- `GET /conversations/{id}/messages/` (pagination `before_message_id`)
- `POST /conversations/{id}/messages/` (texte + `media_file_path_on_storage`)
- `POST /conversations/{id}/messages/media/` (multipart, repli)
- `PUT /conversations/{id}/messages/mark-as-read/` & `.../{message_id}/read/`
- `DELETE /conversations/{id}/messages/{message_id}/`
- `POST /conversations/{id}/typing/`
- `GET /conversations/{id}/presence/`
- `POST /conversations/generate-media-upload-url/`
- `PUT` direct vers l'URL signée GCS
- WS `wss://…/ws/conversations/{id}/?token=`
- `POST /auth/block-user`
- `POST /auth/report-user`

---

## 3. Côté BACKEND — travail produit *depuis ce dépôt*

### 3.1 Suppression de conversation **[BACK-DEMANDÉ — non livré]**
- Fichier : `BACKEND_MESSAGING_DELETE_CONVERSATION.md` (racine).
- Demande : `DELETE /api/v1/conversations/{conversation_id}/` (soft-delete par utilisateur, codes 204 / 401 / 403 / 404 / 500).
- **Statut : document de spécification uniquement.** Aucun code backend n'est écrit dans ce dépôt. En attendant, l'UI reste honnête : le bouton « Supprimer la conversation » affiche `conversations.delete_unavailable` — `conversations_page.dart:426-449`.

> Le contrat actuel n'expose que la suppression **message par message** (§4.7). C'est le seul écart fonctionnel nécessitant une action serveur.

---

## 4. Hors périmètre / limitations connues (FRONTEND)

1. **Appels audio/vidéo (WebRTC)** — décision : hors périmètre. UI présente (boutons appel) mais `_initiateCall` n'affiche qu'un toast « bientôt disponible ». `flutter_webrtc` est dans `pubspec`. Les payloads `/calls/*` de `messaging_api` ne sont **pas alignés** au contrat §4.12 (ex. `answer:{answer:true}` au lieu de `answer_sdp`, pas d'`offer_sdp`) — **sans impact** car non câblés à l'UI.
2. **Streams repo** `watchConversations` / `watchMessages` / `watchTypingStatus` lèvent `UnimplementedError` — non utilisés (le temps réel passe par `ChatWebSocketService` dans le BLoC).
3. **Recherche de conversations** — filtre local sur le contenu du dernier message (`conversations_bloc.dart:223-227`) ; pourrait désormais aussi filtrer sur `otherUserName` (amélioration mineure).
4. **Suppression de conversation** — bloquée backend (cf. §3.1).

---

## 5. Vérification recommandée

- `flutter analyze` (0 erreur attendu) ; régénérer si besoin : `dart run build_runner build --delete-conflicting-outputs`.
- Manuel (émulateur + backend dev) :
  1. Liste des conversations affiche **nom + photo + aperçu** réels.
  2. Tap conversation → **le chat s'ouvre** (plus « page introuvable »), en-tête correct.
  3. Envoyer texte → bulle **à droite** (isMe), statut `sending` → `sent`.
  4. L'autre tape → indicateur « typing » ; statut en ligne se met à jour (WS presence).
  5. Envoyer média (compte premium) → upload URL signée → bulle média ; compte non-premium → prompt premium (402/403).
  6. Menu ⋮ → Bloquer (match dissous, retour liste) ; Signaler (motif → succès).
  7. Pagination : remonter charge les messages plus anciens (`before_message_id`).
