# Audit complet — Page « Messages » HIVMeet (Frontend + Data/Domain + Backend)

**Date** : 2026-07-19
**Périmètre** : page Messages = liste des conversations + conversation ouverte (chat) + saisie/médias + blocage/signalement + présence/typing/notifications + suppression conversation.
**Objectif** : inventorier méthodiquement chaque objet et fonctionnalité, déterminer s'ils sont implémentés et fonctionnent réellement, produire un rapport auto-suffisant servant de **contexte d'entrée** à une session d'implémentation à 100 %.

---

## 0. Décisions de périmètre (important à lire avant implémentation)

L'utilisateur n'étant pas disponible pour clarifier, les décisions autonomes prudentes suivantes ont été prises, conformes aux règles du projet (`AI_AGENT_SHARED_RULES.md`, `.claude/rules/*`) :

| Décision | Choix | Justification |
|---|---|---|
| Sous-ensembles inclus | **Tous** sauf WebRTC | Ambition « 100 % » ; WebRTC exclu (voir ci-dessous) |
| Appels audio/vidéo WebRTC | **EXCLUSION délibérée** — stub « coming soon » conservé | Feature lourde (flutter_webrtc, signaling complet, media path, gestion durée/limite premium), pas de media path WebRTC backend exploitable, dépasse une seule session. Laissé en stub explicite. |
| Gaps backend (suppression conversation, generate-media-upload-url non signé, filtre unread, polling non-premium, reactions, E2E) | Frontend rendu prêt (gestion gracieuse) + production de fichiers `BACKEND_*.md` | Règle non négociable : « Si un problème est confirmé comme backend, créer `BACKEND_[TYPE]_[DESCRIPTION].md` » — pas de modification backend dans le frontend. |
| i18n FR/EN + tests widget/bloc | **Inclus** | i18n non négociable (shared rules) ; tests exigés (testing.md) |
| Langue du rapport | Français | Règle skill frontend-development |
| Source de vérité contrat API | Backend réel (`messaging/views.py`, `serializers.py`) > `API_DOCUMENTATION.md` > `docs/FRONTEND_MESSAGING_API.md` | `FRONTEND_MESSAGING_API.md` est **stale** (clés `participant`, `unread_count`, `message_type`, `PUT /calls/answer`… ne correspondent pas au backend). Le frontend a déjà été adapté au backend réel. |

---

## 1. Cartographie des objets de la page Messages

### 1.1 Arborescence des écrans

```
Messages (tab)
└── ConversationsPage (/conversations)
    ├── AppBar: titre + badge non-lu, cloche notifications, recherche, menu options
    ├── ConversationsSearchBar (toggle)
    ├── ListView conversations
    │   └── ConversationCard (widgets/conversations/)
    │       ├── photo profil (CachedNetworkImage)
    │       ├── nom + badge non-lu (bold si non lu)
    │       ├── aperçu dernier message (texte/média)
    │       └── timestamp + badge non-lu
    ├── EmptyConversationsView / Loading / Error
    ├── Pull-to-refresh
    ├── Infinite scroll (LoadMoreConversations à 90 %)
    └── Long-press → bottom sheet (Ouvrir, Marquer lu, Voir profil, Supprimer)
        └── _confirmDeleteConversation → SnackBar « delete_unavailable » (dead)
└── ChatPage (/chat/:conversationId)
    ├── AppBar: retour, avatar, nom, statut (typing/online/last seen), actions
    │   ├── Appel audio (Icons.call) → toast « coming soon » (WebRTC stub)
    │   ├── Appel vidéo (Icons.videocam) → toast « coming soon » (WebRTC stub)
    │   └── PopupMenu: profile / block / report
    ├── BlocConsumer<ChatBloc>
    │   ├── ChatLoading → HIVLoader
    │   ├── ChatLoaded empty → « It's a match! » + 2 quick-messages
    │   ├── ChatLoaded → Stack(ListView messages + FAB scroll-to-bottom)
    │   └── ChatError → toast
    ├── MessageBubble (texte/image only; video/voice/callLog/system → bulle vide)
    ├── MessageInput
    │   ├── Bouton média → MediaPicker (image/vidéo; non-image premium-gated)
    │   ├── Toggle emoji (~140 emojis hardcoded)
    │   ├── TextField (chat.type_message)
    │   ├── Boutons GIF/stickers (premium) → toast « coming soon » (dead)
    │   ├── Bouton envoi texte
    │   └── Bouton voix (long-press) → TODO recording cassé (envoie `'0:00'`)
    ├── Blocage utilisateur (dialog confirm) → BlockUserEvent
    ├── Signalement (dialog raisons + détails) → ReportUserEvent
    └── Quick messages (empty state): quick_hello / quick_compliment
```

### 1.2 Couche data/domain (cartographie)

| Couche | Fichier | Lignes | Statut global |
|---|---|---|---|
| Entity | `domain/entities/message.dart` | ~340 | Implémenté (avec `fromJson`/`toJson` — viole clean arch) |
| Repository interface | `domain/repositories/message_repository.dart` | ~70 | Interface — OK |
| UseCases `message/` (legacy) | `get_conversations`, `send_message`, `mark_as_read` | — | Implémentés mais `SendMessage` perd `clientMessageId` |
| UseCases `chat/` (new) | `get_messages`, `send_text_message`, `send_media_message`, `mark_message_as_read`, `delete_message`, `set_typing_status`, `get_presence`, `generate_media_upload_url` | — | Implémentés |
| Model | `data/models/message_model.dart` (+`.g.dart`) | ~210 | **Code mort** — jamais utilisé par le repo |
| Repository impl | `data/repositories/message_repository_impl.dart` | ~440 | Implémenté — bugs (§3.2) |
| DataSource | `data/datasources/remote/messaging_api.dart` | ~230 | Implémenté — méthode morte `sendMediaMessage` multipart |
| Service | `core/services/chat_websocket_service.dart` | ~210 | Partiel — pas de reconnexion, pas de heartbeat |
| DI | `injection.dart` | ~430 | Manuel — OK mais `injection_module.dart` mort |

### 1.3 Backend (cartographie)

- **App Django** : `messaging` (conversations + messages + typing + présence + media + calls premium) ; `calls` via `urls_calls.py`.
- **Base URL** : `api/v1/` ; `messaging.urls` monté sur `conversations/` ; `messaging.urls_calls` sur `calls/`.
- **Auth** : JWT `rest_framework_simplejwt` (access 60 min, refresh 7 j), `IsAuthenticated` partout. Rate limit middleware 60/min sur `conversations/.*/messages` — **désactivé en DEBUG**.
- **WebSocket** : `ws/conversations/<uuid:conversation_id>/` → `ConversationConsumer`. Auth : `Authorization: Bearer` header puis fallback `?token=` query. Groupe `conversation_{id}` (un groupe par conversation, les 2 participants rejoignent le même).
- **Infra** : Channels + `channels_redis` (`redis://127.0.0.1:6379/0`) ; Celery broker **`memory://`** (pertes au redémarrage) ; LocMem cache par défaut.

---

## 2. Inventaire détaillé — Objet par objet

### 2.1 `ConversationsPage` (`lib/presentation/pages/conversations/conversations_page.dart`, ~540 lignes)

**Objets UI et leur statut**

| Objet | Implémenté ? | Fonctionne ? | Notes / bugs |
|---|---|---|---|
| `ConversationsPage` (StatelessWidget, providers) | ✅ | ✅ | Fournit `ConversationsBloc` (émet `LoadConversations()`) + `NotificationsBloc` (émet `LoadNotifications()`). |
| AppBar titre `navigation.messages` + badge non-lu | ✅ | ⚠️ partiel | Badge lu depuis `ConversationsLoaded.totalUnreadCount`. OK. |
| Cloche notifications (`Icons.notifications_none`) | ✅ | ⚠️ | `context.push(AppRoutes.notifications)` OK ; **tooltip hardcoded `'Notifications'`** (i18n manquant). Badge depuis `NotificationsBloc`. |
| Icône recherche | ✅ | ✅ | Bascule `_showSearch` → `ConversationsSearchBar`. |
| Menu « more_vert » (`Icons.more_vert`) | ❌ dead | ❌ | `onPressed: () {}` — **callback vide, ne fait rien**. Tooltip `conversations.options`. |
| `ConversationsSearchBar` | ✅ | ⚠️ | Émet `SearchConversations(query)`. **Recherche locale uniquement sur `lastMessage.content`** — ne filtre pas par nom de participant (TODO dans le bloc). |
| `BlocConsumer` états loading/error/loaded | ✅ | ✅ | Loading → `ConversationsLoadingView` ; Error → `ConversationsErrorView` + SnackBar retry → `LoadConversations(refresh:true)` ; Loaded → `RefreshIndicator` + `ListView.separated`. |
| Pull-to-refresh | ✅ | ⚠️ | `LoadConversations(refresh: true)` avec **délai artificiel hardcoded 500 ms** (hack). |
| Infinite scroll (`_scrollController` à 90 %) | ✅ | ⚠️ | Émet `LoadMoreConversations`. **Mais `getConversations` ignore le curseur `lastConversationId`** (toujours `page=1`) → la pagination boucle/duplique (bug §3.2.1). |
| Indicateur « loading more » en bas de liste | ✅ | ✅ | OK. |
| Empty list → `EmptyConversationsView` | ✅ | ⚠️ i18n | **8 chaînes FR hardcoded** (voir §5.2). CTA `context.go('/matches')`. |
| Tap conversation → `_onConversationTap` | ✅ | ⚠️ | Émet `MarkConversationAsRead` puis `context.push('/chat/${id}', extra: conversation)`. **Le `MarkConversationAsRead` perd les champs `otherUserName/otherUserPhotoUrl/otherUserId/isOnline/lastActive/lastActivityAt`** (bug §3.2.2). |
| Long-press → bottom sheet `_showConversationOptions` | ✅ | ⚠️ | « Ouvrir » OK ; « Marquer lu » (si non lu) OK ; « Voir profil » → `context.push('/profile/$participantId')` utilise `participantIds.first` comme fallback (devrait préférer `otherUserId`) ; « Supprimer » → `_confirmDeleteConversation` → SnackBar `conversations.delete_unavailable` (**suppression non branchée — endpoint backend manquant**). |
| `_getParticipantName` helper | ✅ | ⚠️ | Retourne `otherUserName` si non vide, sinon `chat.default_user`. Commentaire TODO obsolète (prétend que Conversation n'a que des IDs — **faux**, l'entité a déjà `otherUserName`). |

