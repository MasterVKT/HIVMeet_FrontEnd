# Finitions & Bugs Discrets — Module Messagerie HIVMeet

**Date** : 2026-07-21
**Objet** : Liste détaillée des dysfonctionnements discrets, finitions et détails UI/UX fréquemment oubliés dans un module de chat — même quand les grandes fonctionnalités sont en place. Inspiré de retours d'expérience terrain (messageries mobiles natives + web) et vérifié sur le code actuel d'HIVMeet (`chat_page.dart`, `message_input.dart`, `message_bubble.dart`, `chat_bloc.dart`, `conversations_page.dart`).

**Usage prévu** : backlog de finition à parcourir après stabilisation des fonctionnalités majeures. Chaque item est indépendant, faible risque, faible effort, mais effet perçu élevé sur la qualité de l'expérience chat.

---

## 1. Scroll & navigation dans la conversation

### 1.1 Auto-scroll au nouveau message seulement si l'utilisateur est en bas
- **Symptôme** : Un message entrant arrive pendant que l'utilisateur scroll vers le haut pour relire l'historique → la liste saute violemment en bas, l'utilisateur perd sa position de lecture.
- **Cause fréquente** : `ListView.builder` avec `notifyDataSetChanged` (ajout au `_allMessages` + `emit`) sans conditionner l'auto-scroll.
- **Code HIVMeet** : `_onWsMessageReceived` ajoute le message puis `emit(currentState.copyWith(messages: _allMessages))`. `_scrollToBottom()` n'est appelé explicitement que dans `didChangeMetrics` (clavier) et `_onScroll` n'auto-scroll pas. **Comportement réel** : pas d'auto-scroll forcé, mais l'utilisateur ne sait pas qu'un message est arrivé (pas de toast « nouveau message ↓ » non plus).
- **Impact** : UX moyenne — l'utilisateur en haut de liste ne voit pas les nouveaux messages sans scroller manuellement.
- **Recommandation** : mémoriser `_wasAtBottom` dans `_onScroll` ; sur nouveau message entrant, si `_wasAtBottom` → `_scrollToBottom()` ; sinon → afficher une bannière discrète « ↓ Nouveau message » (Material `FloatingActionButton` temporaire ou `SnackBar` inline) qui, au tap, scroll en bas.

### 1.2 Pas d'auto-scroll au premier chargement si messages > viewport
- **Symptôme** : Ouverture d'une conversation avec beaucoup de messages → la liste s'affiche en haut (message le plus ancien) au lieu du bas (message le plus récent).
- **Cause** : `ListView.builder` standard (ordre ascendant) commence à l'index 0. Sans `reverse: true` ou sans `WidgetsBinding.addPostFrameCallback(_scrollToBottom)`, l'utilisateur voit d'abord l'historique ancien.
- **Code HIVMeet** : `_sortByCreatedAt` est **ascendant** (index 0 = plus ancien). `initState` ne déclenche pas `_scrollToBottom` après chargement initial ; seul `didChangeMetrics` le fait (clavier).
- **Impact** : UX moyenne — l'utilisateur doit scroll manuellement à l'ouverture pour voir les derniers messages.
- **Recommandation** : soit `ListView.builder(reverse: true)` (index 0 = plus récent, auto en bas), soit post-frame `_scrollToBottom()` dans le listener `ChatLoaded` (quand `_allMessages.isEmpty` → nouvellement rempli).

### 1.3 FAB « scroll-to-bottom » ne masque pas pendant l'animation auto
- **Symptôme** : L'auto-scroll programmatique déclenche `_onScroll` → `_showScrollToBottom` oscille (visible → invisible → visible).
- **Recommandation** : flag `_isAutoScrolling` (bool) ; dans `_onScroll`, ignorer les mises à jour si `_isAutoScrolling` ; remettre à false à la fin de `animateTo` (paramètre `onComplete`).

### 1.4 Pas de restauration de position de scroll au retour
- **Symptôme** : L'utilisateur scroll en haut pour lire l'historique, quitte le chat, revient → la liste est rechargée en bas (position perdue).
- **Cause** : `ChatBloc` est fermé à `dispose`, recréé à l'ouverture, `_allMessages` réinitialisé via `LoadConversation`.
- **Recommandation** : conserver la position scroll par `conversationId` (cache mémoire `PageStorageKey(conversationId)` sur la `ListView`, ou `ScrollController` persisté au niveau supérieur).

