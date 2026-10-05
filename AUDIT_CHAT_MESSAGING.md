# Audit complet du module Chat / Messagerie — HIVMeet

**Date :** 2026-07-09  
**Auditeur :** GitHub Copilot (glm-5.2:cloud)  
**Périmètre :** Toutes les fonctionnalités liées au chat et aux échanges de messages entre utilisateurs (frontend Flutter + backend Django + contrats API + WebSocket temps réel)  
**Sources consultées :**  
- Frontend : `lib/presentation/pages/chat/`, `lib/presentation/widgets/chat/`, `lib/presentation/blocs/chat/`, `lib/core/services/chat_websocket_service.dart`, `lib/data/datasources/remote/messaging_api.dart`, `lib/data/repositories/message_repository_impl.dart`, `lib/domain/entities/message.dart`, `lib/domain/usecases/chat/`, `lib/presentation/pages/conversations/`, `lib/presentation/blocs/conversations/`  
- Backend : `D:\Projets\HIVMeet\env\hivmeet_backend\messaging\` (models, views, serializers, services, consumers, signals, urls)  
- Spécifications : `docs/FRONTEND_MESSAGING_API.md`, `guides/MESSAGES_BACKEND_*.md`

---

## Table des matières

1. [Résumé exécutif](#1-résumé-exécutif)
2. [Inventaire des fonctionnalités](#2-inventaire-des-fonctionnalités)
3. [Fonctionnalités implémentées et fonctionnelles](#3-fonctionnalités-implémentées-et-fonctionnelles)
4. [Fonctionnalités implémentées mais incomplètes ou défectueuses](#4-fonctionnalités-implémentées-mais-incomplètes-ou-défectueuses)
5. [Fonctionnalités inexistantes ou non implémentées](#5-fonctionnalités-inexistantes-ou-non-implémentées)
6. [Audit de conformité aux spécifications](#6-audit-de-conformité-aux-spécifications)
7. [Audit de qualité et règles de l'art](#7-audit-de-qualité-et-règles-de-lart)
8. [Synthèse par sévérité](#8-synthèse-par-sévérité)
9. [Recommandations priorisées](#9-recommandations-priorisées)

---

## 1. Résumé exécutif

Le module de messagerie d'HIVMeet présente une **architecture globalement saine** (Clean Architecture, BLoC, repositories, usecases, WebSocket), mais souffre de **plusieurs défauts fonctionnels notables** qui dégradent l'expérience utilisateur réelle malgré un état « apparemment fonctionnel ».

**Verdict global :** ⚠️ **Fonctionnel mais non conforme aux conventions de chat** — l'échange de messages texte fonctionne de bout en bout, mais l'ordre d'affichage est inversé, les bulles sont collées aux bords, plusieurs fonctionnalités premium sont inactives, et des chemins critiques ne sont pas câblés.

| Catégorie | Nombre | Critique |
|-----------|--------|----------|
| ✅ Fonctionnelles à 100% | 3 | — |
| ⚠️ Implémentées mais défectueuses/incomplètes | 9 | 3 |
| ❌ Inexistantes/non implémentées | 8 | 2 |

---

## 2. Inventaire des fonctionnalités

### 2.1 Fonctionnalités attendues (d'après les specs `FRONTEND_MESSAGING_API.md`)

| # | Fonctionnalité | Type | Statut |
|---|----------------|------|--------|
| F1 | Liste des conversations | Gratuit | ⚠️ |
| F2 | Messages d'une conversation (pagination) | Gratuit | ⚠️ |
| F3 | Envoi de message texte | Gratuit | ⚠️ |
| F4 | Envoi de média (image/vidéo/audio) | Premium | ❌ |
| F5 | Marquer comme lu | Gratuit | ⚠️ |
| F6 | Suppression de message | Gratuit | ⚠️ |
| F7 | Indicateur de frappe (typing) | Gratuit | ⚠️ |
| F8 | Statut de présence (online/offline) | Gratuit | ⚠️ |
| F9 | Appels audio/vidéo (WebRTC) | Premium | ❌ |
| F10 | Réception temps réel WebSocket | Gratuit | ⚠️ |
| F11 | Recherche de conversations | Gratuit | ❌ |
| F12 | Blocage / signalement d'utilisateur | Gratuit | ⚠️ |
| F13 | Réactions aux messages | Futur | ❌ |
| F14 | Messages vocaux | Premium | ❌ |
| F15 | GIFs / stickers | Premium | ❌ |
| F16 | Suppression de conversation | Gratuit | ❌ |
| F17 | Notifications push (nouveau message) | Gratuit | ⚠️ |
| F18 | Indicateur "dernière activité" | Gratuit | ⚠️ |
| F19 | Optimistic update (envoi) | Technique | ✅ |
| F20 | Déduplication via `client_message_id` | Technique | ✅ |
| F21 | Reconnexion WebSocket automatique | Technique | ❌ |

---

## 3. Fonctionnalités implémentées et fonctionnelles

### ✅ F19 — Optimistic update à l'envoi de message texte

**Statut :** Fonctionnel à 100%, conforme aux règles de l'art.

**Détail :** Le `ChatBloc._onSendTextMessage` (et `_onSendMediaMessage`) crée un message optimiste avec `status: MessageStatus.sending`, l'ajoute immédiatement à `_allMessages`, émet l'état, puis envoie réellement. En cas de succès, le message optimiste est remplacé par le message serveur (via `_replaceOptimisticMessage`). En cas d'échec, le message est marqué `MessageStatus.failed` (rollback partiel — voir §4.4).

**Fichiers :** `lib/presentation/blocs/chat/chat_bloc.dart` lignes ~190-260.

### ✅ F20 — Déduplication via `client_message_id`

**Statut :** Fonctionnel à 100%, bien implémenté de bout en bout.

**Détail :** Le frontend génère un `clientMessageId` unique (`client_{conversationId}_{microseconds}`). Le backend vérifie l'existence avant création (`MessageService.send_message` — `existing = Message.objects.filter(match=match, client_message_id=client_message_id).first()`). Le WebSocket consumer et le signal `post_save` propagent l'événement avec le `client_message_id`, et le `ChatBloc._onWsMessageReceived` effectue la correspondance pour remplacer le message optimiste.

**Fichiers :** `lib/presentation/blocs/chat/chat_bloc.dart` (`_onWsMessageReceived`), backend `messaging/services.py`, `messaging/signals.py`, `messaging/consumers.py`.

### ✅ F3 (partiel) — Envoi de message texte — chemin REST

**Statut :** Fonctionnel de bout en bout via REST.

**Détail :** Le texte saisie dans `MessageInput` déclenche `SendTextMessageEvent` → BLoC → `SendTextMessage` usecase → `MessageRepositoryImpl.sendMessage` → `MessagingApi.sendTextMessage` (`POST /conversations/{id}/messages/`). Le backend valide, crée le message, déclenche le signal `post_save` qui diffuse via WebSocket et envoie une notification push.

**Caveat :** Voir §4.1 pour le bug d'ordre et §4.2 pour le bug de marges — ces défauts ne concernent que l'affichage, pas l'envoi lui-même.

---

## 4. Fonctionnalités implémentées mais incomplètes ou défectueuses

### 🔴 CRITIQUE — 4.1 Ordre d'affichage des messages inversé

**Sévérité :** 🔴 Critique (UX)  
**Spécification :** `FRONTEND_MESSAGING_API.md` §2 — *"Pagination inverse (messages récents en bas)"*

**Problème :** Les messages s'affichent **du plus récent au plus ancien** (haut → bas), ce qui est l'inverse de **toutes** les conventions d'interfaces de chat (WhatsApp, Telegram, Messenger, iMessage, etc.) où le plus ancien est en haut et le plus récent en bas.

**Cause racine :**

1. **Backend** (`messaging/services.py`, `get_conversation_messages`) :  
   ```python
   query = query.order_by('-created_at')  # Plus récent d'abord
   messages = list(query[:limit])
   ```
   Le backend renvoie les messages triés du plus récent au plus ancien.

2. **Frontend** (`message_repository_impl.dart`, `getMessages`) :  
   ```dart
   final messages = list.map(_mapJsonToMessage).toList();
   ```
   Les messages sont stockés dans l'ordre reçu (récent → ancien), **sans inversion**.

3. **BLoC** (`chat_bloc.dart`, `_onLoadConversation`) :  
   ```dart
   _allMessages = page.messages;  // Stocké tel quel
   ```

4. **UI** (`chat_page.dart`, `_buildMessagesList`) :  
   ```dart
   ListView.builder(
     itemCount: messages.length + ...,
     itemBuilder: (context, index) {
       final message = messages[index];  // index 0 = plus récent
   ```

**Conséquence :** Le `ListView.builder` affiche le message le plus récent en premier (en haut). Or, dans un chat, l'utilisateur s'attend à voir l'historique défiler vers le haut et les nouveaux messages apparaître en bas. Le `_scrollToBottom()` (qui doit amener au message le plus récent) défile vers le bas de la liste qui contient en réalité le message le plus ancien.

**Pagination aussi cassée :** `_onLoadMoreMessages` insère les messages plus anciens **au début** de `_allMessages` (`_allMessages = [...page.messages, ..._allMessages]`), ce qui est correct pour de la pagination inverse, mais comme l'affichage n'est pas inversé, les messages chargés apparaissent en bas (après les plus récents) — comportement incohérent.

**Correction attendue :** Le frontend doit inverser l'ordre après réception (`messages.reversed.toList()`) OU le backend doit renvoyer `order_by('created_at')` (plus ancien d'abord) pour l'endpoint de consultation. La convention la plus répandue : le backend renvoie les plus récents d'abord pour la pagination par curseur, et le **frontend inverse** avant affichage.

---

### 🔴 CRITIQUE — 4.2 Marges horizontales des bulles de messages absentes

**Sévérité :** 🔴 Critique (UX)  
**Spécification :** Convention universelle des interfaces de chat — les bulles ne doivent pas toucher les bords de l'écran.

**Problème :** Les bulles de messages sont **collées aux bords gauche/droit de l'écran**, sans aucune marge horizontale.

**Cause racine :** `lib/presentation/widgets/chat/message_bubble.dart` :
```dart
Container(
  margin: EdgeInsets.symmetric(vertical: AppSpacing.xs),  // ← pas de horizontal !
  ...
)
```

Le `Align` qui enveloppe le `Container` n'ajoute aucun `padding` horizontal. Résultat : la bulle touche physiquement le bord de l'écran (0px de marge gauche pour les messages reçus, 0px de marge droite pour les messages envoyés).

**Correction attendue :**
```dart
margin: EdgeInsets.symmetric(
  vertical: AppSpacing.xs,
  horizontal: AppSpacing.md,  // 16.0 — marge standard
),
```
Ou utiliser un `Padding` avec marge asymétrique (ex: 8px du côté de l'expéditeur, 16px de l'autre côté), comme le font WhatsApp/iMessage.

---

### 🔴 CRITIQUE — 4.3 Le marquage automatique "comme lu" n'est jamais déclenché côté frontend

**Sévérité :** 🔴 Critique (fonctionnalité annoncée non opérationnelle)  
**Spécification :** `FRONTEND_MESSAGING_API.md` §5 — *"Appel automatique quand le message devient visible"* ; doc usecase `mark_message_as_read.dart` — *"généralement appelé automatiquement quand l'utilisateur voit le message"*.

**Problème :** Aucun événement `MarkAsReadEvent` n'est jamais dispatché par l'UI. Le `ChatBloc` a bien un handler `_onMarkAsRead`, mais **aucun widget ne l'invoque**. La détection de visibilité des messages (via `VisibilityDetector` ou équivalent) n'est pas implémentée.

**Conséquence :** Les messages reçus ne sont jamais marqués comme lus par le frontend. Le backend tente de compenser : `MessageService.get_conversation_messages` marque automatiquement comme lus les messages reçus non lus lors de la récupération. Mais :
- Les messages reçus via **WebSocket** (temps réel) ne sont jamais marqués comme lus.
- Le compteur de non-lus dans la liste des conversations ne se met à jour qu'au prochain rechargement de la conversation.
- L'expéditeur ne reçoit jamais la notification "message lu" en temps réel.

**Fichiers concernés :** `lib/presentation/pages/chat/chat_page.dart` (aucun `VisibilityDetector`), `lib/presentation/blocs/chat/chat_bloc.dart` (handler présent mais non appelé).

---

### 🟠 MAJEUR — 4.4 Échec d'envoi : pas de retry ni de bouton "réessayer"

**Sévérité :** 🟠 Majeur  
**Spécification :** `FRONTEND_MESSAGING_API.md` §3 — *"Retry automatique avec backoff exponentiel"* ; *"États visuels : envoi, envoyé, livré, lu, échec"*.

**Problème :** En cas d'échec d'envoi, le message est marqué `MessageStatus.failed` mais :
1. Aucun mécanisme de retry automatique (backoff exponentiel) n'est implémenté dans le BLoC.
2. Aucun bouton "réessayer" n'est affiché sur la bulle échouée dans `MessageBubble`. Le callback `onDelete` est présent mais pas de callback `onRetry`.
3. Le message échoué reste affiché sans interaction possible (sauf suppression via `onDelete`, qui n'est d'ailleurs câblé que sur un long-press implicite non documenté).

**Fichiers :** `lib/presentation/blocs/chat/chat_bloc.dart` (pas de logique de retry), `lib/presentation/widgets/chat/message_bubble.dart` (pas de UI d'état failed).

---

### 🟠 MAJEUR — 4.5 Pas de reconnexion WebSocket automatique

**Sévérité :** 🟠 Majeur (fiabilité temps réel)  
**Spécification :** `FRONTEND_MESSAGING_API.md` §Notifications — *"Reconnexion automatique en cas de déconnexion"*.

**Problème :** `ChatWebSocketService` n'implémente **aucune** logique de reconnexion. Lorsque la connexion WebSocket se ferme (timeout, coupure réseau, changement de réseau WiFi→4G), l'attribut `_socket` passe à `null` dans `_onDone`, et l'utilisateur perd la réception temps réel sans aucune tentative de reconnexion.

```dart
void _onDone() {
  if (kDebugMode) {
    debugPrint('[WS] Connection closed (intentional: $_intentionalClose)');
  }
  _socket = null;  // ← pas de retry
}
```

**Conséquence :** L'utilisateur doit quitter et réouvrir la conversation pour rétablir la connexion. Les messages envoyés via REST fonctionnent toujours, mais les messages entrants temps réel, les indicateurs de frappe et les mises à jour de présence sont perdus.

**Fichiers :** `lib/core/services/chat_websocket_service.dart`.

---

### 🟠 MAJEUR — 4.6 Suppression de conversation : bouton présent mais désactivé

**Sévérité :** 🟠 Majeur  
**Spécification :** `BACKEND_MESSAGING_DELETE_CONVERSATION.md` indique une demande backend en attente.

**Problème :** Dans `conversations_page.dart`, `_confirmDeleteConversation` affiche une boîte de dialogue de confirmation, mais le bouton "Supprimer" affiche un `SnackBar` disant `"conversations.delete_unavailable"` au lieu de réellement supprimer. Aucun événement `DeleteConversation` n'existe dans le `ConversationsBloc`. Le backend n'expose pas non plus d'endpoint de suppression de conversation (seul le soft-delete de message existe).

**Fichiers :** `lib/presentation/pages/conversations/conversations_page.dart`, `lib/presentation/blocs/conversations/conversations_bloc.dart`.

---

### 🟠 MAJEUR — 4.7 Suppression de message : rollback incorrect

**Sévérité :** 🟠 Majeur  
**Problème :** Dans `ChatBloc._onDeleteMessage`, en cas d'échec de l'API de suppression, le rollback fait `emit(currentState.copyWith(messages: _allMessages))` — or `_allMessages` n'a **pas été modifié** avant l'appel. Le code retire d'abord le message de `optimisticMessages` (variable locale) et émet avec cette liste, mais ne met à jour `_allMessages` qu'en cas de succès. En cas d'échec, `emit(currentState.copyWith(messages: _allMessages))` restaure la liste originale (qui contient encore le message) — **correct en théorie**, mais le message reste affiché comme si rien n'avait échoué, sans feedback utilisateur (pas de toast d'erreur).

```dart
result.fold(
  (failure) {
    // Rollback si l'appel échoue
    if (kDebugMode) {
      debugPrint('[ChatBloc] Delete failed: ${failure.message}');
    }
    emit(currentState.copyWith(messages: _allMessages));
    // ← pas de HIVToast.showError() ici
  },
```

**Fichiers :** `lib/presentation/blocs/chat/chat_bloc.dart`.

---

### 🟡 MINEUR — 4.8 Indicateur de frappe : pas de timeout/débouncing côté frontend

**Sévérité :** 🟡 Mineur  
**Spécification :** `FRONTEND_MESSAGING_API.md` §9 — *"Timeout automatique après 3 secondes sans activité"* ; *"Debouncing pour éviter les appels excessifs"*.

**Problème :** `MessageInput._onTextChanged` déclenche `onStartTyping` / `onStopTyping` à **chaque changement de texte** sans débouncing. Le BLoC envoie alors un appel REST `POST /conversations/{id}/typing/` à chaque caractère tapé → flood d'appels API. Aucun timer de timeout n'envoie un `typing.stop` après 3 secondes d'inactivité.

Côté backend, le cache Redis a un TTL de 10 secondes sur le statut de frappe, ce qui évite l'indicateur permanent, mais le frontend spamme quand même l'API.

**Fichiers :** `lib/presentation/widgets/chat/message_input.dart`, `lib/presentation/blocs/chat/chat_bloc.dart` (`_onSetTypingStatus`).

---

### 🟡 MINEUR — 4.9 Envoi de média : le bouton media existe mais le flux est partiellement câblé

**Sévérité :** 🟡 Mineur (mais bloque une fonctionnalité premium)  
**Problème :** Dans `chat_page.dart`, `_buildInputArea` câble `onSendMessage` mais pour les types non-texte, un commentaire `// TODO: Handle media messages` indique que ce chemin n'est pas terminé. En revanche, `onSendMediaMessage` est bien câblé vers `SendMediaMessageEvent`. Le bouton média (`_buildMediaButton`) ouvre `_showMediaPicker` dont l'implémentation n'a pas été vérifiée en détail.

Le flux d'upload (`MessageRepositoryImpl.sendMessage` avec `mediaFile != null`) utilise le pattern "signed URL" : `generateMediaUploadUrl` → PUT direct vers GCS → `sendMessageWithMediaPath`. Le backend `generate_media_upload_url` génère une URL `https://storage.googleapis.com/hivmeet-media/...` mais **ne crée pas une vraie signed URL** (pas de signature V4, pas de token d'accès limité dans le temps). L'URL retournée est une URL publique non sécurisée.

**Fichiers :** `lib/data/repositories/message_repository_impl.dart` (`_uploadMediaToSignedUrl`), backend `messaging/views.py` (`generate_media_upload_url`).

---

### 🟡 MINEUR — 4.10 Recherche de conversations : recherche locale sur le dernier message uniquement

**Sévérité :** 🟡 Mineur  
**Problème :** `ConversationsBloc._onSearchConversations` filtre uniquement sur le contenu du `lastMessage?.content` — pas sur le nom du participant. Le commentaire `// TODO: Enrichir avec les noms des participants depuis ProfileRepository` indique que la recherche par nom n'est pas implémentée. La spec indique *"Recherche par nom de participant"*.

**Fichiers :** `lib/presentation/blocs/conversations/conversations_bloc.dart`.

---

## 5. Fonctionnalités inexistantes ou non implémentées

### ❌ F9 — Appels audio/vidéo (WebRTC)

**Statut :** ❌ Non implémenté côté frontend  
**Détail :** Les boutons d'appel sont présents dans l'AppBar du chat (`Icons.call`, `Icons.videocam`) mais `_initiateCall` affiche un toast `"chat.call_feature_coming_soon"`. Le backend a un modèle `Call` complet, des serializers, des vues (`initiate_call`, `answer_call`, `end_call`, `add_ice_candidate`) et un service `CallService`, mais aucune intégration WebRTC côté Flutter n'existe (pas de `flutter_webrtc`, pas de gestion SDP, pas de gestion ICE candidates côté frontend). Le consumer WebSocket gère bien `ice.candidate`, `offer`, `answer` mais le frontend `ChatWebSocketService` ne parse pas ces types (`WsEventType.unknown` par défaut).

**Fichiers manquants côté frontend :** Aucun fichier WebRTC. Le `MessagingApi` a bien les endpoints `initiateCall`, `answerCall`, `endCall`, `sendIceCandidate` mais ils ne sont appelés nulle part.

---

### ❌ F14 — Messages vocaux

**Statut :** ❌ Non implémenté  
**Détail :** `MessageInput` a un bouton micro qui active `_buildRecordingIndicator` avec un indicateur visuel (point rouge pulsant + durée `"0:00"` figée), mais :
- `_recordingDuration` est une variable `final` initialisée à `'0:00'` — jamais mise à jour.
- Aucun enregistrement audio réel (`AudioRecorder`, `flutter_sound`, etc.) n'est implémenté.
- `onRecordingStateChanged` est câblé mais le BLoC n'a aucun handler d'enregistrement.

---

### ❌ F15 — GIFs / Stickers

**Statut :** ❌ Non implémenté  
**Détail :** Les boutons GIF et stickers sont visibles uniquement si `widget.isPremium` est true, mais `_showGifPicker` et `_showStickerPicker` ne sont pas implémentés (méthodes référencées mais non lues — à vérifier, mais probablement vides ou TODO).

---

### ❌ F13 — Réactions aux messages

**Statut :** ❌ Modèle backend existe, frontend non implémenté  
**Détail :** Le backend a un modèle `MessageReaction` (emoji, user, message) mais aucun endpoint n'est exposé dans `messaging/urls.py`. Le frontend a un champ `reactions` dans l'entité `Message` mais aucune UI pour ajouter/afficher des réactions.

---

### ❌ F11 — Recherche de conversations (côté backend)

**Statut :** ❌ Non implémenté  
**Détail :** Aucun endpoint de recherche côté backend. La recherche est locale (voir §4.10).

---

### ❌ F21 — Reconnexion WebSocket automatique

**Statut :** ❌ Non implémenté (voir §4.5)

---

### ❌ F16 — Suppression/archivage de conversation

**Statut :** ❌ Non implémenté (voir §4.6)  
**Détail :** Le backend n'a pas d'endpoint. Le frontend a un bouton qui affiche "non disponible".

---

### ❌ F4 — Envoi de média (partiellement)

**Statut :** ❌ Partiellement — flux upload non sécurisé (voir §4.9)

---

## 6. Audit de conformité aux spécifications

### 6.1 Contrats API — Frontend vs Backend

| Endpoint | Frontend (`MessagingApi`) | Backend (`urls.py` + `views.py`) | Conformité |
|----------|---------------------------|----------------------------------|------------|
| `GET /conversations/` | ✅ `getConversations` | ✅ `ConversationListView` | ⚠️ Paramètres divergents : frontend envoie `page`, `page_size`, `status` ; backend lit `status` mais ignore `page`/`page_size` (pas de pagination côté backend — retourne tout) |
| `GET /conversations/{id}/messages/` | ✅ `getConversationMessages` | ✅ `conversation_messages` | ⚠️ Le param `before_message_id` est supporté côté backend mais le frontend l'appelle `beforeMessageId` → envoyé comme `before_message_id` (correct). Mais `limit` côté backend n'est pas lu depuis `limit`, c'est `page_size` qui est utilisé. |
| `POST /conversations/{id}/messages/` | ✅ `sendTextMessage` | ✅ `conversation_messages` (POST) | ✅ Conforme. Payload : `client_message_id`, `content`, `type` → backend attend `client_message_id`, `content`, `type`. |
| `POST /conversations/{id}/messages/media/` | ✅ `sendMediaMessage` | ✅ `SendMediaMessageView` | ⚠️ Le frontend envoie `media_file`, `media_type`, `client_message_id`, `text` → backend attend `media_file`, `media_type`, `client_message_id`, `text`. Conforme, mais l'endpoint alternatif `sendMessageWithMediaPath` (upload signé) envoie `media_file_path_on_storage` qui est attendu par le backend (`media_file_path_on_storage`). |
| `PUT /conversations/{id}/messages/mark-as-read/` | ✅ `markMessageAsRead` | ✅ `mark_messages_as_read` | ⚠️ Le frontend envoie `last_read_message_id` → backend attend `last_read_message_id` (correct via `MarkAsReadSerializer`). Mais le frontend appelle aussi `markSingleMessageAsRead` (`PUT .../{message_id}/read/`) qui existe côté backend — non utilisé par le frontend (voir §4.3). |
| `DELETE /conversations/{id}/messages/{message_id}/` | ✅ `deleteMessage` | ✅ `delete_message` | ✅ Conforme |
| `POST /conversations/{id}/typing/` | ✅ `setTypingStatus` | ✅ `typing_indicator` | ✅ Conforme |
| `GET /conversations/{id}/presence/` | ✅ `getPresence` | ✅ `conversation_presence` | ✅ Conforme |
| `POST /conversations/generate-media-upload-url/` | ✅ `generateMediaUploadUrl` | ✅ `generate_media_upload_url` | ⚠️ Le backend ne génère pas une vraie signed URL (voir §4.9) |
| `POST /calls/initiate` | ✅ `initiateCall` | ✅ `initiate_call` | ❌ Non appelé par le frontend |
| `POST /calls/{id}/answer` | ✅ `answerCall` | ✅ `answer_call` | ❌ Non appelé |
| `POST /calls/{id}/terminate` | ✅ `endCall` | ✅ `end_call` | ❌ Non appelé |
| `POST /calls/{id}/ice-candidate` | ✅ `sendIceCandidate` | ✅ `add_ice_candidate` | ❌ Non appelé |
| `POST /conversations/calls/initiate-premium/` | ✅ `initiatePremiumCall` | ✅ `InitiatePremiumCallView` | ❌ Non appelé |

### 6.2 Contrats WebSocket

| Événement | Frontend (`ChatWebSocketService`) | Backend (`ConversationConsumer`) | Conformité |
|-----------|----------------------------------|--------------------------------|------------|
| `message.created` | ✅ Parse → `WsEventType.messageCreated` | ✅ `message_created` handler | ⚠️ Le payload backend ne contient pas `media_url`, `media_thumbnail_url`, `media_type` — le frontend les lit (`event.data['media_url']`) mais obtient `null`. Les messages média reçus en temps réel sont donc incomplets. |
| `typing.indicator` | ✅ Parse → `WsEventType.typingIndicator` | ✅ `typing_indicator` handler | ✅ Conforme |
| `presence.update` | ✅ Parse → `WsEventType.presenceUpdate` | ✅ `presence_update` handler | ✅ Conforme |
| `ping`/`pong` | ✅ Envoie ping, parse pong | ✅ Répond pong | ✅ Conforme |
| `message.send` | ✅ `sendTextMessage` | ✅ `_handle_message_send` | ⚠️ Le frontend envoie via WebSocket mais le BLoC envoie aussi via REST (double envoi possible). La déduplication via `client_message_id` protège, mais c'est redondant. |
| `ice.candidate` | ❌ Non géré par `ChatWebSocketService` | ✅ `_handle_ice_candidate` | ❌ Manquant |
| `webrtc.offer` | ❌ Non géré | ✅ `_handle_offer` | ❌ Manquant |
| `webrtc.answer` | ❌ Non géré | ✅ `_handle_answer` | ❌ Manquant |
| `incoming_call` | ❌ Non géré | ✅ `incoming_call` | ❌ Manquant |
| `call_update` | ❌ Non géré | ✅ `call_update` | ❌ Manquant |

### 6.3 Discrepances de structure de réponse

**Conversation list** :  
- Spec : `{"conversations": [...], "pagination": {...}}`  
- Backend réel : `{"count", "next", "previous", "results": [...], ...}` (DRF standard paginated)  
- Frontend : lit `payload['results']` ✅ (correct vs backend réel, mais divergent de la spec écrite)

**Messages list** :  
- Spec : `{"messages": [...], "pagination": {...}}`  
- Backend réel : `{"count", "next", "previous", "results": [...], "has_more", "show_premium_prompt"}`  
- Frontend : lit `payload['results']` ✅

---

## 7. Audit de qualité et règles de l'art

### 7.1 Architecture — Conformité Clean Architecture

| Couche | Conformité | Notes |
|--------|------------|-------|
| Presentation (Pages, Widgets, BLoC) | ✅ | `ChatPage`, `MessageBubble`, `MessageInput`, `ChatBloc` bien séparés |
| Application (BLoC events/states) | ✅ | Events/states en `part` files, immutables, bien typés |
| Domain (Entities, UseCases, Repository interfaces) | ✅ | `Message`, `Conversation`, `MessageRepository` abstrait, usecases single-responsibility |
| Data (Models, DataSources, RepositoryImpl) | ⚠️ | `MessageModel` (`.g.dart`) existe mais n'est pas utilisé — `Message.fromJson` fait office de modèle. Pas de `MessageModel` distinct de l'entité. Violation mineure du pattern (models devraient étendre entities). |
| Injection (`get_it`/`injectable`) | ✅ | `ChatBloc`, `ChatWebSocketService`, `MessageRepository` enregistrés correctement |

### 7.2 Gestion des erreurs

| Aspect | Conformité | Notes |
|--------|------------|-------|
| `Either<Failure, Success>` (dartz) | ✅ | Tous les usecases et repositories retournent `Either` |
| Failure hierarchy | ✅ | `ServerFailure`, `NetworkFailure`, `AuthFailure`, `PremiumFailure` |
| Erreurs WebSocket | ⚠️ | Le `ChatWebSocketService` émet des `WsEvent(type: error)` mais le BLoC se contente de `debugPrint` — pas de feedback utilisateur |
| Messages d'erreur i18n | ⚠️ | Le `SendTextMessage` usecase retourne un message **hardcodé en français** : `"Le message ne peut pas être vide"`, `"Le fichier média n'existe pas"`, `"Le fichier est trop volumineux (max 50 MB)"`. Violation de la règle i18n. |

### 7.3 Internationalisation (i18n)

| Aspect | Conformité | Notes |
|--------|------------|-------|
| Clés ARB utilisées | ✅ | `chat.typing`, `chat.online`, `chat.last_seen`, etc. |
| Strings hardcodées | ❌ | `SendTextMessage` et `SendMediaMessage` contiennent des messages d'erreur en français hardcodés. `MessageInput._buildRecordingIndicator` utilise `LocalizationService.translate('chat.recording', params: {})` avec params vides (la clé `chat.recording` ne prend probablement pas de params). |
| Clés manquantes probables | ⚠️ | `chat.call_feature_coming_soon`, `chat.profile_unavailable`, `chat.action_error`, `chat.block_success`, `chat.report_success` — à vérifier dans les fichiers ARB. |

### 7.4 Sécurité

| Aspect | Conformité | Notes |
|--------|------------|-------|
| Auth WebSocket (JWT in query string) | ⚠️ | Le token JWT est passé en query string (`?token=`) — acceptable pour WS mais le token peut apparaître dans les logs serveur. Le backend supporte aussi le header `Authorization` (plus sûr). Le frontend n'utilise que la query string. |
| Sanitisation contenu | ✅ | Backend : `strip_tags` + patterns `DISALLOWED_MESSAGE_PATTERNS` (anti-XSS). Frontend : pas de sanitisation (affichage via `Text` qui échappe par défaut). |
| Upload média non signé | ❌ | Le backend `generate_media_upload_url` retourne une URL GCS publique sans signature — n'importe qui avec l'URL peut uploader. À corriger côté backend. |
| Soft-delete | ✅ | Implémenté correctement (`is_deleted_by_sender`, `is_deleted_by_recipient`) avec filtrage dans les queries. |

### 7.5 Performance

| Aspect | Conformité | Notes |
|--------|------------|-------|
| Pagination | ⚠️ | Frontend : pagination par curseur côté messages, pagination par page côté conversations. Backend conversations : pas de pagination réelle (retourne tout). |
| Cache présence | ✅ | Backend utilise Redis avec TTL. |
| N+1 queries | ⚠️ | `ConversationSerializer.get_other_user` fait une query par conversation pour la photo principale (`other_user.profile.photos.filter(is_main=True).first()`) — N+1 potentiel. Le queryset fait `select_related('user1__profile', 'user2__profile')` mais pas `prefetch_related('user1__profile__photos', ...)`. |
| Optimistic update | ✅ | Implémenté correctement (voir §3). |

### 7.6 Tests

| Fichier | Couverture | Notes |
|---------|------------|-------|
| `test/presentation/blocs/chat/chat_bloc_test.dart` | Existe | À vérifier en détail |
| `test/domain/usecases/chat/*.dart` | Existe (5 fichiers) | `get_messages`, `send_text_message`, `send_media_message`, `mark_message_as_read`, `delete_message` |
| `test/domain/entities/messaging_contract_mapping_test.dart` | Existe | Test de mapping DTO |
| `test/presentation/blocs/conversations/conversations_bloc_test.dart` | Existe | — |
| Tests WebSocket | ❌ | Aucun test pour `ChatWebSocketService` |
| Tests d'intégration chat | ❌ | Aucun test d'intégration du flux complet |

---

## 8. Synthèse par sévérité

### 🔴 Critique (3)

| # | Problème | Impact |
|---|----------|--------|
| 4.1 | Ordre des messages inversé | UX inacceptable — ne respecte aucune convention de chat. Les nouveaux messages apparaissent en haut, l'historique en bas. |
| 4.2 | Marges horizontales des bulles absentes | Les bulles sont collées aux bords de l'écran — aspect non professionnel, lecture difficile. |
| 4.3 | Marquage "comme lu" jamais déclenché | Compteurs de non-lus incorrects, pas de feedback "lu" en temps réel pour l'expéditeur. |

### 🟠 Majeur (4)

| # | Problème | Impact |
|---|----------|--------|
| 4.4 | Pas de retry ni bouton "réessayer" sur échec d'envoi | Message bloqué, pas de récupération. |
| 4.5 | Pas de reconnexion WebSocket automatique | Perte du temps réel en cas de coupure réseau. |
| 4.6 | Suppression de conversation désactivée | Fonctionnalité annoncée mais inopérante. |
| 4.7 | Suppression de message : pas de feedback d'erreur | Échec silencieux, utilisateur confus. |

### 🟡 Mineur (3)

| # | Problème | Impact |
|---|----------|--------|
| 4.8 | Typing indicator sans débouncing | Spam API, performance dégradée. |
| 4.9 | Upload média non signé | Faille de sécurité + fonctionnalité premium partiellement cassée. |
| 4.10 | Recherche de conversations incomplète | Recherche par nom non fonctionnelle. |

### ❌ Non implémenté (8)

| # | Fonctionnalité | Impact business |
|---|----------------|----------------|
| F9 | Appels audio/vidéo | Premium feature majeure manquante. |
| F14 | Messages vocaux | Premium feature manquante. |
| F15 | GIFs / Stickers | Premium feature manquante. |
| F13 | Réactions aux messages | Engagement utilisateur réduit. |
| F11 | Recherche backend | Scalabilité de la recherche. |
| F21 | Reconnexion WS | Fiabilité temps réel. |
| F16 | Suppression/archivage conversation | Gestion de vie privée incomplète. |
| F4 | Upload média sécurisé | Sécurité + premium. |

---

## 9. Recommandations priorisées

### P0 — Corrections immédiates (bloquant pour release)

1. **Corriger l'ordre des messages** (§4.1) : Inverser `_allMessages` après chargement dans `_onLoadConversation` (`_allMessages = page.messages.reversed.toList()`) et ajuster la pagination (`_onLoadMoreMessages` doit insérer au début et préserver l'ordre chronologique). Alternative : faire trier le backend par `created_at` ascendant pour l'endpoint de consultation.

2. **Ajouter les marges horizontales aux bulles** (§4.2) : Modifier `MessageBubble` pour `margin: EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.md)` ou utiliser un padding asymétrique.

3. **Implémenter le marquage automatique comme lu** (§4.3) : Ajouter un `VisibilityDetector` (package `visibility_detector`) sur chaque `MessageBubble` dans `_buildMessagesList`, dispatcher `MarkAsReadEvent` quand un message reçu devient visible, avec un batch pour éviter les appels excessifs.

### P1 — Corrections importantes (prochaine itération)

4. **Ajouter le retry + bouton "réessayer"** (§4.4) : Implémenter un backoff exponentiel dans le BLoC pour les messages `failed`, ajouter un `onRetry` callback sur `MessageBubble` avec un bouton/icône "réessayer".

5. **Implémenter la reconnexion WebSocket** (§4.5) : Dans `ChatWebSocketService._onDone`, si `!_intentionalClose`, démarrer un timer de reconnexion avec backoff exponentiel (1s, 2s, 4s, 8s, max 30s). Annuler à la fermeture intentionnelle.

6. **Corriger le rollback de suppression** (§4.7) : Ajouter `HIVToast.showError()` dans le handler d'échec de `_onDeleteMessage`.

7. **Implémenter le débouncing du typing** (§4.8) : Ajouter un `Timer` dans `MessageInput` qui envoie `onStopTyping` après 3 secondes d'inactivité. Debouncer l'envoi de `onStartTyping` (une seule fois au début de la frappe).

8. **Corriger les strings hardcodées** (§7.3) : Remplacer les messages français hardcodés dans `SendTextMessage` et `SendMediaMessage` par des codes d'erreur que le BLoC/UI traduit via `LocalizationService`.

### P2 — Améliorations (backlog)

9. **Câbler la suppression de conversation** (§4.6) : Créer l'endpoint backend `DELETE /conversations/{id}/` (soft-archive) + ajouter `DeleteConversationEvent` au `ConversationsBloc`.

10. **Sécuriser l'upload média** (§4.9) : Le backend doit générer une vraie signed URL V4 GCS. Le frontend doit valider le type MIME avant upload.

11. **Compléter le payload WebSocket `message.created`** (§6.2) : Le signal `post_save` doit inclure `media_url`, `media_thumbnail_url`, `media_type` pour que les messages média reçus en temps réel soient complets.

12. **Implémenter la recherche par nom** (§4.10) : Soit enrichir les conversations côté frontend avec les profils, soit ajouter un endpoint backend `GET /conversations/?search=nom`.

### P3 — Fonctionnalités futures (premium roadmap)

13. **Appels audio/vidéo WebRTC** (F9) : Intégrer `flutter_webrtc`, câbler les endpoints REST + WebSocket signaling, UI d'appel entrant/sortant.

14. **Messages vocaux** (F14) : Intégrer un recorder (`flutter_sound` ou `record`), uploader en tant que `MessageType.voice`, UI de lecteur audio dans `MessageBubble`.

15. **Réactions aux messages** (F13) : Exposer les endpoints backend + UI long-press sur bulle pour ajouter une réaction emoji.

16. **GIFs / Stickers** (F15) : Intégrer Giphy API ou bibliothèque de stickers locale.

---

## Annexe A — Fichiers audités

### Frontend
- `lib/presentation/pages/chat/chat_page.dart` (891 lignes)
- `lib/presentation/widgets/chat/message_bubble.dart` (96 lignes)
- `lib/presentation/widgets/chat/message_input.dart` (300+ lignes)
- `lib/presentation/blocs/chat/chat_bloc.dart` (700+ lignes)
- `lib/presentation/blocs/chat/chat_event.dart`
- `lib/presentation/blocs/chat/chat_state.dart`
- `lib/core/services/chat_websocket_service.dart` (182 lignes)
- `lib/data/datasources/remote/messaging_api.dart` (220+ lignes)
- `lib/data/repositories/message_repository_impl.dart` (500+ lignes)
- `lib/domain/entities/message.dart` (330+ lignes)
- `lib/domain/repositories/message_repository.dart`
- `lib/domain/usecases/chat/get_messages.dart`
- `lib/domain/usecases/chat/send_text_message.dart`
- `lib/domain/usecases/chat/send_media_message.dart`
- `lib/domain/usecases/chat/mark_message_as_read.dart`
- `lib/domain/usecases/chat/delete_message.dart`
- `lib/presentation/pages/conversations/conversations_page.dart` (500+ lignes)
- `lib/presentation/blocs/conversations/conversations_bloc.dart` (290+ lignes)
- `lib/core/config/app_config.dart`
- `lib/core/config/constants.dart`
- `lib/injection.dart`

### Backend
- `messaging/models.py` (Message, MessageReaction, Call, TypingIndicator)
- `messaging/views.py` (ConversationListView, conversation_messages, mark_messages_as_read, mark_single_message_as_read, delete_message, typing_indicator, conversation_presence, generate_media_upload_url, initiate_call, answer_call, add_ice_candidate, end_call, SendMediaMessageView, InitiatePremiumCallView)
- `messaging/serializers.py` (MessageSerializer, ConversationSerializer, SendMessageSerializer, etc.)
- `messaging/services.py` (MessageService, CallService)
- `messaging/consumers.py` (ConversationConsumer WebSocket)
- `messaging/signals.py` (post_save handlers pour Message et Call)
- `messaging/urls.py`
- `hivmeet_backend/asgi.py` (routing WebSocket)

---

*Fin du rapport.*