**Événements BLoC consommés** : `LoadConversations`, `LoadMoreConversations`, `MarkConversationAsRead`, `SearchConversations`.
**Dead UI** : menu « more_vert » (callback vide), option « Supprimer » (info SnackBar au lieu d'une action).

---

### 2.2 `ChatPage` (`lib/presentation/pages/chat/chat_page.dart`, ~890 lignes)

| Objet | Implémenté ? | Fonctionne ? | Notes / bugs |
|---|---|---|---|
| `ChatPage` (StatefulWidget, `conversationId` requis, `conversation?` optionnel) | ✅ | ✅ | — |
| `initState` | ✅ | ⚠️ | Crée `ChatBloc` via `getIt`, émet `LoadConversation` puis `ConnectToWebSocket`, puis post-frame `MarkUnreadMessagesAsRead`. `_typingController.repeat(reverse:true)` **tourne en continu pendant toute la durée du chat** (gaspillage perf mineur). |
| `dispose` | ⚠️ | ⚠️ | **`DisconnectFromWebSocket` JAMAIS émis** — le WS n'est coupé que via `ChatBloc.close()`. Ferme `_chatBloc` manuellement (au lieu de laisser faire `BlocProvider`). |
| `didChangeMetrics` (clavier) | ✅ | ✅ | Scroll en bas si clavier visible. |
| `_onScroll` (FAB scroll-to-bottom + mark read) | ✅ | ✅ | OK. |
| AppBar retour | ✅ | ✅ | `context.pop()`. |
| Avatar (`_otherUserPhotoUrl`) | ✅ | ✅ | `NetworkImage` ou placeholder. |
| Nom (`_otherUserName`) | ✅ | ✅ | Fallback `chat.default_user`. |
| Statut (typing animé / online / last seen) | ✅ | ✅ | `chat.online` / `chat.last_seen` + `_formatLastSeen`. |
| Appel audio (`Icons.call`) → `_initiateCall(CallType.audio)` | ❌ stub | ❌ | **TODO WebRTC — toast « coming soon »**. **EXCLUSION confirmée** (WebRTC hors périmètre). |
| Appel vidéo (`Icons.videocam`) → `_initiateCall(CallType.video)` | ❌ stub | ❌ | Idem. |
| `PopupMenuButton` (profile/block/report) | ✅ | ✅ | — |
| → `profile` : `context.push('/profile/$otherUserId')` | ✅ | ✅ | Garde null. |
| → `block` : `_showBlockDialog` → `BlockUserEvent(userId)` | ✅ | ✅ | Dialog confirm + i18n `chat.block_confirm_*`. |
| → `report` : `_showReportDialog` → `ReportUserEvent(userId, reason, description?)` | ✅ | ⚠️ i18n | **Liste raisons hardcoded** `['inappropriate','harassment','scam','other']` — mais correspondent aux clés i18n `chat.report_reason_*` (OK fonctionnel, code en dur acceptable car clés dérivées). |
| `BlocConsumer<ChatBloc>` listener | ✅ | ✅ | Gère `completedAction`/`actionError` (block/report), scroll-to-bottom, `MarkUnreadMessagesAsRead`. |
| Builder : `ChatLoading` → `HIVLoader` | ✅ | ✅ | — |
| Builder : `ChatLoaded` empty → `_buildEmptyState` (« It's a match! » + 2 quick messages) | ✅ | ✅ | `chat.its_a_match`, `chat.quick_hello`, `chat.quick_compliment`. |
| Builder : `ChatLoaded` → Stack(ListView + FAB) | ✅ | ⚠️ | Voir `MessageBubble` (§2.6) et `MessageInput` (§2.7). |
| Builder : fallback → `common.error` | ✅ | ✅ | — |
| `_buildMessagesList` : `ListView.builder` + indicateur typing + timestamp divider (>1h) | ✅ | ✅ | `_shouldShowTimestamp` (>1h gap). |
| `_buildInputArea` : `MessageInput` wiring | ✅ | ⚠️ | `onSendMessage(content, type)` : texte → `SendTextMessageEvent` ; **non-texte → `// TODO: Handle media messages`** (branche morte — mais `onSendMediaMessage` est aussi branché, donc cette branche est injoignable pour les médias). |
| `onStartTyping` / `onStopTyping` → `SetTypingStatus(isTyping:true/false)` | ✅ | ⚠️ | **`_onSetTypingStatus` dans le BLoC émet `copyWith(isTyping: currentState.isTyping)` — no-op** (bug §3.1.3). Le WS inbound gère correctement le typing de l'autre ; le REST outbound est donc inutile/no-op côté état. |
| `onRecordingStateChanged` | ❌ dead | ❌ | Commentaire « handled by MessageInput » — **ne fait rien côté ChatPage**. |
| `_showBlockDialog` / `_showReportDialog` | ✅ | ✅ | — |
| `_formatLastSeen` | ✅ | ✅ | `chat.just_now` / `chat.minutes_ago` / `chat.hours_ago` / `chat.days_ago`. |

**Dead UI** : appels WebRTC (stub), `onRecordingStateChanged` callback côté ChatPage, branche `onSendMessage` non-texte.
**Dead state** : `showPremiumPrompt` jamais lu par l'UI (pas d'upsell premium dans le chat).

---

### 2.3 `ConversationsBloc` (`lib/presentation/blocs/conversations/conversations_bloc.dart`, ~270 lignes)

| Événement | Handler | Statut | Bugs |
|---|---|---|---|
| `LoadConversations { bool refresh }` | `_onLoadConversations` | ✅ | — |
| `LoadMoreConversations` | `_onLoadMoreConversations` | ⚠️ | Utilise `_allConversations.last.id` comme curseur (suppose tri par récence). **Le repo ignore ce curseur → pagination boucle** (§3.2.1). |
| `RefreshConversations` | `_onRefreshConversations` | ❌ dead | **Événement défini mais jamais émis par l'UI** (l'UI utilise `LoadConversations(refresh:true)`). |
| `MarkConversationAsRead { String conversationId }` | `_onMarkConversationAsRead` | ⚠️ | **Reconstruit `Conversation` avec uniquement `id, participantIds, lastMessage, unreadCount=0, updatedAt` — perd `otherUserName/otherUserPhotoUrl/otherUserId/isOnline/lastActive/lastActivityAt`** (§3.2.2). Sur erreur : rollback puis émet `ConversationsError` après le rollback (flash d'erreur). |
| `SearchConversations { String query }` | `_onSearchConversations` | ⚠️ | **Filtre local sur `lastMessage.content` uniquement** (TODO « enrichir avec noms participants »). Ne filtre pas par nom de participant malgré le hint de la search bar. |

**Dépendances** : `GetConversations`, `SendMessage` (non utilisé — commentaire « reserved for later »), `MarkAsRead`.

---

### 2.4 `ChatBloc` (`lib/presentation/blocs/chat/chat_bloc.dart`, ~700 lignes)

| Événement | Handler | Statut | Notes |
|---|---|---|---|
| `LoadConversation { String conversationId }` | `_onLoadConversation` | ✅ | Fetch page initiale, tri ascendant, émet `ChatLoaded`. |
| `LoadMoreMessages` | `_onLoadMoreMessages` | ⚠️ | Pagination par `beforeMessageId` (plus ancien id). **Le repo envoie `page=1` + `before_message_id` simultanément → comportement backend indéfini** (§3.2.2). |
| `SendTextMessageEvent { String content }` | `_onSendTextMessage` | ✅ | Optimistic (status `sending`), rollback `failed`. |
| `SendMediaMessageEvent { File mediaFile, MessageType type }` | `_onSendMediaMessage` | ⚠️ | Optimistic mais **`content:''` et `type: event.type` sans URL média** → la bulle affiche vide jusqu'à confirmation serveur/WS. |
| `MarkAsReadEvent { String messageId }` | — | ❌ dead | **Jamais émis par l'UI** (l'UI utilise `MarkUnreadMessagesAsRead`). |
| `MarkUnreadMessagesAsRead` | `_onMarkUnreadMessagesAsRead` | ✅ | Marque le dernier message non-lu non-mine. |
| `SetTypingStatus { bool isTyping }` | `_onSetTypingStatus` | ⚠️ | **Émet `copyWith(isTyping: currentState.isTyping)` — no-op** (§3.1.3). Appelle aussi REST + WS (double chemin). |
| `DeleteMessageEvent { String messageId }` | `_onDeleteMessage` | ⚠️ | Optimistic removal + rollback. **Mais `MessageBubble.onDelete` n'est jamais appelé → suppression injoignable depuis la bulle** (§2.6). |
| `BlockUserEvent { String userId }` | `_onBlockUser` | ✅ | Set `completedAction = block`. |
| `ReportUserEvent { String userId, String reason, String? description }` | `_onReportUser` | ✅ | Set `completedAction = report`. |
| `ClearChatActionFeedback` | `_onClearChatActionFeedback` | ✅ | Nullifie les champs action. |
| `ConnectToWebSocket` | `_onConnectWebSocket` | ✅ | Récupère token, connecte WS, abonne `events` → dispatch `_WebSocket*`. |
| `DisconnectFromWebSocket` | `_onDisconnectWebSocket` | ❌ dead | **Jamais émis par l'UI** (le WS n'est coupé que via `close()`). |
| `_WebSocketMessageReceived` | `_onWsMessageReceived` | ⚠️ | Déduplique par `message_id`/`client_message_id`. **Construit `Message` à la main (3e implémentation de mapping)** — risque de dérive. |
| `_WebSocketTypingIndicator` | `_onWsTypingIndicator` | ✅ | Ignore son propre userId, set `isTyping`. |
| `_WebSocketPresenceUpdate` | `_onWsPresenceUpdate` | ✅ | Ignore son propre userId, set `otherIsOnline`/`otherLastActive`. |

**States** : `ChatInitial`, `ChatLoading`, `ChatLoaded { messages, hasMore, isTyping, isLoadingMore, showPremiumPrompt=false (dead), otherIsOnline?, otherLastActive?, completedAction?, actionError? }`, `ChatError { message }`.

**`_stringToMessageType`** : mappe `'image'|'video'|'audio'|'voice'|'call_log'|'system'|'text'`.
**`close()`** : annule sub WS, dispose le service WS. OK car factory DI.

---

### 2.5 Widgets conversations