### 1.5 `_isScrolledToBottom` tolère 25 % de viewport
- **Code** : `position.pixels >= position.maxScrollExtent - position.viewportDimension * 0.25`. Tolérance large → marque « lu » même si l'utilisateur n'a pas vraiment vu le dernier message (en bas d'un grand écran).
- **Recommandation** : tolérance plus stricte (~80px) ou 5 % viewport.

---

## 2. Saisie & clavier

### 2.1 Pas de debounce sur le typing indicator
- **Symptôme** : Chaque frappe déclenche `onStartTyping`/`onStopTyping` → le backend est spammé de `POST /typing/` (et le WS de `typing.start`/`typing.stop`) à chaque caractère. Sur réseau mobile lent : coût data + charge serveur.
- **Cause fréquente** : `_onTextChanged` écoute `_textController`, émet sans debounce.
- **Recommandation** : debounce 800-1500 ms pour `onStopTyping` ; émettre `onStartTyping` uniquement à la première frappe d'une session de saisie (pas à chaque caractère) ; émettre `onStopTyping` seulement après X ms sans frappe (et à la perte de focus / envoi).

### 2.2 `onStopTyping` jamais émis explicitement à l'envoi
- **Symptôme** : L'utilisateur envoie un message ; chez le destinataire, l'indicateur « typing… » reste affiché jusqu'à expiration du TTL backend (10s) au lieu de disparaître immédiatement.
- **Recommandation** : `_sendTextMessage` → `_chatBloc.add(SetTypingStatus(isTyping: false))` avant `SendTextMessageEvent`.

### 2.3 Clavier emoji picker ne restaure pas la sélection
- **Symptôme** : L'utilisateur tape au milieu d'un mot, ouvre l'emoji picker, insère un emoji → l'emoji s'insère au curseur (bon) mais le focus revient parfois au début (selon implémentation).
- **Recommandation** : conserver `_textController.selection` avant insertion, restaurer après avec offset décalé.

### 2.4 Emoji picker ne se ferme pas au tap extérieur
- **Symptôme** : L'emoji picker reste visible quand l'utilisateur tap ailleurs que dans le champ.
- **Recommandation** : `GestureDetector` global ou `onTapOutside` (Flutter 3.7+) qui `_showEmojiPicker = false`.

### 2.5 Le champ texte ne grandit pas avec le contenu multi-lignes
- **Symptôme** : Un long message est tapé → le `TextField` reste 1 ligne, scroll horizontal, l'utilisateur ne voit qu'une portion.
- **Recommandation** : `maxLines: null` (ou 5 max), `minLines: 1`, `expands: false` ; ou `Scrollbar` + `maxLines: 6`.

### 2.6 Bouton envoi désactivé visuellement mais pas haptique
- **Symptôme** : Bouton envoi grisé quand pas de texte, mais un tap produit quand même un ripple/feedback haptique trompeur.
- **Recommandation** : `onTap: hasText ? _sendTextMessage : null` (déjà fait) ; vérifier qu'aucun `HapticFeedback` n'est déclenché quand `hasText == false`.

### 2.7 Pas de fermeture du clavier au tap dans la zone de messages
- **Symptôme** : L'utilisateur tap une bulle pour la sélectionner/copier → le clavier reste ouvert, masque une partie de la conversation.
- **Recommandation** : `GestureDetector` sur le `ListView` qui `_focusNode.unfocus()` au tap (sauf si un mode édition/sélection est actif).

### 2.8 Pas de gestion du « retour » quand le clavier est ouvert
- **Symptôme** : Clavier ouvert, back Android → ferme le clavier (OK) mais un 2e back doit fermer le chat. Avec `WillPopScope`, parfois le premier back sort directement du chat.
- **Recommandation** : `FocusManager.instance.primaryFocus?.unfocus()` dans `WillPopScope.onWillPop` ; retourner `false` si clavier était ouvert, `true` sinon.

---

## 3. Bulles de message

### 3.1 Statut `sending`/`failed` non distingué visuellement
- **Symptôme** : Un message en cours d'envoi (status `sending`) et un message échoué (`failed`) affichent la même icône `done` (gris) qu'un message envoyé (`sent`). L'utilisateur ne voit pas que son message n'est pas parti.
- **Code HIVMeet** : `message_bubble.dart` ne gère que `status == MessageStatus.read ? done_all : done`. `sending` et `failed` tombent dans le `else` → icône `done`.
- **Impact** : grave — l'utilisateur croit son message envoyé alors qu'il a échoué (réseau coupé), ne retry pas.
- **Recommandation** :
  - `sending` → `CircularProgressIndicator` (12px) ou `Icons.access_time` (horloge grise).
  - `failed` → `Icons.error_outline` rouge + tap pour retry (`onTap: () => _chatBloc.add(SendTextMessageEvent(content: message.content))`).
  - `sent` → `Icons.done` gris ; `delivered` → `Icons.done_all` gris ; `read` → `Icons.done_all` couleur accent.

### 3.2 Pas de retry sur message échoué
- **Symptôme** : Voir 3.1 — message `failed` ne peut pas être renvoyé.
- **Recommandation** : `GestureDetector`/`InkWell` sur la bulle `failed` → menu « Réessayer / Supprimer / Copier ».

### 3.3 Pas de copie de message
- **Symptôme** : L'utilisateur veut copier un texte reçu pour le rechercher / le partager → pas de long-press menu.
- **Recommandation** : long-press bulle → `showModalBottomSheet` : Copier / Répondre / Supprimer (si own) / Transférer (optionnel).

### 3.4 Pas de « répondre à » (reply/quote)
- **Symptôme** : Impossible de citer un message pour répondre en contexte — feature devenue standard.
- **Recommandation** : long-press → « Répondre » → prévisualisation au-dessus du `MessageInput` avec le contenu cité + bouton close ; le message envoyé porte une référence `replyTo` (nécessite champ backend — créer `BACKEND_*.md` si hors périmètre).

### 3.5 Timestamp relatif ambigu
- **Symptôme** : Bulle affiche `HH:mm` uniquement. Si l'utilisateur rouvre le chat 3 jours plus tard, il ne sait pas que le message est ancien sans scroll jusqu'au divider.
- **Recommandation** : sur long-press, afficher la date complète (`12 juil. 2026, 14:32`) en tooltip ou dans le menu contextuel.

### 3.6 Image sans placeholder / loading / error
- **Symptôme** : `MessageBubble` pour `MessageType.image` utilise `Image.network(url, width: 200)` sans `loadingBuilder` ni `errorBuilder` → écran vide pendant le chargement, puis crash/blank si URL morte.
- **Code HIVMeet** : confirmé, aucune gestion d'erreur.
- **Recommandation** : `Image.network(url, loadingBuilder: ..., errorBuilder: ...)` + `CachedNetworkImage` (déjà utilisé dans `conversation_card.dart` — harmoniser).

### 3.7 Pas de tap-to-zoom sur image
- **Symptôme** : L'utilisateur tap une image reçue → rien ne se passe. Standard attendu : ouverture en plein écran avec pinch-to-zoom.
- **Recommandation** : `GestureDetector(onTap: () => Navigator.push(... PhotoView ...))` (package `photo_view`).

### 3.8 Types video/voice/audio/callLog/system rendent une bulle vide
- **Symptôme** : Bulle totalement vide pour ces types — l'utilisateur voit un rectangle coloré sans rien.
- **Recommandation** :
  - `video` → thumbnail + `Icons.play_circle` overlay → tap ouvre lecteur.
  - `voice`/`audio` → mini-lecteur (waveform/icône play + duration + slider).
  - `callLog` → texte stylé (« Appel manqué », « Appel 12:34 » avec icône phone).
  - `system` → bulle centrée, italique, fond transparent (« X a quitté la conversation »).

### 3.9 Liens non cliquables
- **Symptôme** : Un message contient une URL `https://...` → affichée en texte brut, non tappable.
- **Recommandation** : `SelectableText.rich` avec `TextSpan` détectant les URL via regex, `recognizer: TapGestureRecognizer()..onTap = () => launchUrl(...)`.

### 3.10 Pas de sélection de texte
- **Symptôme** : Texte du message non sélectionnable (Text standard) → l'utilisateur ne peut pas copier manuellement.
- **Recommandation** : `SelectableText` pour les messages reçus (pas les propres — gênerait le long-press).

### 3.11 Pas de date complète sur dividers peu lisibles
- **Symptôme** : Dividers >1h affichent juste l'heure. Passé 24h, un divider « 14:32 » est ambigu (aujourd'hui ? hier ?).
- **Recommandation** : divider affiche « Aujourd'hui / Hier / 12 juil. » + heure si pertinent.