#### `conversation_card.dart` (`widgets/conversations/`, ~280 lignes) — **utilisé**
- Props : `conversation, participantName, participantPhotoUrl?, currentUserId, onTap, onLongPress?`.
- Photo : `CachedNetworkImage` + placeholder/error.
- Header : nom (bold si non lu), aperçu message (`conversations.media_photo/video/voice`, `conversations.own_message_prefix`).
- Trailing : timestamp (`_formatTimestamp` today/yesterday/weekday/days_ago/dd-mm-yyyy) + badge non-lu.
- **`currentUserId` passé comme `''` depuis la page** (§3.4) → détection « own message » fallback sur `lastMessage.isMine` seulement.
- **TODO doc obsolète** L7-9 (prétend que Conversation n'a que des IDs — faux).

#### `conversation_card.dart` (`widgets/cards/`, ~210 lignes) — **DOUBLON MORT**
- 2e implémentation différente avec `Dismissible` (swipe-to-delete) + dialog confirm.
- **Jamais utilisé par `conversations_page.dart`** (utilise l'autre). Dead/duplicate.
- **5 chaînes FR hardcoded** : `'Supprimer la conversation'`, `'Cette action est irréversible.'`, `'Annuler'`, `'Supprimer'`, `'Maintenant'`.
- Conséquence : la UI swipe-to-delete est perdue (le `onDelete` n'est jamais branché).

#### `empty_conversations_view.dart` (~210 lignes)
- `EmptyConversationsView` (search-empty vs default-empty), `ConversationsLoadingView`, `ConversationsErrorView` (message + retry).
- **8 chaînes FR hardcoded** (voir §5.2).

#### `conversations_search_bar.dart` (~115 lignes)
- StatefulWidget avec debounce 300 ms, bouton clear, focus node.
- **Hint hardcoded FR** `'Rechercher une conversation...'`.

#### `conversations_widgets.dart` (barrel, 7 lignes)
- Exporte `conversation_card`, `conversations_search_bar`, `empty_conversations_view`.

---

### 2.6 `MessageBubble` (`lib/presentation/widgets/chat/message_bubble.dart`, ~120 lignes)

| Rendu | Statut | Notes |
|---|---|---|
| Texte (`MessageType.text`) | ✅ | `Text(message.content)`. |
| Image (`MessageType.image && mediaUrl != null`) | ✅ | `Image.network` 200px. **Pas de placeholder/error/loading, pas de tap-to-zoom, pas de cached**. |
| Video / voice / audio / callLog / system | ❌ | **Rend une bulle vide** — pas de lecteur vidéo, pas de lecteur audio, pas d'icône pour voice, pas de rendu call log, pas de rendu system. |
| Timestamp `HH:mm` | ✅ | via `intl.DateFormat`. |
| Statut propre message (`done` sent / `done_all` read) | ⚠️ | **Seul `read` vs « else » est distingué — `sending`/`failed` ressemblent à `sent`** (messages échoués apparaissent comme envoyés). |
| `onDelete` prop | ❌ dead | **Accepté mais jamais appelé dans `build()`** — pas de long-press/menu pour supprimer. Le `chat_page.dart` passe `onDelete: () => _deleteMessage(message)` mais la bulle ne l'invoque jamais → **suppression de message injoignable depuis l'UI**. |

---

### 2.7 `MessageInput` (`lib/presentation/widgets/chat/message_input.dart`, ~840 lignes)

| Fonctionnalité | Implémenté ? | Fonctionne ? | Notes |
|---|---|---|---|
| TextField (`chat.type_message`) | ✅ | ✅ | — |
| Bouton envoi texte (avec animation) | ✅ | ✅ | `HapticFeedback.lightImpact`. |
| Bouton média → `MediaPicker` | ✅ | ⚠️ | `_showMediaPicker` → `_sendMediaMessageFile`. **Non-image premium-gated** (dialog `_showPremiumDialog`). |
| Envoi média → `onSendMediaMessage(file, type)` | ✅ | ⚠️ | Voir `_onSendMediaMessage` (bulle vide jusqu'à confirmation serveur). |
| Toggle emoji picker (~140 emojis hardcoded) | ✅ | ✅ | Insertion à la sélection. |
| Boutons GIF/stickers (premium) | ❌ stub | ❌ | `_showGifPicker`/`_showStickerPicker` → **TODO — toast « coming soon »**. |
| Bouton voix (long-press si pas de texte) | ❌ cassé | ❌ | `_startRecording` → si non premium → `_showPremiumDialog` ; sinon `_isRecording=true` + **TODO « start audio recording » (pas implémenté)**. `_stopRecording` → **TODO « stop & send voice »** puis appelle `onSendMessage(_recordingDuration, MessageType.voice)` → **envoie la chaîne `'0:00'` comme contenu voice** (bug — envoie du garbage). |
| `_recordingDuration='0:00'` (final String) | ❌ | ❌ | **Jamais mis à jour** — duration statique. |
| `_showPremiumDialog` → bouton « Upgrade » | ⚠️ | ❌ | **TODO « navigate to premium page » — ne fait rien que pop**. |
| Indicateur recording (point rouge animé + `chat.recording`) | ✅ UI | ❌ logique | Le visuel existe mais la logique de recording n'existe pas. |
| Tooltips `'GIFs'`, `'Stickers'` | ⚠️ | ❌ | Hardcoded (i18n manquant). |
| `onRecordingStateChanged` callback | ✅ prop | ❌ | Côté `ChatPage` ne fait rien (dead). |
| Typing start/stop → `onStartTyping`/`onStopTyping` | ✅ | ⚠️ | BLoC no-op (§3.1.3). |

**Dead/cassé** : voice recording, GIF/stickers, premium upgrade navigation, `_recordingDuration`.

---

### 2.8 Couche data/domain — détails par méthode

#### Repository interface (`message_repository.dart`) — 11 méthodes

| Méthode | Implémentée ? | Fonctionne ? | Notes |
|---|---|---|---|
| `getConversations({limit, lastConversationId?})` | ✅ | ⚠️ | **Ignore `lastConversationId`** → pagination cassée (§3.2.1). |
| `getConversation(conversationId)` | ✅ | ✅ | — |
| `watchConversations()` | ❌ | ❌ | **`throw UnimplementedError`** — toute appel plante. Rien ne l'appelle actuellement. |
| `getMessages({conversationId, limit, beforeMessageId?})` | ✅ | ⚠️ | Envoie `page=1` **et** `before_message_id` simultanément → comportement backend indéfini (§3.2.2). |
| `watchMessages(conversationId)` | ❌ | ❌ | **`throw UnimplementedError`**. |
| `sendMessage({conversationId, content, type, mediaFile?, clientMessageId?, mediaText?})` | ✅ | ⚠️ | Texte : OK. Média : flow URL signée → PUT Dio brut (pas de timeout/retry) → POST path. **`content: mediaText` hardcoded null** dans le use case path. **`_buildClientMessageId` = `'client_' + DateTime.now().microsecondsSinceEpoch`** (collision si envoi rapide dans la même microseconde). |
| `markAsRead({conversationId, messageId})` | ✅ | ⚠️ | PUT `/mark-as-read/` body `{last_read_message_id}`. **Ignore le body de réponse `{message, read_at}`** → perd le timestamp `read_at`. |
| `deleteMessage({conversationId, messageId})` | ✅ | ✅ | DELETE `/messages/{msg_id}/`. |
| `setTypingStatus({conversationId, isTyping})` | ✅ | ✅ | POST `/typing/` body `{is_typing}`. |
| `getPresence({conversationId})` | ✅ | ✅ | GET `/presence/`. |
| `generateMediaUploadUrl({fileName, contentType})` | ✅ | ⚠️ | POST `/generate-media-upload-url/`. **Retourne `expiresInSeconds` mais le repo ne vérifie jamais l'expiration** → si l'URL expire entre génération et PUT, échec opaque. |
| `watchTypingStatus(conversationId)` | ❌ | ❌ | **`throw UnimplementedError`**. |

#### `MessageModel` (`data/models/message_model.dart`) — **code mort**
- `@JsonSerializable()` avec `fromEntity()`/`toEntity()`.
- **Jamais utilisé par `MessageRepositoryImpl`** (le repo fait son propre `_mapJsonToMessage`).
- Clés JSON strictes (`id`, `content`) — **pas d'alias `message_id`/`content_preview`** → casserait sur les previews `last_message`.
- Cast `reactions` `(json['reactions'] as Map<String,dynamic>?)?.map((k,e) => MapEntry(k, e as String))` — crash si valeur non-string.

#### `MessagingApi` (`data/datasources/remote/messaging_api.dart`) — 15 méthodes
- Toutes retournent `Future<Response<Map<String,dynamic>>>` sans catch (propagent `DioException` au repo — bonne séparation).
- **`sendMediaMessage` (multipart `/messages/media/`) — DEAD CODE** — le repo utilise le flow URL signée à la place. Si le backend ne supporte pas l'URL signée, l'envoi de média échoue (à confirmer côté backend — voir §4.5).
- **`markSingleMessageAsRead`** — méthode existe mais jamais appelée par le repo (endpoint `PUT /messages/{msg_id}/read/` non utilisé).
- **Calls** : `initiateCall` body `{target_user_id, call_type}` (doc dit `callee_id`), **manque `offer_sdp`**. `answerCall` POST `{answer: true}` (doc PUT `{answer_sdp}`). `endCall` POST `/terminate` (doc PUT `/end` + `end_reason`). **→ WebRTC exclu du périmètre d'implémentation, ces méthodes peuvent rester en stub**.

#### `ChatWebSocketService` (`core/services/chat_websocket_service.dart`, ~210 lignes)

| Aspect | Statut | Notes |
|---|---|---|
| `connect({conversationId, token})` | ✅ | `WebSocket.connect('$baseWs/ws/conversations/$id/?token=$token')`. **Token en query string** (risque log proxy/CDN). Envoie `{type:'ping'}` initial. |
| `disconnect()` | ✅ | `_intentionalClose=true`, ferme socket. |
| `isConnected` getter | ✅ | — |
| `sendTextMessage({content, clientMessageId})` | ❌ dead | **Jamais appelé par `ChatBloc`** (le BLoC utilise REST `SendTextMessage`). |
| `sendTyping(bool isTyping)` | ✅ | `{type:'typing.start'|'typing.stop'}`. Utilisé par `ChatBloc`. |
| `sendPing()` | ✅ | — |
| Events stream (broadcast) | ✅ | `messageCreated`, `typingIndicator`, `presenceUpdate`, `pong`, `error`, `unknown`. |
| **Reconnexion auto** | ❌ | `_onDone` null juste le socket. **Pas de reconnexion** — drop réseau = temps réel mort jusqu'à navigation away/back. |
| **Heartbeat loop** | ❌ | Un seul ping à la connexion. Idle sockets tués par proxies. |
| **Token refresh** | ❌ | Si token expire mid-session, socket fermée, reconnect utilise le même token (via `_authService.getAccessToken()` qui refresh, mais seulement sur événement explicite). |
| **`_onError`/`_onDone` n'émettent pas d'événement reconnect-request** | ❌ | Le BLoC ne peut pas distinguer close intentionnelle vs drop réseau sauf à poller `isConnected`. |
| **Pas de multiplexing** | — | Une socket par conversation ; changement de conversation = disconnect+connect. |
| **`_sendRaw` drop silencieux si non connecté** | ❌ | Pas de buffer, pas d'erreur. Typing indicators perdus pendant reconnect. |
| **`dispose()` ferme le StreamController** | — | OK car factory DI (nouvelle instance par ChatBloc). |
| **`_parseEventType` retourne `unknown` pour types non reconnus** | ❌ | Types serveur nouveaux silencieusement ignorés. **Pas d'événement `message.read`/`message.delivered` modélisé** — seuls `message.created` l'est. |

#### DI (`injection.dart`)
- `MessageRepository` → `MessageRepositoryImpl` singleton ; `MessagingApi` singleton.
- UseCases legacy (`GetConversations`, `SendMessage`, `MarkAsRead`) + nouveaux (`chat/`) tous singletons.
- `ChatWebSocketService` **factory** (nouveau par ChatBloc — OK car `dispose()` ferme le controller).
- `ConversationsBloc` / `ChatBloc` factory.
- `NotificationsBloc` factory — injecte `MessageRepository` directement (skip use cases).
- **`injection_module.dart` (module injectable) unused** — `injection.dart` re-enregistre manuellement `FlutterSecureStorage`, `FirebaseAuth`, `FirebaseMessaging`, `ApiClient`. Le `Dio` du module n'est jamais utilisé (ApiClient construit le sien). Dead config.

#### Configuration
- `AppConfig.apiBaseUrl` : dev emulator `http://10.0.2.2:8000`, device `http://192.168.1.118:8000`, prod `https://api.hivmeet.com`. `--dart-define=API_URL` override.
- `AppConfig.websocketUrl` : dérivé de `apiBaseUrl` (http→ws). **Pas de `/ws` suffix** (le service WS ajoute `/ws/conversations/{id}/`).
- **`constants.dart` `AppConstants.baseUrl='https://api.hivmeet.com'`** hardcoded prod — **mort mais landmine**.
- **`AppConstants.websocketUrl='wss://api.hivmeet.com/ws'`** — différent de `AppConfig.websocketUrl` (qui n'a pas `/ws`). Incohérent.
- `AppConstants.maxMessageLength = 1000` — **pas enforced** dans `SendTextMessage` (vérifie seulement `trim().isEmpty`).
- `AppConstants.maxFileSize = 10 MB` — **mais `SendMediaMessage` enforce 50 MB** (§3.3 mismatch).
- `AppConstants.maxMessagesStoredGratuit = 50` / `Premium = 200` — pas enforced frontend (backend responsibility).

---

## 3. Bugs critiques et problèmes transverses

### 3.1 Bugs frontend (présentation)

1. **`ConversationsBloc._onMarkConversationAsRead` perd les champs other-user** (§2.1, §2.3) — après mark-as-read, la card perd nom/photo/online. Reconstruit `Conversation` avec seulement `id, participantIds, lastMessage, unreadCount=0, updatedAt` au lieu de `copyWith`.
2. **`ChatBloc._onSetTypingStatus` no-op** — émet `copyWith(isTyping: currentState.isTyping)` au lieu de `isTyping: event.isTyping`. Le typing outbound REST est donc sans effet sur l'état local (le WS inbound gère le typing de l'autre correctement).
3. **`MessageBubble.onDelete` jamais appelé** — suppression de message injoignable depuis l'UI.
4. **`MessageBubble` ne rend pas video/voice/audio/callLog/system** — bulles vides.
5. **`MessageBubble` ne distingue pas `sending`/`failed`** — messages échoués apparaissent comme envoyés.
6. **`MessageInput` voice recording cassé** — `_startRecording` TODO, `_stopRecording` envoie `'0:00'` comme contenu voice. `_recordingDuration` jamais mis à jour.
7. **`MessageInput` GIF/stickers stub** — toast « coming soon ».
8. **`MessageInput` premium dialog « Upgrade » ne fait rien** — TODO navigation premium.
9. **`ConversationsPage` menu « more_vert » callback vide** — dead UI.
10. **`ConversationsPage` option « Supprimer » non branchée** — SnackBar `delete_unavailable` (endpoint backend manquant).
11. **`ConversationsPage` tooltip cloche hardcoded `'Notifications'`** — i18n manquant.
12. **`ChatPage` `DisconnectFromWebSocket` jamais émis** — WS coupé via `close()` seulement.
13. **`ChatPage` `onSendMessage` non-texte branche morte** — `// TODO: Handle media messages` (injoignable car `onSendMediaMessage` aussi branché).
14. **`ChatPage` `onRecordingStateChanged` callback mort côté ChatPage**.
15. **`RefreshConversations` event dead** — jamais émis.
16. **`MarkAsReadEvent { messageId }` event dead** — jamais émis.
17. **`showPremiumPrompt` state field dead** — jamais lu par l'UI.
18. **`ChatPage._typingController.repeat(reverse:true)` tourne en continu** — gaspillage perf mineur.
19. **`widgets/cards/conversation_card.dart` doublon mort** — 5 chaînes FR hardcoded, swipe-to-delete perdu.
20. **`ConversationsPage` « Voir profil » utilise `participantIds.first`** comme fallback au lieu de `otherUserId`.
21. **`_onLoadMoreConversations` emit `ConversationsError` après rollback** — flash d'erreur.

### 3.2 Bugs data/domain

1. **`MessageRepositoryImpl.getConversations` ignore `lastConversationId`** — envoie toujours `page=1` → pagination boucle/duplique.
2. **`MessageRepositoryImpl.getMessages` mélange pagination** — envoie `page=1` + `before_message_id` simultanément → comportement backend indéfini.
3. **`watchConversations`/`watchMessages`/`watchTypingStatus` throw `UnimplementedError`** — 3 méthodes publiques de l'interface qui plantent si appelées.
4. **`MessageModel` code mort** avec mapping JSON strict (casserait sur aliases `message_id`/`content_preview`).
5. **`SendMessage` (legacy use case) perd `clientMessageId`** — ne le forward pas au repo (optimistic dedup fail).
6. **`_uploadMediaToSignedUrl` Dio brut sans timeout/retry** — PUT GCS peut pendre indéfiniment.
7. **`markAsRead` ignore le body de réponse** — perd `read_at` timestamp.
8. **`markSingleMessageAsRead` (MessagingApi) dead code** — endpoint `PUT /messages/{msg_id}/read/` non utilisé.
9. **`_buildClientMessageId` = `'client_' + DateTime.now().microsecondsSinceEpoch`** — collision si envoi rapide dans la même microseconde (pas un UUID).
10. **`_mapDioFailure` : 402 → `PremiumFailure`** (Payment Required sémantiquement faux ; 403 = Forbidden ≠ premium). Devrait splitter.
11. **`_mapDioFailure` : `sendTimeout`/`badResponse`/`unknown` DioExceptionTypes non gérés** — tombent sur `ServerFailure(code: statusCode?.toString())`.
12. **`catch (e) → ServerFailure(message: e.toString())`** — leak d'exception brute vers l'UI (non-i18n, potentiellement PII).
13. **`reactions` cast `Map<String,String>`** — crash si backend envoie valeurs non-string.
14. **3 implémentations de mapping message** (entity `fromJson`, `MessageModel.fromJson` mort, `_mapJsonToMessage` repo) — risque de dérive.
15. **`Message`/`Conversation` entities ont `fromJson`/`toJson`** — viole clean arch (devrait être dans models).
16. **2 hiérarchies use cases qui se chevauchent** (`message/` legacy vs `chat/` new) — consolider.

### 3.3 Bugs config/constants

1. **`SendMediaMessage` enforce 50 MB** vs `AppConstants.maxFileSize = 10 MB` — mismatch.
2. **`AppConstants.maxMessageLength = 1000` non enforced** dans `SendTextMessage`.
3. **`AppConstants.baseUrl`/`websocketUrl` hardcoded prod** — mort mais landmine si importé.

### 3.4 Bugs backend (impact frontend)

1. **`GET .../messages` auto-marque READ les messages reçus** — `MessageService.get_conversation_messages` update unread→READ immédiatement, avant que l'utilisateur voie les messages. **Read receipts incorrects** (messages marqués lus au fetch, pas au viewport).
2. **`generate-media-upload-url` est un stub** — retourne `https://storage.googleapis.com/hivmeet-media/...` non signé (pas de policy/credentials). Tout client pourrait PUT. Pas d'intégration `FIREBASE_STORAGE_BUCKET`.
3. **`create_media_message` construit `media_url` depuis `MEDIA_URL` + path** alors que `generate-media-upload-url` retourne une URL GCS → 2 flows média incohérents.
4. **`conversation_messages` POST ignore `media_url`/`media_thumbnail_url`** sur le endpoint JSON — seul `media_file_path` est stocké ; `media_url` reste vide sauf si endpoint `/media/` multipart séparé est utilisé.
5. **WS `message.send` bypass la sanitization** — `_handle_message_send` passe le `content` brut à `MessageService.send_message` ; les patterns `DISALLOWED_MESSAGE_PATTERNS`/`strip_tags` du `SendMessageSerializer` ne sont PAS appliqués sur le path WS. Risque XSS/injection.
6. **WS `message.send` texte-only** — pas de `message_type`, pas de média, pas de premium gate, pas de `media_file_path`.
7. **Typing indicators dupliqués** — `TypingIndicator` model (REST) vs cache keys `typing_{cid}_{uid}` (WS). `get_typing_users` lit le cache, pas le model → model write-only dead.
8. **Présence per-conversation** — cache `presence_{user_id}_{conversation_id}`. Un user « online » dans conv A est « offline » ailleurs. `ConversationSerializer.other_user.is_online` utilise `last_active < 300s` → 2 définitions online coexistent.
9. **`mark_messages_as_read` ne broadcast pas d'événement WS `read`** — le destinataire notifié via FCM push seulement, pas via le WS group ouvert. Le sender dont le chat est ouvert ne voit pas le read receipt en temps réel.
10. **`Call.ice_candidates` croît sans limite** — JSONField list, réécrit toute la liste à chaque candidate.
11. **`Call.check_call_limit` ne compte que `ENDED`** — un call `FAILED` après 29 min ne compte pas → cap 30 min/jour effectif sur temps réussi seulement.
12. **Celery broker `memory://`** — tasks (`send_message_notification`, `send_call_notification`, `send_read_notification`) perdus au redémarrage, effectivement synchrones.
13. **Rate limiting désactivé en DEBUG** — dev/QA sans protection spam.
14. **N+1 queries sur conversations list** — `ConversationSerializer.get_last_message` query per row + `get_other_user` `photos.filter(is_main=True).first()` per row (pas de `prefetch_related('photos')` malgré `select_related('user1__profile','user2__profile')`).
15. **`conversation_messages` ordering `-created_at`** mais cursor `created_at__lt` — 2 messages avec `created_at` identique (sub-ms) peuvent être skip/dupliqué entre pages.
16. **`mark_single_message_as_read` retourne 403 si déjà lu ou si user est sender** — non idempotent (retry yield 403).
17. **Pas de `DELETE /conversations/{id}/`** — endpoint suppression conversation manquant (le frontend a `BACKEND_MESSAGING_DELETE_CONVERSATION.md` tracked mais pas implémenté).
18. **Filtre `unread` non implémenté** — `ConversationListView` ne gère que `status=archived` (qui retourne `queryset.none()` car `Match` n'a pas de statut `archived`).
19. **`CHANNEL_LAYERS_FALLBACK` dead config** — jamais sélectionné à l'exécution ; Redis down → events silently drop (caught by `channel_layer_context`).

---

## 4. Contrats API — frontend ↔ backend

### 4.1 Endpoints REST backend (source de vérité = backend réel)

Base : `api/v1/` ; `conversations/` (messaging.urls) ; `calls/` (urls_calls).

| # | Méthode & chemin | Nom | Auth | Body/Query | Réponse | Status |
|---|---|---|---|---|---|---|
| 1 | `GET /conversations/` | `conversation-list` | JWT | `status` (only `archived` → none), `page`, pagination DRF | `{count,next,previous,results:[ConversationSerializer]}` | 200 |
| 2 | `POST /conversations/generate-media-upload-url/` | `generate-media-upload-url` | JWT | `{file_name?,content_type?}` | `{upload_url,file_path_on_storage,content_type,expires_in_seconds:900}` | 200 |
| 3 | `GET /conversations/<uuid:id>/messages/` | `conversation-messages` | JWT | `page,page_size=50,limit,before_message_id` | `{count,next,previous,results:[MessageSerializer],has_more,show_premium_prompt}` + **auto-mark READ** | 200/404 |
| 4 | `POST /conversations/<uuid:id>/messages/` | `conversation-messages` | JWT | `SendMessageSerializer`: `{client_message_id(req),content?,type:text|image|video|audio(default text),media_file_path_on_storage?}` | `MessageSerializer` | 201/400/403(premium)/404 |
| 5 | `POST /conversations/<uuid:id>/messages/media/` | `send-media-message` | JWT + **premium** (`media_messaging`) | multipart `media_file` ≤10MB, `media_type`, `text?`, `client_message_id?` | `MessageSerializer` | 201/400/403/404 |
| 6 | `PUT /conversations/<uuid:id>/messages/mark-as-read/` | `mark-as-read` | JWT | `{last_read_message_id?}` | `{messages_marked:int}` | 200/404 |
| 7 | `PUT /conversations/<uuid:id>/messages/<uuid:msg_id>/read/` | `mark-single-read` | JWT | none | `{message,read_at}` | 200/403/404 |
| 8 | `DELETE /conversations/<uuid:id>/messages/<uuid:msg_id>/` | `delete-message` | JWT | none | empty | 204/400/403/404 |
| 9 | `POST /conversations/<uuid:id>/typing/` | `typing-indicator` | JWT | `{is_typing?:bool}` | `{is_typing}` | 200/404 |
| 10 | `GET /conversations/<uuid:id>/presence/` | `conversation-presence` | JWT | none | `{participant:{user_id,is_online,last_active,is_typing}}` | 200/404 |
| 11 | `POST /conversations/calls/initiate-premium/` | `initiate-premium-call` | JWT + premium (`calls`) | `{target_user_id,call_type,offer_sdp}` | `CallSerializer` | 201/400/403/404 |
| 12 | `POST /calls/initiate` | `calls:initiate` | JWT (premium in `Call.check_call_limit`) | `{target_user_id,call_type:audio|video,offer_sdp}` | `{call_id,status,message}` | 201/400/403/404 |
| 13 | `POST /calls/<uuid:call_id>/answer` | `calls:answer` | JWT, callee only | `{answer_sdp}` | `{call_id,status,message}` | 200/400/404 |
| 14 | `POST /calls/<uuid:call_id>/ice-candidate` | `calls:ice-candidate` | JWT, caller or callee | `{candidate:dict}` | empty | 204/400/404 |
| 15 | `POST /calls/<uuid:call_id>/terminate` | `calls:terminate` | JWT, caller or callee | `{reason:declined|ended_by_caller|ended_by_callee|no_answer|connection_failed|duration_limit_reached}` | `{call_id,status,duration_seconds,message}` | 200/400/404 |

**Serializers clés** :
- `MessageSerializer` : `message_id`, `id`, `client_message_id`, `conversation_id`, `sender_id`, `is_mine`, `content`, `message_type`, `media_url`, `media_type`, `media_thumbnail_url`, `status`, `sent_at`, `created_at`, `delivered_at`, `read_at`, `read_at_by_recipient`, `is_sending`.
- `ConversationSerializer` : `conversation_id`, `id`, `other_user` (`{user_id,display_name,main_photo_url,is_online,last_active}`), `last_message` (`{message_id,content_preview,sender_id,sent_at,is_read_by_me}`), `unread_count_for_me`, `created_at`, `last_message_at`, `last_activity_at`.
- `SendMessageSerializer` : valide `javascript:`, `data:text/html`, `<script` (regex), strip HTML tags ; `type=text` requires `content` ; `image|video|audio` requires `media_file_path_on_storage`.

### 4.2 WebSocket backend

- **Routing** : `ws/conversations/<uuid:conversation_id>/` → `ConversationConsumer` ; `ws/notifications/` → `UserNotificationConsumer`.
- **Auth** : JWT `AccessToken` — header `Authorization: Bearer` puis fallback `?token=` query. Décode `user_id`, charge `User`.
- **Access control** : user doit faire partie d'un `Match` ACTIVE avec `id == conversation_id`, sinon close code `4001`.
- **Groupe** : `conversation_{conversation_id}` (un groupe par conversation, les 2 participants rejoignent le même).

**Client → Server (`receive`)**

| `type` | Comportement |
|---|---|
| `message.send` | `{content,client_message_id}` → `MessageService.send_message` (texte only) → `post_save` broadcast `message.created` + push. Empty → error `EMPTY_MESSAGE`. **Pas de sanitization** (bug §3.4.5). |
| `typing.start` | Cache `typing_{cid}_{uid}` TTL 10s ; broadcast `typing.indicator` `{user_id,status:'typing'}` (skip self). |
| `typing.stop` | Clear cache ; broadcast `typing.indicator` `{status:'stopped'}`. |
| `ping` | Reply `{type:'pong',timestamp}`. |
| `ice.candidate` | Broadcast `ice.candidate` `{from_user_id,candidate,sdpMid,sdpMLineIndex}`. |
| `offer` | Broadcast `webrtc.offer` `{from_user_id,call_id,offer}`. |
| `answer` | Broadcast `webrtc.answer` `{from_user_id,call_id,answer}`. |

JSON invalide → `{type:'error',code:'INVALID_JSON'}`. Autres → `{type:'error',code:'INTERNAL_ERROR'}`.

**Server → Client event types**

| Event | Payload |
|---|---|
| `message.created` | `{message_id,conversation_id,sender_id,content,message_type,sent_at,client_message_id}` (via `post_save` signal `handle_new_message`, non-`CALL_LOG`). |
| `typing.indicator` | `{user_id,status:'typing'|'stopped'}`. |
| `presence.update` | `{user_id,status:'online'|'offline',timestamp}`. |
| `ice.candidate` | `{from_user_id,candidate,sdpMid,sdpMLineIndex}`. |
| `webrtc.offer` | `{from_user_id,call_id,offer}`. |
| `webrtc.answer` | `{from_user_id,call_id,answer}`. |
| `incoming_call` | `{call:{id,caller_id,caller_name,call_type,match_id}}` (signal `handle_call_update` quand `Call.status==RINGING`). |
| `call_update` | `{call:{id,status,end_reason}}` (ANSWERED|ENDED|DECLINED). |

**Persistence & notifications** :
- New `Message` (REST ou WS) → `post_save` signal `handle_new_message` : queue `send_message_notification` Celery (FCM push, respecte `new_message_notifications` setting), persist `Notification` row (`type='new_message'`), broadcast `message.created` au group. Channel-layer wrappé dans `channel_layer_context()` (Redis outage degrades gracefully).
- Read receipts (`mark_messages_as_read`, `mark_single_message_as_read`, auto-mark GET) → queue `send_read_notification` Celery (FCM `message_read`, respecte `message_read_notifications`).
- New `Call` RINGING → `send_call_notification` (FCM high-priority `ringtone.caf`).
- `Call` `post_save` `handle_call_update` broadcast `incoming_call`/`call_update`.

**Reconnexion** : pas de logique serveur. Présence TTL 1h, typing TTL 10s. **Pas de replay buffer** — events émis pendant offline client sont perdus (sauf FCM push qui fire quand même).

### 4.3 Contrats — écarts frontend doc vs backend réel

| Frontend doc (`FRONTEND_MESSAGING_API.md`) | Backend réel | Statut |
|---|---|---|
| `GET /conversations/?filter=all|unread|archived` | Only `status=archived` (returns none) ; `unread` non implémenté | ⚠️ Manquant |
| `GET /conversations/` response clé `participant` | Backend retourne `other_user` | ❌ Key mismatch (frontend déjà adapté) |
| `GET /conversations/` champ `unread_count` | Backend retourne `unread_count_for_me` | ❌ Key mismatch (frontend déjà adapté) |
| `GET .../messages` top-level `messages` + `pagination` | Backend retourne DRF `count/next/previous/results` + `has_more` + `show_premium_prompt` | ⚠️ Shape diffère (frontend déjà adapté) |
| `POST .../messages` body `message_type` | Backend attend `type` | ❌ Field name mismatch (frontend déjà adapté — envoie `type`) |
| `POST .../messages` success wrappé `{message:{...}}` | Backend flat `MessageSerializer` | ❌ Wrapping mismatch (frontend déjà adapté) |
| `POST .../messages` media via multipart même endpoint | Backend endpoint séparé `POST .../messages/media/` | ⚠️ Endpoint mismatch (frontend utilise URL signée à la place) |
| `PUT /calls/{id}/answer` | Backend `POST /calls/{id}/answer` | ❌ Method mismatch |
| `PUT /calls/{id}/end` reason `normal|declined|failed|timeout` | Backend `POST /calls/{id}/terminate` reason `declined|ended_by_caller|ended_by_callee|no_answer|connection_failed|duration_limit_reached` | ❌ Method + path + vocab mismatch |
| `POST /calls/` body `callee_id` | Backend `POST /calls/initiate` body `target_user_id` | ❌ Field + path mismatch |
| Polling fallback non-premium | Non implémenté (WS only) | ⚠️ Manquant |
| Message reactions / ephemeral / E2E | Non implémenté (model `MessageReaction` existe mais pas d'endpoint) | ⚠️ Manquant |
| Block/report depuis messaging | Pas d'endpoint dans `messaging.urls` ; reporting commenté dans `api_urls.py` (`moderation.urls`) | ❌ Manquant (frontend appelle `BlockUser`/`ReportUser` use cases — vérifier où ils pointent) |

**Conclusion** : `FRONTEND_MESSAGING_API.md` est **stale**. Le frontend a déjà été adapté au backend réel. **Régénérer la doc depuis les serializers réels** ou aligner le backend sur la doc (décision backend, hors périmètre frontend).

### 4.4 Clés JSON à respecter (frontend déjà aligné)

- Conversation : `other_user.{user_id,display_name,main_photo_url,is_online,last_active}`, `last_message.{message_id,content_preview,sender_id,sent_at,is_read_by_me}`, `unread_count_for_me`, `last_message_at`, `last_activity_at`.
- Message : `message_id`|`id`, `client_message_id`, `conversation_id`, `sender_id`, `is_mine`, `content`, `message_type`, `media_url`, `media_type`, `media_thumbnail_url`, `status`, `sent_at`|`created_at`, `delivered_at`, `read_at`, `read_at_by_recipient`, `is_sending`.
- Send : `client_message_id` (req), `content?`, `type` (text|image|video|audio), `media_file_path_on_storage?`.
- Mark-as-read : `last_read_message_id?`.
- Typing : `is_typing`.
- Presence : `participant.{user_id,is_online,last_active,is_typing}`.

### 4.5 Endpoint média — 2 flows incohérents (CRITIQUE)

1. **Flow URL signée (utilisé par le frontend)** : `POST /generate-media-upload-url/` → PUT Dio brut vers `upload_url` (GCS non signé — bug backend §3.4.2) → POST `/messages/` body `{type,media_file_path_on_storage,client_message_id,content?}`. **Problème** : le backend ne construit pas `media_url` sur ce path (bug §3.4.4) → le message créé a `media_url` vide.
2. **Flow multipart (endpoint séparé, premium)** : `POST /messages/media/` multipart `media_file` ≤10MB. `MessageService.create_media_message` construit `media_url` depuis `MEDIA_URL` + path. **Mais `MessagingApi.sendMediaMessage` (frontend) est dead code** — jamais appelé par le repo.

**Décision d'implémentation à prendre** : soit basculer le frontend sur le flow multipart `POST /messages/media/` (qui construit `media_url` côté backend), soit produire un `BACKEND_MEDIA_URL_SIGNED.md` demandant au backend de (a) signer réellement `generate-media-upload-url` et (b) construire `media_url` sur le path URL signée. **Recommandé** : basculer sur le flow multipart (plus simple, backend déjà fonctionnel, premium-gated naturel) + produire `BACKEND_*.md` pour le nettoyage du flow URL signée.

---

## 5. i18n — audit

### 5.1 Clés i18n existantes (FR/EN OK)

- `navigation.messages`
- `chat.*` (default_user, typing, online, last_seen, audio_call, video_call, view_profile, block_user, report_user, its_a_match, start_conversation, quick_hello, quick_hello_message, quick_compliment, quick_compliment_message, call_feature_coming_soon, recording, type_message, attach_media, feature_coming_soon, premium_media_message, profile_unavailable, block_confirm_title, block_confirm_message, report_dialog_title, report_dialog_message, report_reason_inappropriate, report_reason_harassment, report_reason_scam, report_reason_other, report_details_label, block_success, report_success, action_error)
- `conversations.*` (search, options, open, mark_read, delete, delete_title, delete_message, delete_unavailable, no_message, media_photo, media_video, media_voice, own_message_prefix)
- `common.*` (cancel, retry, error, just_now, minutes_ago, hours_ago, days_ago, yesterday, weekday_mon..sun, days_ago_short, view_profile, block, report, delete)

### 5.2 Chaînes hardcoded (i18n violations)

| Fichier | Chaîne(s) | Clé i18n à créer |
|---|---|---|
| `conversations_page.dart` L~225 | `'Notifications'` (tooltip cloche) | `common.notifications` |
| `empty_conversations_view.dart` | `'Aucun résultat'`, `'Aucune conversation ne correspond à "$searchQuery"'`, `'Aucune conversation'`, `'Vos conversations apparaîtront ici.\nCommencez par matcher avec quelqu\'un! 💬'`, `'Voir mes matches'`, `'Chargement de vos conversations...'`, `'Oups, une erreur est survenue'`, `'Réessayer'` | `conversations.empty_search_title`, `conversations.empty_search_subtitle`, `conversations.empty_title`, `conversations.empty_subtitle`, `conversations.view_matches`, `conversations.loading`, `conversations.error_title`, `conversations.retry` |
| `conversations_search_bar.dart` | `'Rechercher une conversation...'` | `conversations.search_placeholder` |
| `widgets/cards/conversation_card.dart` (doublon mort) | `'Supprimer la conversation'`, `'Cette action est irréversible.'`, `'Annuler'`, `'Supprimer'`, `'Maintenant'` | (supprimer le fichier doublon) |
| `message_input.dart` | `'GIFs'`, `'Stickers'` (tooltips) | `chat.gifs`, `chat.stickers` |

### 5.3 Clés i18n manquantes à créer

- `common.notifications`
- `conversations.search_placeholder`
- `conversations.empty_title`, `conversations.empty_subtitle`, `conversations.empty_search_title`, `conversations.empty_search_subtitle`, `conversations.view_matches`
- `conversations.loading`, `conversations.error_title`, `conversations.retry`
- `chat.gifs`, `chat.stickers`
- (optionnel) `chat.message_failed`, `chat.message_sending` (pour distinguer les statuts `sending`/`failed` dans `MessageBubble`)
- (optionnel) `chat.media_video`, `chat.media_voice`, `chat.media_audio`, `chat.call_log_*`, `chat.system_*` (pour le rendu des types non-texte/non-image dans `MessageBubble`)

---

## 6. Tests — couverture actuelle

| Fichier test | Couvre | Statut |
|---|---|---|
| `test/domain/entities/messaging_contract_mapping_test.dart` | `Conversation.fromJson` (other_user), `Message.fromJson` (content_preview) | ✅ 2 tests pass |
| `test/domain/usecases/message/get_conversations_test.dart` | `GetConversations` use case | à vérifier |
| `test/domain/usecases/chat/{send_text_message,send_media_message,mark_message_as_read,get_messages,delete_message}_test.dart` | Use cases chat | à vérifier |
| `test/presentation/blocs/chat/chat_bloc_test.dart` | `ChatBloc` | à vérifier |
| `test/presentation/blocs/conversations/conversations_bloc_test.dart` | `ConversationsBloc` | à vérifier |

**Manquants** : tests `MessageRepositoryImpl`, `MessagingApi`, `ChatWebSocketService`, `MessageModel`, `MessageBubble`, `MessageInput`, `ConversationsPage`, `ChatPage` widget tests.

---

## 7. Fonctionnalités — synthèse de statut

### 7.1 Liste des conversations

| Fonctionnalité | Statut | Détail |
|---|---|---|
| Chargement initial | ✅ | OK |
| Pull-to-refresh | ⚠️ | Délai artificiel 500 ms à retirer |
| Infinite scroll / pagination | ❌ | `getConversations` ignore le curseur → boucle |
| Recherche | ⚠️ | Locale sur `lastMessage.content` seulement, pas par nom participant |
| Badge non-lu total | ✅ | OK |
| Badge non-lu par conversation | ✅ | OK |
| Mark-as-read (tap) | ⚠️ | Perd les champs other-user après optimistic update |
| Marquer lu (option long-press) | ⚠️ | Idem |
| Voir profil (long-press) | ⚠️ | Utilise `participantIds.first` au lieu de `otherUserId` |
| Supprimer conversation | ❌ | Endpoint backend manquant + UI affiche SnackBar |
| État vide | ⚠️ i18n | 8 chaînes hardcoded |
| État loading | ⚠️ i18n | Chaîne hardcoded |
| État error | ⚠️ i18n | Chaînes hardcoded |
| Notifications cloche | ⚠️ i18n | Tooltip hardcoded |
| Menu options (more_vert) | ❌ dead | Callback vide |
| Temps réel (new conversation / new message) | ❌ | Pas de WS sur la liste, pas de `watchConversations` (UnimplementedError) |
| Filtre unread | ❌ | Backend non implémenté |

### 7.2 Chat / conversation ouverte

| Fonctionnalité | Statut | Détail |
|---|---|---|
| Chargement messages | ✅ | OK |
| Pagination messages | ⚠️ | Mélange `page=1` + `before_message_id` |
| Envoi texte | ✅ | Optimistic + rollback |
| Envoi média image | ⚠️ | Bulle vide jusqu'à confirmation + flow URL signée cassé côté backend |
| Envoi média vidéo | ⚠️ | Idem + `MessageBubble` ne rend pas vidéo |
| Envoi voice | ❌ | Recording cassé (envoie `'0:00'`) + `MessageBubble` ne rend pas voice |
| Envoi audio | ❌ | `MessageBubble` ne rend pas audio |
| Statut message (sending/sent/delivered/read/failed) | ⚠️ | Bulle ne distingue que `read` vs else |
| Suppression message | ❌ | `onDelete` jamais appelé par la bulle |
| Read receipts temps réel | ❌ | Backend ne broadcast pas `read` WS event |
| Typing indicator (outbound) | ⚠️ | BLoC no-op local (REST + WS envoyés mais état local inchangé) |
| Typing indicator (inbound) | ✅ | WS handler OK |
| Présence online/last seen | ✅ | WS handler OK |
| Block user | ✅ | OK |
| Report user | ✅ | OK |
| Appel audio | ❌ stub | WebRTC exclu du périmètre |
| Appel vidéo | ❌ stub | WebRTC exclu du périmètre |
| Quick messages (empty state) | ✅ | OK |
| Scroll-to-bottom FAB | ✅ | OK |
| Timestamp dividers (>1h) | ✅ | OK |
| Emoji picker | ✅ | OK (140 emojis hardcoded — acceptable) |
| GIF picker | ❌ stub | Toast « coming soon » |
| Sticker picker | ❌ stub | Toast « coming soon » |
| Premium dialog upgrade | ❌ | Bouton « Upgrade » ne fait rien |
| Photo tap-to-zoom | ❌ | Pas implémenté |
| Copy message | ❌ | Pas implémenté |
| Reactions | ❌ | Backend model existe mais pas d'endpoint |
| WebSocket reconnexion | ❌ | Pas de reconnexion auto |
| WebSocket heartbeat | ❌ | Pas de heartbeat loop |
| Déconnexion propre | ⚠️ | `DisconnectFromWebSocket` jamais émis |

### 7.3 Notifications & présence

| Fonctionnalité | Statut | Détail |
|---|---|---|
| FCM push new message | ✅ backend | Celery task `send_message_notification` |
| FCM push message read | ✅ backend | `send_read_notification` |
| FCM push incoming call | ✅ backend | `send_call_notification` high-priority |
| Notifications screen | ✅ | `NotificationsBloc` fourni par `ConversationsPage` |
| Présence online | ⚠️ | 2 définitions coexistent (cache per-conversation vs `last_active<300s`) |
| Last seen | ✅ | OK |
| Read receipt setting respect | ✅ backend | Respecte `new_message_notifications`/`message_read_notifications` |
| Missed-event replay | ❌ | Pas de replay buffer WS |

---

### 7.4 Finitions & détails discrets (points importants à vérifier)

> Cette sous-section consolide les finitions, bugs discrets et détails UI/UX fréquemment oubliés dans un module de chat — même quand les grandes fonctionnalités sont en place. Source : rapport dédié `FINITIONS_CHAT_MESSAGES.md`, croisé avec le code HIVMeet. Chaque item est **indépendant, faible risque, mais effet perçu élevé** sur la qualité de l'expérience. À traiter comme une **checklist de finition** après stabilisation des fonctionnalités majeures (§10.1).

#### 7.4.1 Scroll & navigation dans la conversation

| # | Finition | Statut HIVMeet | Impact | Recommandation |
|---|---|---|---|---|
| F1 | Auto-scroll au nouveau message **seulement si l'utilisateur est en bas** | ⚠️ partiel | UX moyenne — message entrant pendant scroll-up passe inaperçu (pas de bannière « ↓ Nouveau message ») | Mémoriser `_wasAtBottom` dans `_onScroll` ; si `false` → bannière discrète tappable qui scroll en bas |
| F2 | Auto-scroll au **premier chargement** si messages > viewport | ❌ manquant | UX moyenne — la liste s'affiche en haut (message le plus ancien) au lieu du bas | Post-frame `_scrollToBottom()` dans le listener `ChatLoaded` (quand `_allMessages` nouvellement rempli) ; ou `ListView.builder(reverse: true)` |
| F3 | FAB « scroll-to-bottom » ne oscille pas pendant l'animation auto | ⚠️ | Mineur | Flag `_isAutoScrolling` ignoré dans `_onScroll` ; remis à false dans `animateTo(onComplete:)` |
| F4 | Restauration de la position de scroll au retour | ❌ manquant | UX moyenne — position de lecture perdue en quittant/revenant | `PageStorageKey(conversationId)` sur la `ListView` ou `ScrollController` persisté au niveau supérieur |
| F5 | `_isScrolledToBottom` tolérance 25 % viewport trop large | ⚠️ | Mineur — marque « lu » même si dernier message pas vraiment vu | Tolérance plus stricte (~80px ou 5 % viewport) |

#### 7.4.2 Saisie & clavier

| # | Finition | Statut HIVMeet | Impact | Recommandation |
|---|---|---|---|---|
| F6 | Debounce sur le typing indicator | ❌ manquant | Coût data + charge serveur (spam `POST /typing/` + WS à chaque caractère) | Debounce 800-1500 ms pour `onStopTyping` ; `onStartTyping` seulement à la 1re frappe d'une session de saisie |
| F7 | `onStopTyping` émis explicitement à l'envoi | ❌ manquant | Le destinataire voit « typing… » pendant 10s (TTL backend) après l'envoi | `_sendTextMessage` → `SetTypingStatus(isTyping: false)` avant `SendTextMessageEvent` |
| F8 | Emoji picker restaure la sélection du curseur | ⚠️ à vérifier | Mineur | Conserver `_textController.selection` avant insertion, restaurer après avec offset décalé |
| F9 | Emoji picker se ferme au tap extérieur | ⚠️ à vérifier | Mineur | `onTapOutside` (Flutter 3.7+) ou `GestureDetector` global |
| F10 | Champ texte grandit avec le contenu multi-lignes | ⚠️ à vérifier | UX — long message en 1 ligne, scroll horizontal | `maxLines: null` (ou 5 max), `minLines: 1` |
| F11 | Bouton envoi désactivé visuellement ET haptique | ⚠️ | Mineur — feedback trompeur | Vérifier qu'aucun `HapticFeedback` n'est déclenché quand `hasText == false` |
| F12 | Fermeture du clavier au tap dans la zone de messages | ❌ manquant | UX — clavier masque une partie de la conversation | `GestureDetector` sur le `ListView` qui `_focusNode.unfocus()` au tap |
| F13 | Gestion du « retour » quand le clavier est ouvert | ⚠️ à vérifier | UX — 1er back ferme le clavier, 2e back sort du chat | `FocusManager.instance.primaryFocus?.unfocus()` dans `PopScope.onPopInvoked` |

#### 7.4.3 Bulles de message

| # | Finition | Statut HIVMeet | Impact | Recommandation |
|---|---|---|---|---|
| F14 | Statut `sending`/`failed` distingué visuellement | ❌ manquant (§3.1.5) | **Grave** — l'utilisateur croit son message envoyé alors qu'il a échoué, ne retry pas | `sending` → `CircularProgressIndicator`/`Icons.access_time` ; `failed` → `Icons.error_outline` rouge + tap pour retry |
| F15 | Retry sur message échoué | ❌ manquant | Suite de F14 | `GestureDetector` sur bulle `failed` → menu « Réessayer / Supprimer / Copier » |
| F16 | Copie de message (long-press) | ❌ manquant | UX standard attendu | Long-press bulle → `showModalBottomSheet` : Copier / Répondre / Supprimer (si own) |
| F17 | « Répondre à » (reply/quote) | ❌ manquant | UX moderne attendue | Long-press → « Répondre » → prévisualisation au-dessus du `MessageInput` ; nécessite champ backend `replyTo` → `BACKEND_*.md` si requis |
| F18 | Timestamp relatif ambigu (`HH:mm` seul) | ⚠️ | Mineur — message ancien non daté | Long-press → date complète (`12 juil. 2026, 14:32`) en tooltip/menu |
| F19 | Image sans placeholder/loading/error | ❌ manquant (§2.6) | UX — écran vide pendant chargement, crash si URL morte | `CachedNetworkImage` (déjà utilisé dans `conversation_card.dart` — harmoniser) + `loadingBuilder`/`errorBuilder` |
| F20 | Tap-to-zoom sur image | ❌ manquant | UX standard attendu | `GestureDetector(onTap: ...)` → `PhotoView` (package `photo_view`) plein écran + pinch-to-zoom |
| F21 | Types video/voice/audio/callLog/system rendus | ❌ manquant (§3.1.4) | **Grave** — bulles vides | `video` → thumbnail + `Icons.play_circle` ; `voice`/`audio` → mini-lecteur (play + duration + slider) ; `callLog` → texte stylé « Appel manqué/12:34 » ; `system` → bulle centrée italique |
| F22 | Liens non cliquables | ❌ manquant | UX — URL en texte brut | `SelectableText.rich` + `TextSpan` détectant URL via regex + `TapGestureRecognizer` → `launchUrl` |
| F23 | Sélection de texte | ❌ manquant | UX — pas de copie manuelle | `SelectableText` pour les messages reçus (pas les propres — gênerait le long-press) |
| F24 | Date complète sur dividers peu lisibles | ⚠️ | Mineur — divider « 14:32 » ambigu après 24h | Divider affiche « Aujourd'hui / Hier / 12 juil. » + heure si pertinent |
| F25 | Heure en format 24h non localisée | ⚠️ | i18n — EN attend 12h AM/PM | `DateFormat.jm(LocalizationService.locale.toString())` |

#### 7.4.4 Temps réel & WebSocket

| # | Finition | Statut HIVMeet | Impact | Recommandation |
|---|---|---|---|---|
| F26 | Reconnexion automatique (backoff exponentiel) | ❌ manquant (§3.1.7) | **Grave** — drop réseau = temps réel mort jusqu'à navigation away/back | Backoff 1s→2s→4s→8s→max 30s dans `ChatWebSocketService._onDone` (si `!_intentionalClose`) + émission `WsEventType.reconnecting` |
| F27 | Heartbeat / keep-alive | ❌ manquant (§3.1.8) | Grave — idle sockets tués par proxies silencieusement | `Timer.periodic(30s, sendPing)` ; si pas de `pong` en 60s → `disconnect` + reconnect |
| F28 | Indicateur « connexion perdue » | ❌ manquant | UX — l'utilisateur ne sait pas qu'il est hors ligne | `MaterialBanner` discrète « Connexion instable — récupération en cours… » quand `!_wsService.isConnected` pendant >3s |
| F29 | Typing indicator outbound no-op sur l'état local | ⚠️ (§3.1.2) | Mineur — acceptable tel quel | Ne pas « fixer » en mettant `isTyping: true` pour soi-même (trompeur) ; laisser le WS inbound gérer |
| F30 | Défense en profondeur dédup écho WS | ⚠️ à surveiller | Mineur — si backend droppe `client_message_id` un jour, doublon | Test d'intégration vérifiant la présence de `client_message_id` dans l'écho WS ; fallback dédup par `content`+`senderId`+`createdAt±2s` |
| F31 | Presence TTL 1h vs socket fermeture immédiate | ⚠️ backend | Mineur — kill app → « online » à tort pendant 1h | `BACKEND_PRESENCE_TTL.md` : réduire TTL presence à ~60s (refresh via heartbeat) |
| F32 | Read receipts non temps réel pour l'expéditeur | ❌ (§3.4.9) | UX — `done`→`done_all` ne se met pas à jour sans recharger | `BACKEND_READ_RECEIPT_WS_BROADCAST.md` + frontend : `WsEventType.readReceipt` + handler BLoC qui met à jour `status: MessageStatus.read` |

#### 7.4.5 Liste des conversations

| # | Finition | Statut HIVMeet | Impact | Recommandation |
|---|---|---|---|---|
| F33 | Mark-as-read perd les champs other-user | ❌ bug (§3.2.2) | **Grave** — la card perd nom/photo/online après tap | `conv.copyWith(unreadCount: 0)` au lieu de reconstruire `Conversation` |
| F34 | Pagination conversations boucle (curseur ignoré) | ❌ bug (§3.2.1) | **Grave** — infinite scroll répète la page 1 | Câbler le curseur (page-based DRF : `page: _currentPage + 1`) |
| F35 | Recherche ne filtre que sur `lastMessage.content` | ⚠️ (§3.2.3) | UX — recherche par nom ne marche pas | Ajouter `conv.otherUserName?.toLowerCase().contains(query)` |
| F36 | Draft de message non envoyé | ❌ manquant | UX — texte perdu en quittant le chat | Persister `_textController.text` par `conversationId` (`SharedPreferences` ou `flutter_secure_storage`) |
| F37 | Pull-to-refresh « trop rapide » | ⚠️ | Mineur — l'utilisateur a l'impression que rien ne s'est passé | `Future.wait([_load(), Future.delayed(400ms)])` (minimum visible duration) |
| F38 | Indicateur « nouvelles conversations » temps réel | ❌ manquant | UX — pas de WS sur la liste, pas de `watchConversations` (`UnimplementedError`) | WS notifications (`/ws/notifications/` déjà exposé backend) → abonner la liste aux `new_match` events → recharger |
| F39 | Badge non-lu total non rafraîchi après lecture dans le chat | ⚠️ | UX — badge obsolète au retour | `ConversationsBloc.add(MarkConversationAsRead)` côté `ChatPage` avant `pop` |
| F40 | Long-press « Voir profil » utilise `participantIds.first` | ⚠️ (§3.1.20) | Mineur — ouvre le mauvais profil si ordre instable | `conversation.otherUserId ?? participantIds.firstWhere((id) => id != currentUserId)` |
| F41 | Tri des conversations fragile | ⚠️ | Mineur — flicker si `updatedAt` identique sub-ms | Tri stable par `updatedAt DESC, lastActivityAt DESC, id DESC` |
| F42 | Avatar de conversation sans indication online | ⚠️ | UX — `isOnline` disponible mais non affiché | Badge vert 10px en bas-droite de l'avatar quand `conversation.isOnline == true` |
| F43 | Badge non-lu > 99 affiche « 100 » au lieu de « 99+ » | ⚠️ | Mineur — casse le layout | `unreadCount > 99 ? '99+' : unreadCount.toString()` |
| F44 | Aperçu dernier message « Vous : » préfixe | ⚠️ à vérifier | Mineur | Vérifier que `conversations.own_message_prefix` contient bien « Vous : » / « You: » avec espace final |
| F45 | Swipe-to-archive/delete | ❌ manquant | UX mobile standard | `Dismissible` sur chaque card (endpoint backend archivage manquant → `BACKEND_MESSAGING_DELETE_CONVERSATION.md`) |

#### 7.4.6 Sécurité, vie privée & robustesse

| # | Finition | Statut HIVMeet | Impact | Recommandation |
|---|---|---|---|---|
| F46 | `_buildClientMessageId` collision | ⚠️ (§3.2.9) | Mineur — 2 envois dans la même microseconde → dédup collision (2e message droppé) | `uuid` package ou `'client_${microsecondsSinceEpoch}_${Random().nextInt(1<<32)}'` |
| F47 | `catch (e) → ServerFailure(message: e.toString())` leak | ⚠️ (§3.2.12) | Moyen — exception brute (parfois PII) remonte à l'utilisateur | Messages génériques i18n (`common.error_unknown`) + log interne ; ne pas exposer `e.toString()` |
| F48 | Limite de longueur côté UI | ❌ manquant (§3.3.2) | UX — l'utilisateur tape 10 000 caractères → backend rejette (400) sans explication | `maxLength: AppConstants.maxMessageLength` sur le `TextField` + compteur discret (850/1000 gris, rouge si dépasse) |
| F49 | Token JWT en query string WS | ⚠️ (§9) | Moyen — token loggé par proxies/CDN | Passer en header `Authorization` (backend `ConversationConsumer` le supporte déjà en priorité) via `WebSocketChannel.connect(uri, headers: ...)` |
| F50 | Media URL non expirée vérifiée | ❌ manquant | UX — upload échoue si >15 min (gallery browsing lent) | Vérifier `DateTime.now().isBefore(generatedAt + expiresInSeconds)` avant le PUT ; si expiré, régénérer |
| F51 | Media upload sans timeout / retry | ⚠️ (§3.2.6) | UX — upload GCS lent/instable pend indéfiniment | `BaseOptions(connectTimeout: 30s, receiveTimeout: 60s)` + indicateur de progression (`onSendProgress`) + bouton cancel |
| F52 | Pas d'annulation de l'envoi média | ❌ manquant | UX — l'utilisateur doit attendre un upload 50MB | `CancelToken` Dio + bouton « × » sur la bulle `sending` (média) |
| F53 | Pas de preview du média avant envoi | ❌ manquant | UX — la photo s'envoie immédiatement, pas de crop/confirm | Écran de confirmation avec preview + caption + bouton Annuler/Envoyer |
| F54 | Reactions crash si valeur non-string | ⚠️ (§3.2.13) | Mineur — crash si backend envoie `int`/`null` | `v?.toString() ?? ''` ou try/catch ; si le backend n'envoie jamais de reactions (pas d'endpoint), supprimer le champ |

#### 7.4.7 Performance & mémoire

| # | Finition | Statut HIVMeet | Impact | Recommandation |
|---|---|---|---|---|
| F55 | `_typingController.repeat(reverse: true)` tourne en continu | ⚠️ (§3.1.18) | Mineur — 60 FPS à soutenir pour rien, batterie | `_typingController.repeat` uniquement quand `state.isTyping == true` ; `stop()` sinon |
| F56 | Pas de cache d'images message | ⚠️ (§2.6) | Mineur — re-fetch à chaque rebuild | `CachedNetworkImage` (déjà dépendance) partout |
| F57 | ListView.builder sans `cacheExtent` | ⚠️ | Mineur — scroll janky sur longues conversations | `ListView.builder(cacheExtent: 1000)` |
| F58 | Rebuild du `BlocBuilder` trop large | ⚠️ | Mineur — tout `ChatPage` rebuild à chaque message (même l'`AppBar`) | `BlocBuilder(buildWhen: (prev, curr) => prev.messages != curr.messages)` sur la liste ; `BlocBuilder` séparé sur l'`AppBar` avec `buildWhen` sur `isTyping/otherIsOnline` |

#### 7.4.8 Accessibilité (a11y)

| # | Finition | Statut HIVMeet | Impact | Recommandation |
|---|---|---|---|---|
| F59 | Bulles sans `Semantics` | ❌ manquant | A11y — screen reader ne lit pas le statut/expéditeur/heure | `Semantics(label: 'Message de ${senderName} à ${time}, ${status}', button: true)` sur chaque bulle |
| F60 | Indicateur « typing » non annoncé | ❌ manquant | A11y | `Semantics(liveRegion: true, label: '...')` sur le statut |
| F61 | Bouton envoi sans `tooltip`/`Semantics` | ❌ manquant | A11y — TalkBack lit « bouton » sans contexte | `Tooltip(message: 'Envoyer')` ou `Semantics(label: 'Envoyer')` |
| F62 | Contraste des timestamps | ⚠️ à vérifier | A11y — `AppColors.slate` sur blanc souvent < 4.5:1 | Audit contraste WCAG AA, assombrir si nécessaire |
| F63 | Taille de tap cible < 48px | ⚠️ à vérifier | A11y — bouton emoji/média parfois <48px | `SizedBox(width: 48, height: 48)` minimum sur tous les boutons actionnables |
| F64 | Pas de `ExcludeSemantics` sur les éléments décoratifs | ❌ manquant | A11y — le screen reader annonce les dividers/animations | `ExcludeSemantics` sur les dividers purement visuels |

#### 7.4.9 Edge cases de données

| # | Finition | Statut HIVMeet | Impact | Recommandation |
|---|---|---|---|---|
| F65 | Message vide autorisé visuellement | ⚠️ | Mineur — bulle texte optimiste avec `content: ''` (cas media) apparaît vide une fraction de seconde | Ne pas afficher de bulle texte si `content.isEmpty && type == text` |
| F66 | Heure du message à `DateTime.fromMillisecondsSinceEpoch(0)` si `created_at` absent | ⚠️ (§2.8 entity) | Mineur — affiche « 00:00 » ou date 1970 | Fallback `DateTime.now()` pour les messages entrants ; ou `null` + bulle sans timestamp |
| F67 | Conversation sans `other_user` | ⚠️ | Mineur — `otherUserName` null → fallback `chat.default_user` | Vérifier que le placeholder avatar (initiales/icône) est géré dans `_buildProfilePhoto` |
| F68 | Date `lastActive` dans le futur | ⚠️ | Mineur — décalage d'horloge → « à l'instant » pour toujours | `if (lastActive.isAfter(DateTime.now())) return 'chat.online';` |
| F69 | ID conversation avec caractères spéciaux dans URL | ⚠️ | Mineur — `context.push('/chat/${id}')` sans `Uri.encodeComponent` | `Uri.encodeComponent(conversation.id)` (défense en profondeur) |
| F70 | Caractères RTL (arabe, hébreu) | ⚠️ | Mineur — `Text` gère la direction Unicode, mais l'alignement de la bulle reste lié à `isOwnMessage` | Acceptable ; si support RTL complet prévu, `Directionality` widget |
| F71 | Emoji multi-caractères (ZWIJ, skin tones) | ⚠️ si `maxLength` appliqué | Mineur — troncature au milieu d'un emoji composé | Si `maxLength` appliqué, utiliser `Characters` au lieu de `String.length` |

#### 7.4.10 Internationalisation (i18n) & localisation

| # | Finition | Statut HIVMeet | Impact | Recommandation |
|---|---|---|---|---|
| F72 | Heure 24h hardcoded | ⚠️ (§5.2) | i18n — EN attend 12h | Voir F25 |
| F73 | Pluriels non gérés | ⚠️ à vérifier | i18n — « 1 jour / 5 jours » propre | Audit des clés `days_ago`, `minutes_ago`, `hours_ago` pour les règles de pluriel FR/EN (`Intl.plural`) |
| F74 | Format date/heure non sensible à la locale | ⚠️ | i18n | `DateFormat.jm(LocalizationService.locale.toString())` |
| F75 | ~15 chaînes FR hardcoded | ❌ (§5.2) | i18n — violations | Voir §5.2 / §5.3 du présent rapport |
| F76 | Pas de fallback i18n explicite | ⚠️ à vérifier | Mineur — clé manquante retourne la clé elle-même (`chat.foo`) | Fallback chaîne EN, puis `[missing: key]` en debug |
| F77 | Tri alphabétique des conversations dépend de la locale | ⚠️ (si tri ajouté) | Mineur — « é » doit trier avec « e » en FR | `String.compareTo` insensible à la locale via collator |

#### 7.4.11 États vides & transitions

| # | Finition | Statut HIVMeet | Impact | Recommandation |
|---|---|---|---|---|
| F78 | État vide « It's a match! » affiché même sans match réel | ⚠️ | Mineur — trompeur si tous les messages sont supprimés | Distinguer « conversation vide après suppression » (texte neutre « Début de la conversation ») vs « nouveau match » (quick messages) |
| F79 | Pas de skeleton loader | ⚠️ | UX — spinner simple au lieu de shimmer | `Shimmer` package + skeleton `ConversationCard` placeholder |
| F80 | Error state sans distinction cause (réseau vs serveur) | ⚠️ | UX — message brute, pas d'action adaptée | Mapper `Failure` type → message + action (`NetworkFailure` → « Vérifiez votre connexion » + Retry ; `ServerFailure` → « Serveur indisponible » + Réessayer plus tard) |
| F81 | Pas de transition animée entre empty / loaded | ⚠️ | Mineur — le contenu « saute » | `AnimatedSwitcher` entre les états |

#### 7.4.12 Cycle de vie & navigation

| # | Finition | Statut HIVMeet | Impact | Recommandation |
|---|---|---|---|---|
| F82 | `DisconnectFromWebSocket` jamais émis | ⚠️ (§3.1.12) | Mineur — WS coupé via `close()` seulement | `_chatBloc.add(DisconnectFromWebSocket())` avant `_chatBloc.close()` dans `dispose` |
| F83 | `ChatBloc` fermé manuellement au lieu de `BlocProvider` | ⚠️ | Mineur — risque « BlocProvider.of() called with a closed bloc » | `BlocProvider(create: (_) => getIt<ChatBloc>(), child: ChatPage(...))` ; le provider gère `close` |
| F84 | Pas de `PopScope` pour confirmer la sortie pendant upload | ❌ manquant | UX — upload annulé sans confirmation | `PopScope(canPop: !_isUploading, onPopInvoked: ...)` → dialog « Envoi en cours, quitter ? » |
| F85 | Navigation « back » depuis le chat ne remet pas le badge | ⚠️ (F39) | UX | `ChatPage` émet `MarkConversationAsRead` côté `ConversationsBloc` avant `pop` |
| F86 | Rotation d'écran non gérée | ⚠️ | Mineur — `_scrollController` perd la position | `PageStorageKey(conversationId)` sur la `ListView` |

#### 7.4.13 Divers

| # | Finition | Statut HIVMeet | Impact | Recommandation |
|---|---|---|---|---|
| F87 | Pas de son/vibration à la réception | ❌ manquant | UX — standard : léger feedback haptique à la réception quand le chat est ouvert | `HapticFeedback.lightImpact()` sur `_onWsMessageReceived` (si `!isMine`) |
| F88 | Pas de « dernière connexion » affinée | ⚠️ | Mineur — manque « hier », « la semaine dernière », « le 12 juillet » | Enrichir les paliers de `_formatLastSeen` |
| F89 | Pas de recherche dans la conversation courante | ❌ manquant | UX (optionnel) | Optionnel (nécessite backend `GET /messages?search=` → `BACKEND_*.md`) |
| F90 | Pas de mode sombre testé | ⚠️ | Mineur — `AppColors.primaryWhite`/`platinum`/`charcoal` à vérifier en dark | Test `ThemeMode.dark` |
| F91 | Pas de gestion des gros textes (accessibilité système) | ⚠️ | A11y — bulles débordent si police système 1.5× | `MediaQuery.textScalerOf(context)` ; éviter `maxLines: 1` fixe |
| F92 | Pas de « mute » conversation | ❌ manquant | UX (optionnel) | Backend `PATCH /conversations/{id}/` avec `muted: true` → `BACKEND_*.md` |

#### 7.4.14 Synthèse — Priorisation des finitions

| Priorité | Items | Effort | Impact perçu |
|---|---|---|---|
| 🔴 Haute (UX critique, bugs visibles) | F14 (statut sending/failed), F21 (types video/voice/audio vides), F26 (reconnexion WS), F33 (mark-read perd champs), F34 (pagination boucle), F46 (collision clientMessageId), F48 (limite longueur UI) | Faible | Évite bugs visibles |
| 🟡 Moyenne (qualité perçue) | F1-F2 (auto-scroll), F6 (debounce typing), F19-F20 (image placeholder/zoom), F22 (liens), F27 (heartbeat), F35 (recherche nom), F36 (draft), F51-F53 (upload progress/cancel/preview), F55 (typing controller), F56 (cache images), F79 (skeleton loader) | Moyen | Finition notable |
| 🟢 Basse (polish) | F3-F5, F7-F13, F15-F18, F23-F25, F28-F32, F37-F45, F47, F49-F50, F54, F57-F64, F65-F77, F78, F80-F92 | Variable | Polish & robustesse long-terme |

> **Note** : les items nécessitant backend (F31 presence TTL, F32 read receipt WS, F38 new conversation WS, F45 archivage, F89 recherche, F92 mute) → produire `BACKEND_*.md` au lieu de modifier le frontend (règle non négociable §0). Les items 🔴 sont à traiter **en priorité** dans la session d'implémentation à 100 % (§10), en complément des bugs critiques §10.1.

---

## 8. Dead code / stubs à nettoyer ou implémenter

| Item | Action recommandée |
|---|---|
| `widgets/cards/conversation_card.dart` (doublon) | Supprimer (utiliser `widgets/conversations/conversation_card.dart`) |
| `MessageModel` (`data/models/message_model.dart`) | Soit le wired dans le repo (et corriger les aliases), soit le supprimer. Recommandé : supprimer (3 mapping impl déjà trop). |
| `injection_module.dart` | Supprimer (DI manuel dans `injection.dart` duplique). |
| `AppConstants.baseUrl`/`websocketUrl` hardcoded | Supprimer (utiliser `AppConfig`). |
| `RefreshConversations` event | Supprimer (utilise `LoadConversations(refresh:true)`). |
| `MarkAsReadEvent { messageId }` | Supprimer ou exposer via UI (long-press message). |
| `DisconnectFromWebSocket` event | Exposer dans `ChatPage.dispose`. |
| `showPremiumPrompt` state field | Soit l'utiliser (upsell premium), soit le supprimer. |
| `MessagingApi.sendMediaMessage` (multipart) | Soit basculer le repo dessus (recommandé), soit le supprimer. |
| `MessagingApi.markSingleMessageAsRead` | Soit l'utiliser (single-message read), soit le supprimer. |
| `ChatWebSocketService.sendTextMessage` | Soit l'utiliser (envoi via WS), soit le supprimer. |
| `ChatPage._typingController.repeat(reverse:true)` continu | Animer seulement quand `isTyping==true`. |
| `conversations_page.dart` menu more_vert | Implémenter (filtrer, trier, archiver) ou supprimer. |
| `MessageInput` GIF/stickers | Implémenter ou supprimer les boutons. |
| `MessageInput` voice recording | Implémenter (flutter_sound / record) ou supprimer le bouton. |
| `MessageInput` premium dialog « Upgrade » | Naviguer vers page premium. |
| `MessageBubble.onDelete` | Exposer via long-press menu (delete/copy/react). |

---

## 9. Risques sécurité / confidentialité

| Risque | Gravité | Statut |
|---|---|---|
| Token JWT en query string WS (log proxy/CDN) | Moyen | Mitigé si wss + pas d'intermédiaire log. |
| WS `message.send` bypass sanitization (XSS/injection) | **Élevé** | Bug backend §3.4.5. Frontend ne peut pas corriger → `BACKEND_SECURITY_WS_MESSAGE_SANITIZE.md`. |
| `generate-media-upload-url` non signé (tout client peut PUT) | **Élevé** | Bug backend §3.4.2. `BACKEND_MEDIA_UPLOAD_SIGNED_URL.md`. |
| `catch (e) → ServerFailure(message: e.toString())` leak exception brute | Moyen | Frontend à corriger (messages i18n génériques + log interne). |
| Logging interceptor déjà sanitize PII | ✅ | OK (existant). |
| `flutter_secure_storage` pour tokens | ✅ | OK (existant). |

---

## 10. Synthèse des actions pour l'implémentation à 100%

### 10.1 Bugs frontend à corriger (priorité critique)

1. `ConversationsBloc._onMarkConversationAsRead` — utiliser `copyWith` au lieu de reconstruire `Conversation` (préserver `otherUserId/otherUserName/otherUserPhotoUrl/isOnline/lastActive/lastActivityAt`).
2. `MessageRepositoryImpl.getConversations` — utiliser `lastConversationId` comme curseur (backend utilise pagination DRF `page`/`page_size` — adapter : soit page-based, soit cursor-based si backend supporte).
3. `MessageRepositoryImpl.getMessages` — ne pas mélanger `page=1` + `before_message_id` ; choisir un modèle (préférer `before_message_id` seul pour cursor).
4. `ChatBloc._onSetTypingStatus` — soit ne pas émettre local state (le WS inbound gère), soit émettre correctement `isTyping: event.isTyping` pour feedback local immédiat.
5. `MessageBubble` — exposer `onDelete` via long-press menu, distinguer `sending`/`failed`, rendre video/voice/audio/callLog/system.
6. `MessageInput` — implémenter voice recording (flutter_sound) ou supprimer le bouton.
7. `ChatPage.dispose` — émettre `DisconnectFromWebSocket` avant `close()`.
8. `ConversationsPage` menu more_vert — implémenter ou supprimer.
9. `ConversationsPage` « Voir profil » — utiliser `otherUserId` au lieu de `participantIds.first`.
10. `_onLoadMoreConversations` — ne pas émettre `ConversationsError` après rollback.

### 10.2 Flow média — décision à prendre

- **Option A (recommandée)** : basculer sur `POST /messages/media/` multipart (backend déjà fonctionnel, premium-gated, construit `media_url`). Supprimer le flow URL signée + `generateMediaUploadUrl` du repo.
- **Option B** : garder le flow URL signée + produire `BACKEND_MEDIA_UPLOAD_SIGNED_URL.md` demandant au backend de signer réellement + construire `media_url` sur le path URL signée.

### 10.3 i18n à corriger

- Créer les clés listées en §5.3 dans `assets/translations/fr.json` et `en.json`.
- Remplacer toutes les chaînes hardcoded listées en §5.2.
- Supprimer le fichier doublon `widgets/cards/conversation_card.dart`.

### 10.4 Tests à ajouter

- `MessageRepositoryImpl` tests (mock `MessagingApi`) — couvrir `getConversations` curseur, `getMessages` cursor, `sendMessage` text/media, `markAsRead`, `deleteMessage`, error mapping.
- `ChatWebSocketService` tests — connect/disconnect/events/reconnect (à implémenter).
- `ChatBloc` tests — tous les handlers (send text/media optimistic, delete, block, report, WS events).
- `ConversationsBloc` tests — load/loadMore/markAsRead (field preservation)/search.
- Widget tests — `MessageBubble` (tous types), `MessageInput` (text/media/emoji), `ConversationCard`, `ConversationsPage`, `ChatPage`.

### 10.5 Fichiers `BACKEND_*.md` à produire (règle projet)

- `BACKEND_MESSAGING_DELETE_CONVERSATION.md` — endpoint `DELETE /conversations/{id}/` manquant (déjà tracked mais pas implémenté).
- `BACKEND_SECURITY_WS_MESSAGE_SANITIZE.md` — WS `message.send` bypass sanitization.
- `BACKEND_MEDIA_UPLOAD_SIGNED_URL.md` — `generate-media-upload-url` non signé + `media_url` non construit sur path URL signée (si Option B choisie).
- `BACKEND_CONVERSATION_FILTER_UNREAD.md` — filtre `unread` non implémenté.
- `BACKEND_READ_RECEIPT_WS_BROADCAST.md` — `mark_messages_as_read` ne broadcast pas d'événement WS `read`.
- `BACKEND_AUTO_MARK_READ_ON_GET.md` — GET messages auto-marque READ avant viewport (read receipts incorrects).
- (Optionnel) `BACKEND_CONVERSATIONS_N1_QUERY.md` — N+1 queries sur conversations list.

### 10.6 Exclusions délibérées du périmètre d'implémentation

- **Appels audio/vidéo WebRTC** : laissés en stub « coming soon ». Justification : feature lourde (flutter_webrtc, signaling complet, media path, gestion durée/limite premium), pas de media path WebRTC backend exploitable, dépasse une seule session. Les méthodes `MessagingApi.initiateCall`/`answerCall`/`endCall`/`sendIceCandidate` peuvent rester en stub.
- **Message reactions** : backend model existe mais pas d'endpoint → `BACKEND_*.md` à produire, UI non implémentée.
- **E2E encryption** : pas implémenté → `BACKEND_*.md` à produire si requis.
- **Polling fallback non-premium** : pas implémenté → `BACKEND_*.md` à produire si requis.
- **GIF/stickers** : si implémentation lourde (Giphy API), laisser en stub. Sinon picker simple local.

### 10.7 Finitions & détails discrets à traiter (checklist §7.4)

La session d'implémentation à 100 % doit **compléter** les bugs critiques §10.1 par la checklist de finition §7.4 (92 items F1-F92). Priorisation recommandée :

1. **🔴 Haute priorité (bugs visibles, faible effort)** — à traiter **en plus** de §10.1 :
   - **F14** — distinguer visuellement `sending`/`failed` dans `MessageBubble` (actuellement tous apparaissent comme `sent`).
   - **F21** — rendre les types `video`/`voice`/`audio`/`callLog`/`system` dans `MessageBubble` (actuellement bulles vides).
   - **F26** — reconnexion WebSocket automatique avec backoff exponentiel dans `ChatWebSocketService`.
   - **F33** — `ConversationsBloc._onMarkConversationAsRead` utiliser `copyWith` (préserver les champs other-user) — **chevauche §10.1.1**.
   - **F34** — `MessageRepositoryImpl.getConversations` câbler le curseur de pagination — **chevauche §10.1.2**.
   - **F46** — `_buildClientMessageId` utiliser `uuid` (anti-collision) — **chevauche §3.2.9**.
   - **F48** — appliquer `maxLength: AppConstants.maxMessageLength` sur le `TextField` + compteur — **chevauche §3.3.2**.

2. **🟡 Moyenne priorité (qualité perçue, effort moyen)** — à traiter après stabilisation des bugs critiques :
   - **F1-F2** — auto-scroll conditionnel + au premier chargement.
   - **F6** — debounce sur le typing indicator (800-1500 ms).
   - **F19-F20** — `CachedNetworkImage` + `loadingBuilder`/`errorBuilder` + tap-to-zoom (`photo_view`).
   - **F22** — liens cliquables (`SelectableText.rich` + `TapGestureRecognizer`).
   - **F27** — heartbeat WebSocket (`Timer.periodic(30s, sendPing)`).
   - **F35** — recherche conversations par `otherUserName` en plus de `lastMessage.content`.
   - **F36** — draft de message persisté par `conversationId`.
   - **F51-F53** — upload média : timeout/progression + bouton cancel + preview avant envoi.
   - **F55** — `_typingController.repeat` seulement quand `isTyping == true`.
   - **F56** — `CachedNetworkImage` partout dans `MessageBubble`.
   - **F79** — skeleton loader shimmer pour `ConversationsLoadingView`.

3. **🟢 Basse priorité (polish & robustesse long-terme)** — à traiter en dernier, par lots :
   - Items F3-F5, F7-F13, F15-F18, F23-F25, F28-F32, F37-F45, F47, F49-F50, F54, F57-F64 (a11y), F65-F77 (edge cases + i18n), F78, F80-F92 (cycle de vie, divers).
   - Items nécessitant backend (F31, F32, F38, F45, F89, F92) → produire `BACKEND_*.md` (voir §10.5) au lieu de modifier le frontend.

> **Important** : les items 🔴 chevauchent les bugs critiques §10.1 — les traiter ensemble évite la duplication. Les items 🟡/🟢 sont indépendants et peuvent être traités par lots après stabilisation. Référence complète : §7.4 (F1-F92) du présent rapport, et rapport dédié `FINITIONS_CHAT_MESSAGES.md`.

---

## 11. Points à valider avec l'utilisateur avant implémentation

> Ces points sont des décisions de conception qui doivent être tranchées en amont. Recommandations fournies.

1. **Flow média** : Option A (multipart `POST /messages/media/`, recommandé) ou Option B (URL signée + `BACKEND_*.md`) ? **Recommandation : Option A.**
2. **Voice recording** : implémenter avec `flutter_sound`/`record` (effort moyen) ou supprimer le bouton voice ? **Recommandation : implémenter.**
3. **GIF/stickers** : intégrer Giphy API (premium) ou laisser stub ? **Recommandation : stub conservé (effort vs valeur).**
4. **Pagination modèle** : page-based (DRF `page`/`page_size`) ou cursor-based (`before_message_id`)? **Recommandation : cursor-based pour messages, page-based pour conversations (backend utilise DRF PageNumberPagination).**
5. **Recherche conversations** : local-only (enrichir avec noms participants) ou backend search endpoint ? **Recommandation : local-only + enrichir avec `otherUserName`.**
6. **Suppression conversation** : implémenter UI en attente backend (disable + tooltip) ou masquer l'option ? **Recommandation : masquer l'option tant que backend manquant.**
7. **Menu more_vert conversations** : implémenter (filtrer/trier/archiver) ou supprimer ? **Recommandation : supprimer (features non spécifiées).**

---

## 12. Conclusion

La page « Messages » de HIVMeet est **fonctionnellement partielle** : le core text chat + WS real-time + blocage/signalement + quick messages + emoji picker + presence/typing inbound sont implémentés. Cependant, de nombreux objets/features sont **non implémentés, cassés, ou dead code** :

- **Bugs critiques frontend** : pagination conversations cassée (curseur ignoré), mark-as-read perd les champs other-user, typing outbound no-op, suppression message injoignable, voice recording cassé, bulles vides pour video/voice/audio/system, statuts `sending`/`failed` non distingués.
- **Finitions & détails discrets manquants** (§7.4, 92 items F1-F92) : auto-scroll conditionnel, debounce typing, reconnexion WebSocket, heartbeat, image placeholder/zoom, liens cliquables, sélection de texte, copie/retry message, skeleton loader, accessibilité (Semantics/contraste/taille tap), edge cases données (date future, ID URL, RTL, emoji multi-caractères), i18n (heure 24h, pluriels, ~15 chaînes hardcoded), cycle de vie (`PopScope`, `PageStorageKey`), etc. — voir checklist complète §7.4 et priorisation §10.7.
- **Dead code** : `MessageModel`, `injection_module.dart`, `AppConstants` URLs, `widgets/cards/conversation_card.dart` doublon, events `RefreshConversations`/`MarkAsReadEvent`/`DisconnectFromWebSocket` non émis, `showPremiumPrompt` state, `MessagingApi.sendMediaMessage`/`markSingleMessageAsRead`, `ChatWebSocketService.sendTextMessage`, menu more_vert callback vide.
- **Gaps backend** (production `BACKEND_*.md`) : suppression conversation, filtre unread, `generate-media-upload-url` non signé, WS message sanitization, read receipt WS broadcast, auto-mark-read-on-GET, N+1 queries, presence TTL, mute conversation, recherche dans conversation.
- **i18n violations** : ~15 chaînes hardcoded FR.
- **Tests manquants** : `MessageRepositoryImpl`, `ChatWebSocketService`, widget tests.
- **Exclusions délibérées** : WebRTC (appels audio/vidéo), reactions, E2E, polling non-premium, GIF/stickers (si effort trop élevé).

Ce rapport sert de **contexte d'entrée complet** à une session d'implémentation à 100 % de la page Messages. L'implémenteur devra :
1. Corriger les bugs critiques frontend listés en §10.1.
2. **Traiter la checklist de finitions §7.4 (92 items F1-F92)** selon la priorisation §10.7 : 🔴 Haute (F14, F21, F26, F33, F34, F46, F48 — chevauchent §10.1, traiter ensemble), 🟡 Moyenne (F1-F2, F6, F19-F20, F22, F27, F35, F36, F51-F53, F55, F56, F79), 🟢 Basse (le reste, par lots).
3. Trancher les points §11 avec l'utilisateur (ou suivre les recommandations).
4. Corriger l'i18n (§5.2, §5.3) — inclut les finitions i18n F72-F77.
5. Ajouter les tests (§10.4).
6. Produire les `BACKEND_*.md` (§10.5) pour les gaps backend, sans modifier le backend — inclut les finitions nécessitant backend (F31, F32, F38, F45, F89, F92).
7. Respecter les exclusions délibérées (§10.6).

> **Référence complémentaire** : le rapport dédié `FINITIONS_CHAT_MESSAGES.md` (à la racine du projet) contient le détail exhaustif de chaque finition (symptôme, cause, recommandation). Le présent rapport en consolide les éléments pertinents dans §7.4 pour servir de checklist unifiée lors de l'implémentation à 100 %.