### 3.12 Heure en format 24h non localisée
- **Symptôme** : `DateFormat('HH:mm')` hardcoded 24h. EN attendu : `h:mm a` (12h AM/PM).
- **Recommandation** : `DateFormat.jm()` (locale-aware) ou `LocalizationService` pour choisir le pattern.

---

## 4. État temps réel & WebSocket

### 4.1 Pas de reconnexion automatique
- **Symptôme** : Le téléphone passe en mode avion 3s puis revient → la WS est fermée (`_onDone` null le socket), aucun re-tentative. Les nouveaux messages ne sont plus reçus en temps réel jusqu'à navigation away/back.
- **Recommandation** : backoff exponentiel (1s, 2s, 4s, 8s, max 30s) dans `ChatWebSocketService._onDone` (si `!_intentionalClose`), émission d'un événement `WsEventType.reconnecting` pour que le BLoC mette à jour l'UI (« Reconnexion… » dans le statut).

### 4.2 Pas de heartbeat / keep-alive
- **Symptôme** : Connexion WS idle >5 min derrière un proxy/CDN → le proxy ferme la socket silencieusement, le client croit être connecté.
- **Recommandation** : `Timer.periodic(Duration(seconds: 30), (_) => sendPing())` ; si pas de `pong` en 60s → forcer `disconnect` + reconnect.

### 4.3 Pas d'indicateur « connexion perdue »
- **Symptôme** : Voir 4.1/4.2 — l'utilisateur ne sait pas qu'il est hors ligne, continue d'envoyer des messages qui échouent silencieusement.
- **Recommandation** : bannière `MaterialBanner` discrète « Connexion instable — récupération en cours… » quand `_wsService.isConnected == false` pendant >3s.

### 4.4 Typing indicator outbound no-op sur l'état local
- **Symptôme** : L'utilisateur A tape ; l'utilisateur B voit bien « typing… » (WS inbound OK). Mais si l'utilisateur A regarde sa propre conversation, son propre `isTyping` est `false` (correct), mais il n'y a pas de feedback visuel local non plus (animation de la bulle d'envoi). Mineur.
- **Recommandation** : acceptable tel quel ; ne pas « fixer » en mettant `isTyping: true` pour soi-même ( trompeur).

### 4.5 Pas de gestion des messages entrants pendant que l'utilisateur envoie
- **Symptôme** : L'utilisateur A envoie un message optimiste (id `temp_x`) ; le WS reçoit l'écho serveur (`message_id` réel, même `client_message_id`) → `_replaceOptimisticMessage` déduplique correctement. Mais si le serveur n'inclut **pas** `client_message_id` dans l'écho WS → doublon (deux bulles : le temp + le serveur).
- **Code HIVMeet** : `SendMessageSerializer` exige `client_message_id` ; le signal `handle_new_message` broadcast `{message_id, conversation_id, sender_id, content, message_type, sent_at, client_message_id}` → OK, mais **à surveiller** (si backend droppe le champ un jour, doublon).
- **Recommandation** : test d'intégration vérifiant la présence de `client_message_id` dans l'écho WS ; défense en profondeur côté BLoC (fallback dédup par `content`+`senderId`+`createdAt±2s`).

### 4.6 Presence TTL 1h vs socket fermeture immédiate
- **Symptôme** : L'utilisateur ferme l'app brutalement (kill) → pas de `presence.update offline` envoyé → le backend garde le statut « online » pendant 1h (TTL cache). Les autres voient « en ligne » à tort.
- **Recommandation** : backend devrait réduire le TTL presence à ~60s (refresh via heartbeat) ; à documenter dans `BACKEND_PRESENCE_TTL.md`.

### 4.7 Read receipts non temps réel pour l'expéditeur
- **Symptôme** : A envoie un message ; B l'ouvre → `mark_messages_as_read` (backend) envoie une notif FCM à A, mais pas d'événement WS `message.read`. Le chat de A (s'il est ouvert) ne passe pas `done` → `done_all` en temps réel ; il faut recharger.
- **Code HIVMeet** : confirmé — pas d'événement WS `read` modélisé côté frontend (`WsEventType` n'a que `messageCreated/typingIndicator/presenceUpdate/pong/error/unknown`).
- **Recommandation** : `BACKEND_READ_RECEIPT_WS_BROADCAST.md` + frontend : ajouter `WsEventType.readReceipt` + handler BLoC qui met à jour `status: MessageStatus.read` pour les messages correspondants.

---

## 5. Liste des conversations

### 5.1 Mark-as-read perd les champs other-user
- **Code HIVMeet** : `ConversationsBloc._onMarkConversationAsRead` reconstruit `Conversation(id, participantIds, lastMessage, unreadCount:0, updatedAt)` au lieu de `copyWith` → perd `otherUserName/otherUserPhotoUrl/otherUserId/isOnline/lastActive/lastActivityAt`.
- **Symptôme** : L'utilisateur tap une conversation → la card « perd » son nom et sa photo (revient au placeholder) jusqu'au prochain refresh.
- **Recommandation** : `conv.copyWith(unreadCount: 0)`.

### 5.2 Pagination conversations boucle (curseur ignoré)
- **Code HIVMeet** : `MessageRepositoryImpl.getConversations` ignore `lastConversationId`, envoie toujours `page=1`.
- **Symptôme** : Infinite scroll → la même page 1 se répète indéfiniment.
- **Recommandation** : câbler le curseur (page-based DRF : `page: _currentPage + 1`).

### 5.3 Recherche ne filtre que sur `lastMessage.content`
- **Symptôme** : L'utilisateur cherche « Marie » → aucune conversation ne ressort, car la recherche locale ne filtre pas par `otherUserName`.
- **Recommandation** : `conv.otherUserName?.toLowerCase().contains(query)` en plus de `lastMessage.content`.

### 5.4 Pas de « draft » de message non envoyé
- **Symptôme** : L'utilisateur tape un message, quitte le chat sans envoyer → le texte est perdu.
- **Recommandation** : persister `_textController.text` par `conversationId` (`SharedPreferences` ou `flutter_secure_storage` si sensible) ; restaurer à l'ouverture.

### 5.5 Pas de « pull-to-refresh » visuellement « trop rapide »
- **Symptôme** : Le refresh réussit en <100ms → l'utilisateur voit à peine l'indicateur, a l'impression que rien ne s'est passé.
- **Recommandation** : `Future.wait([_load(), Future.delayed(Duration(milliseconds: 400))])` (minimum visible duration).

### 5.6 Pas d'indicateur « nouvelles conversations » en temps réel
- **Symptôme** : L'utilisateur est sur la liste, un nouveau match crée une conversation → pas de mise à jour temps réel (pas de WS sur la liste, `watchConversations` `UnimplementedError`). Il faut pull-to-refresh.
- **Recommandation** : WS notifications (`/ws/notifications/` déjà exposé par le backend) → abonner la liste aux `new_match` events → recharger.

### 5.7 Badge non-lu total non rafraîchi après lecture dans le chat
- **Symptôme** : L'utilisateur ouvre une conversation (mark-as-read) → revient à la liste → le badge total non-lu a encore l'ancienne valeur (sauf si la liste écoute l'événement).
- **Recommandation** : `ConversationsBloc.add(MarkConversationAsRead)` côté `ChatPage` avant de `pop`, ou écouter le retour.

### 5.8 Long-press « Voir profil » utilise `participantIds.first`
- **Code HIVMeet** : `conversations_page.dart` fallback sur `participantIds.first` au lieu de `conversation.otherUserId`.
- **Symptôme** : Si l'ordre des participantIds n'est pas stable, ouvre le mauvais profil.
- **Recommandation** : `conversation.otherUserId ?? conversation.participantIds.firstWhere((id) => id != currentUserId, orElse: ...)`.

### 5.9 Tri des conversations fragile
- **Symptôme** : `ConversationsBloc` ne re-trie pas explicitement après mark-as-read (qui modifie `updatedAt` ? non). Si 2 conversations ont le même `updatedAt` sub-ms, l'ordre peut flicker.
- **Recommandation** : tri stable par `updatedAt DESC, lastActivityAt DESC, id DESC` (fallback deterministic).

### 5.10 Avatar de conversation sans indication online
- **Symptôme** : `ConversationCard` a `isOnline` mais ne l'affiche pas (pas de point vert sur l'avatar).
- **Recommandation** : badge vert 10px en bas-droite de l'avatar quand `conversation.isOnline == true`.

### 5.11 Badge non-lu > 99 affiche « 100 » au lieu de « 99+ »
- **Symptôme** : Grand compteur casse le layout.
- **Recommandation** : `unreadCount > 99 ? '99+' : unreadCount.toString()`.

### 5.12 Aperçu dernier message : « Vous : » préfixe
- **Symptôme** : `_buildMessagePreview` ajoute `conversations.own_message_prefix` — vérifier que la clé i18n contient bien « Vous : » / « You: » avec espace final.

### 5.13 Pas de swipe-to-archive/delete
- **Symptôme** : Standard mobile : swipe gauche/droite pour archiver/supprimer. HIVMeet n'a que le long-press bottom sheet.
- **Recommandation** : `Dismissible` sur chaque card (endpoint backend archivage manquant → voir `BACKEND_MESSAGING_DELETE_CONVERSATION.md`).

---

## 6. Sécurité, vie privée & robustesse

### 6.1 `_buildClientMessageId` collision
- **Code HIVMeet** : `'client_' + DateTime.now().microsecondsSinceEpoch`. Deux envois dans la même microseconde → même ID → dédup collision (le 2e message est droppé).
- **Recommandation** : `uuid` package ou `'client_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1<<32)}'`.

### 6.2 `catch (e) → ServerFailure(message: e.toString())` leak
- **Symptôme** : Une exception brute (avec noms de classe, parfois PII si le backend echo des infos) remonte jusqu'à l'utilisateur via `ConversationsError(message:)` / SnackBar.
- **Recommandation** : messages génériques i18n (`common.error_unknown`) + log interne ; ne pas exposer `e.toString()`.

### 6.3 Pas de limite de longueur côté UI
- **Symptôme** : `SendTextMessage` ne valide que `trim().isEmpty`, pas `length > maxMessageLength` (1000). L'utilisateur peut taper 10 000 caractères → backend rejette (400) → message failed sans explication claire.
- **Recommandation** : `maxLength: AppConstants.maxMessageLength` sur le `TextField` + compteur discret (ex : 850/1000 en gris, rouge si dépasse).

### 6.4 Token JWT en query string WS
- **Symptôme** : `ws://...?token=<JWT>` → le token peut être loggé par proxies/CDN. Risque moyen.
- **Recommandation** : si possible, passer en header `Authorization` (le backend `ConversationConsumer` le supporte déjà en priorité). À condition que `WebSocket` de `dart:io` permette d'ajouter des headers (oui, via `headers:` param) ou `web_socket_channel` avec `WebSocketChannel.connect(uri, headers: ...)`.

### 6.5 Pas de sanitization XSS côté UI
- **Symptôme** : Si le backend WS `message.send` ne strip pas `<script>`, et que le frontend rend le contenu en HTML quelque part (ex : `Html` widget), risque XSS. En Flutter pur (`Text`), pas de rendu HTML → sûr, mais si on ajoute un rendu markdown/HTML riche, attention.
- **Recommandation** : toujours `Text` (pas `Html`) ; si markdown nécessaire, package `flutter_markdown` qui sanitize.

### 6.6 Media URL non expirée vérifiée
- **Symptôme** : `generateMediaUploadUrl` retourne `expiresInSeconds: 900`. Si l'utilisateur met >15 min à choisir un fichier (gallery browsing lent), l'URL expire avant le PUT → échec opaque.
- **Recommandation** : vérifier `DateTime.now().isBefore(generatedAt + expiresInSeconds)` avant le PUT ; si expiré, régénérer.

### 6.7 Media upload sans timeout / retry
- **Symptôme** : `_uploadMediaToSignedUrl` utilise un `Dio` brut sans `connectTimeout`/`receiveTimeout`. Upload GCS lent/instable → pend indéfiniment, l'utilisateur attend sans feedback.
- **Recommandation** : `BaseOptions(connectTimeout: 30s, receiveTimeout: 60s)` + indicateur de progression (stream `onSendProgress`) + bouton cancel.

### 6.8 Pas d'annulation de l'envoi média
- **Symptôme** : L'utilisateur démarre l'upload d'une vidéo 50MB, change d'avis → pas de bouton annuler, doit attendre.
- **Recommandation** : `CancelToken` Dio + bouton « × » sur la bulle `sending` (média).

### 6.9 Pas de preview du média avant envoi
- **Symptôme** : L'utilisateur sélectionne une photo → elle s'envoie immédiatement, pas de preview/crop/confirm.
- **Recommandation** : écran de confirmation avec preview + caption (texte accompagnant) + bouton Annuler/Envoyer.

### 6.10 Reactions crash si valeur non-string
- **Code HIVMeet** : `reactions: (json['reactions'] as Map<String,dynamic>?)?.map((k, v) => MapEntry(k, v as String))` → crash si `v` est `int` ou `null`.
- **Recommandation** : `v?.toString() ?? ''` ou try/catch ; si le backend n'envoie jamais de reactions (pas d'endpoint), supprimer le champ.

---

## 7. Performance & mémoire

### 7.1 `_typingController.repeat(reverse: true)` tourne en continu
- **Code HIVMeet** : `initState` → `_typingController.repeat(reverse: true)` dès l'ouverture, même si personne ne tape.
- **Impact** : 60 FPS de plus à soutenir pour rien, batterie.
- **Recommandation** : `_typingController.repeat(reverse: true)` uniquement quand `state.isTyping == true` (dans le `BlocBuilder` du statut), `stop()` sinon.

### 7.2 Pas de cache d'images message
- **Symptôme** : Chaque `Image.network` dans `MessageBubble` re-fetch l'image à chaque rebuild.
- **Recommandation** : `CachedNetworkImage` (déjà dépendance) partout.

### 7.3 ListView.builder sans `itemExtent` / pas de `cacheExtent`
- **Symptôme** : Longues conversations → scroll janky.
- **Recommandation** : `ListView.builder(cacheExtent: 1000)` (pré-render plus d'items) ; `itemExtent` impossible (bulles de hauteur variable).

### 7.4 Pas de pagination paresseuse des médias
- **Symptôme** : Si l'utilisateur scroll vite dans une conversation avec 50 images, toutes se chargent en RAM.
- **Recommandation** : `ListView.builder` paresseux déjà ; mais `Image.network` déclenche le fetch à la construction. Utiliser `precacheImage` avec parcimonie ou `cacheWidth`/`cacheHeight` pour downsampler.

### 7.5 `Equatable` props trop larges
- **Symptôme** : `Message.props` contient 20 champs dont `reactions` (Map) — chaque `==` compare toute la Map. Sur 1000 messages, coûteux.
- **Recommandation** : acceptable ; si profiling montre un coût, réduire les props à `[id, status, isRead, content, mediaUrl]` (champs qui changent réellement).

### 7.6 Rebuild du `BlocBuilder` trop large
- **Symptôme** : Tout `ChatPage` rebuild à chaque nouveau message (même la `AppBar`).
- **Recommandation** : `BlocBuilder<ChatBloc, ChatState>(buildWhen: (prev, curr) => prev.messages != curr.messages)` sur la liste ; `BlocBuilder` séparé sur l'AppBar avec `buildWhen` sur `isTyping/otherIsOnline`.

---

## 8. Accessibilité (a11y)

### 8.1 Bulles sans `Semantics`
- **Symptôme** : Screen reader (TalkBack/VoiceOver) lit le contenu mais pas le statut (envoyé/lu), l'expéditeur, l'heure.
- **Recommandation** : `Semantics(label: 'Message de ${senderName} à ${time}, ${status}', button: true)` sur chaque bulle.

### 8.2 Indicateur « typing » non annoncé
- **Symptôme** : « typing… » visuel mais pas annoncé au screen reader.
- **Recommandation** : `Semantics(liveRegion: true, label: '...')` sur le statut.

### 8.3 Bouton envoi sans `tooltip`
- **Symptôme** : TalkBack lit « bouton » sans contexte.
- **Recommandation** : `Tooltip(message: 'Envoyer')` ou `Semantics(label: 'Envoyer')`.

### 8.4 Contraste des timestamps
- **Symptôme** : `AppColors.slate` sur fond blanc — vérifier le ratio WCAG AA (4.5:1). Souvent insuffisant pour les `bodySmall`.
- **Recommandation** : audit contraste, assombrir si nécessaire.

### 8.5 Taille de tap cible < 48px
- **Symptôme** : Bouton emoji / bouton média parfois <48px → échec WCAG, tap difficile.
- **Recommandation** : `SizedBox(width: 48, height: 48)` minimum sur tous les boutons actionnables.

### 8.6 Pas de `ExcludeSemantics` sur les éléments décoratifs
- **Symptôme** : Le screen reader annonce les séparateurs de date, les animations.
- **Recommandation** : `ExcludeSemantics` sur les dividers purement visuels.

---

## 9. Edge cases de données

### 9.1 Message vide autorisé visuellement
- **Symptôme** : `SendTextMessage` valide `trim().isEmpty`, mais `SendMediaMessage` envoie `content: ''` → une bulle média sans caption est OK, mais une bulle texte optimiste avec `content: ''` (cas media) apparaît vide une fraction de seconde.
- **Recommandation** : ne pas afficher de bulle texte si `content.isEmpty && type == text`.

### 9.2 Heure du message à `DateTime.fromMillisecondsSinceEpoch(0)` si `created_at` absent
- **Code HIVMeet** : `Message.fromJson` fallback `DateTime.fromMillisecondsSinceEpoch(0)` (1970-01-01) → affiche « 00:00 » ou une date 1970.
- **Recommandation** : fallback `DateTime.now()` pour les messages entrants ; ou `null` + bulle sans timestamp.

### 9.3 Conversation sans `other_user`
- **Symptôme** : Si le backend renvoie une conversation sans `other_user` (edge case), `otherUserName` null → fallback `chat.default_user` « Utilisateur » — acceptable mais pas d'avatar.
- **Recommandation** : placeholder avatar (initiales ou icône) déjà géré ? vérifier `_buildProfilePhoto`.

### 9.4 Date `lastActive` dans le futur
- **Symptôme** : Décalage d'horloge serveur/client → `lastActive` dans le futur → `_formatLastSeen` affiche « à l'instant » pour toujours.
- **Recommandation** : `if (lastActive.isAfter(DateTime.now())) return 'chat.online';` (fallback).

### 9.5 ID conversation avec caractères spéciaux dans URL
- **Symptôme** : `context.push('/chat/${conversation.id}')` sans `Uri.encodeComponent` — si l'ID contient `/` (UUID n'en contient pas, mais par défense) → casse la route.
- **Recommandation** : `Uri.encodeComponent(conversation.id)`.

### 9.6 Caractères RTL (arabe, hébreu)
- **Symptôme** : Un message en arabe s'affiche LTR au lieu de RTL — `Text` gère automatiquement la direction Unicode, mais l'alignement de la bulle reste lié à `isOwnMessage`.
- **Recommandation** : acceptable ; si support RTL complet prévu, `Directionality` widget.

### 9.7 Emoji multi-caractères (ZWIJ, skin tones)
- **Symptôme** : Emoji picker insère un emoji composé (ex : 👨‍👩‍👧‍👦 = 7 codepoints) → le `TextField` peut compter/limiter par codepoints au lieu de graphemes → troncature au milieu d'un emoji.
- **Recommandation** : si `maxLength` appliqué, utiliser `Characters` au lieu de `String.length` pour les limites.

---

## 10. Internationalisation (i18n) & localisation

### 10.1 Heure 24h hardcoded
- Voir 3.12.

### 10.2 Pluriels non gérés
- **Symptôme** : `conversations.days_ago_short` (ex : « 5 j ») — mais `Intl.plural` permet « 1 jour / 5 jours » propre. Vérifier que les clés `*_one` / `*_other` existent.
- **Recommandation** : audit des clés `days_ago`, `minutes_ago`, `hours_ago` pour les règles de pluriel FR/EN.

### 10.3 Format date/heure non sensible à la locale
- **Symptôme** : `DateFormat('HH:mm')` sans `locale` → toujours 24h même en EN.
- **Recommandation** : `DateFormat.jm(LocalizationService.locale.toString())`.

### 10.4 ~15 chaînes FR hardcoded
- Voir `AUDIT_MESSAGES_PAGE.md` §5.2 (`empty_conversations_view`, `conversations_search_bar`, tooltip cloche, doublon `widgets/cards/conversation_card.dart`).

### 10.5 Pas de fallback i18n explicite
- **Symptôme** : Si une clé manque dans `fr.json`, `LocalizationService.translate` retourne la clé elle-même (ex : `chat.foo`) au lieu du texte EN ou d'un placeholder.
- **Recommandation** : fallback chaîne EN, puis `[missing: key]` en debug.

### 10.6 Tri alphabétique des conversations dépend de la locale
- **Symptôme** : Si tri alphabétique ajouté un jour, « é » doit trier avec « e » en FR.
- **Recommandation** : `String.compareTo` insensible à la locale ; utiliser `Intl.toString()` ou un collator.

---

## 11. États vides & transitions

### 11.1 État vide « It's a match! » affiché même sans match réel
- **Symptôme** : Si une conversation existe mais que tous les messages sont supprimés, `_buildEmptyState` affiche « It's a match! » — trompeur.
- **Recommandation** : distinguer « conversation vide après suppression » (texte neutre « Début de la conversation ») vs « nouveau match » (quick messages).

### 11.2 Pas de skeleton loader
- **Symptôme** : `ConversationsLoadingView` affiche probablement un spinner simple. Standard attendu : shimmer skeletons imitant les cards.
- **Recommandation** : `Shimmer` package + skeleton `ConversationCard` placeholder.

### 11.3 Error state sans distinction cause (réseau vs serveur)
- **Symptôme** : `ConversationsErrorView` affiche `message` brute, ne distingue pas « pas de connexion » (retry utile) vs « serveur down » (réessayer plus tard).
- **Recommandation** : mapper `Failure` type → message + action adaptée (`NetworkFailure` → « Vérifiez votre connexion » + Retry ; `ServerFailure` → « Serveur indisponible » + Réessayer plus tard).

### 11.4 Pas de transition animée entre empty / loaded
- **Symptôme** : L'état passe de loading à loaded sans transition → le contenu « saute ».
- **Recommandation** : `AnimatedSwitcher` entre les états.

---

## 12. Cycle de vie & navigation

### 12.1 `DisconnectFromWebSocket` jamais émis
- **Code HIVMeet** : `ChatPage.dispose` appelle `_chatBloc.close()` (qui ferme le WS via `ChatBloc.close`), mais n'émet jamais `DisconnectFromWebSocket`. Fonctionnellement OK, mais le flux n'est pas explicite.
- **Recommandation** : `_chatBloc.add(DisconnectFromWebSocket())` avant `_chatBloc.close()` pour une fermeture propre.

### 12.2 `ChatBloc` fermé manuellement au lieu de `BlocProvider`
- **Symptôme** : Si un parent écoute le bloc, le close prématuré peut causer « BlocProvider.of() called with a bloc that is closed ».
- **Recommandation** : fournir via `BlocProvider(create: (_) => getIt<ChatBloc>(), child: ChatPage(...))` ; le provider gère `close`.

### 12.3 Pas de `PopScope` / `WillPopScope` pour confirmer la sortie
- **Symptôme** : L'utilisateur recule pendant l'upload d'un média → l'upload est annulé, message marqué `failed` sans confirmation.
- **Recommandation** : `PopScope(canPop: !_isUploading, onPopInvoked: ...)` → dialog « Envoi en cours, quitter ? ».

### 12.4 Navigation « back » depuis le chat ne remet pas le badge
- **Symptôme** : Voir 5.7.
- **Recommandation** : `ChatPage` emet `MarkConversationAsRead` côté `ConversationsBloc` avant `pop`.

### 12.5 Rotation d'écran non gérée
- **Symptôme** : Rotation → le `_scrollController` perd la position, la liste revient en haut.
- **Recommandation** : `PageStorageKey(conversationId)` sur la `ListView`.

---

## 13. Divers

### 13.1 Pas de son/vibration à la réception
- **Symptôme** : Standard : léger feedback haptique + son (si activé) à la réception d'un message quand le chat est ouvert.
- **Recommandation** : `HapticFeedback.lightImpact()` sur `_onWsMessageReceived` (si `!isMine`).

### 13.2 Pas de « dernière connexion » affinée
- **Symptôme** : `_formatLastSeen` : `just_now / minutes_ago / hours_ago / days_ago`. Manque « hier », « la semaine dernière », « le 12 juillet ».
- **Recommandation** : enrichir les paliers.

### 13.3 Pas de partage de message vers une autre conversation
- **Symptôme** : Standard在一些 apps.
- **Recommandation** : optionnel (nécessite backend).

### 13.4 Pas de recherche dans la conversation courante
- **Symptôme** : Impossible de chercher un mot dans l'historique de la conversation.
- **Recommandation** : optionnel (nécessite backend `GET /messages?search=`).

### 13.5 Pas d'épinglage de message
- **Symptôme** : Optionnel.
- **Recommandation** : optionnel (backend).

### 13.6 Pas de mode sombre testé
- **Symptôme** : `AppColors.primaryWhite`/`platinum`/`charcoal` — vérifier que les bulles restent lisibles en dark mode.
- **Recommandation** : test `ThemeMode.dark`.

### 13.7 Pas de gestion des gros textes (accessibilité système)
- **Symptôme** : Si l'utilisateur a agrandi la police système (1.5×), les bulles débordent ou le texte est coupé.
- **Recommandation** : `MediaQuery.textScalerOf(context)` ; éviter `maxLines: 1` fixe.

### 13.8 Pas de sauvegarde/restauration de l'état draft
- Voir 5.4.

### 13.9 Pas de « mute » conversation
- **Symptôme** : Standard : mute notifications d'une conversation spécifique bruyante.
- **Recommandation** : backend `PATCH /conversations/{id}/` avec `muted: true` (à demander dans `BACKEND_*.md`).

### 13.10 Pas de compteur de messages non lus persistant entre sessions
- **Symptôme** : Le badge total non-lu se recalcule au chargement — OK, mais si l'utilisateur met l'app en arrière-plan puis revient, peut flicker.
- **Recommandation** : acceptable.

---

## 14. Synthèse — Priorisation recommandée

| Priorité | Items | Effort | Impact perçu |
|---|---|---|---|
| 🔴 Haute (UX critique) | 3.1 (statut sending/failed), 4.1 (reconnexion WS), 5.1 (mark-read perd champs), 6.1 (collision clientMessageId), 6.3 (limite longueur UI) | Faible | Évite bugs visibles |
| 🟡 Moyenne (qualité perçue) | 1.1, 1.2 (auto-scroll), 2.1 (debounce typing), 3.6/3.7/3.8 (médias), 3.9 (liens), 4.2 (heartbeat), 5.3 (recherche nom), 5.4 (draft), 6.7/6.8 (upload progress/cancel), 6.9 (preview média), 7.1 (typing controller) | Moyen | Finition notable |
| 🟢 Basse (polish) | 1.3-1.5, 2.3-2.8, 3.2-3.5, 3.10-3.12, 4.3-4.6, 5.5-5.13, 6.4-6.6, 6.10, 7.2-7.6, 8.x (a11y), 9.x, 10.x, 11.x, 12.x, 13.x | Variable | Polish & robustesse long-terme |

---

## 15. Comment utiliser cette liste

1. Choisir un item par item — chaque correction est indépendante et faible risque.
2. Pour chaque item : valider le symptôme sur émulateur/device, appliquer le fix, vérifier `flutter analyze` + tests impactés.
3. Items nécessitant backend (4.7 read receipt WS, 5.6 new conversation WS, 5.13 archivage, 13.9 mute) → produire `BACKEND_*.md` au lieu de modifier le frontend.
4. Après un groupe d'items, relancer la matrice de tests messagerie (`flutter test test/domain/usecases/chat/ test/presentation/blocs/chat/ ...`) pour non-regression.

---

**Note** : cette liste n'est pas exhaustive mais couvre les finitions les plus fréquemment oubliées dans les modules de chat mobiles. Elle complète `AUDIT_MESSAGES_PAGE.md` (qui couvre les fonctionnalités majeures) en se concentrant sur le « ressenti » et la robustesse de détail.