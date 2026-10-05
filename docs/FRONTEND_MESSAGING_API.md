# 💬 API Messaging - Documentation Frontend

## 📋 Vue d'Ensemble

Le module Messaging gère la messagerie temps réel entre utilisateurs matchés, incluant les messages texte, multimédias, les appels audio/vidéo, et les indicateurs de statut.

## 🏗️ Architecture de la Messagerie

### Principe de Fonctionnement
**Logique Métier :**
- Messagerie uniquement entre utilisateurs matchés
- Messages temps réel via WebSocket ou polling
- Support multimédia pour les utilisateurs premium
- Appels audio/vidéo avec WebRTC
- Indicateurs de statut (en ligne, en train d'écrire, lu)

### Types de Messages
1. **Texte** : Messages standard
2. **Image** : Photos (premium)
3. **Vidéo** : Vidéos courtes (premium)
4. **Audio** : Messages vocaux (premium)
5. **Call Log** : Historique des appels

## 💬 Endpoints de Messagerie

### 1. Liste des Conversations

**Endpoint :** `GET /conversations/`

**Paramètres de Requête :**
```
page: 1
per_page: 20
filter: "all|unread|archived"
```

**Réponse Succès (200) :**
```json
{
  "conversations": [
    {
      "id": "uuid",
      "match_id": "uuid",
      "participant": {
        "id": "uuid",
        "display_name": "Emma",
        "age": 26,
        "photo_url": "https://...",
        "is_online": true,
        "last_active": "2024-01-20T15:30:00Z"
      },
      "last_message": {
        "id": "uuid",
        "content": "Salut ! Comment ça va ?",
        "message_type": "text",
        "sender_id": "uuid",
        "sent_at": "2024-01-20T15:45:00Z",
        "status": "read"
      },
      "unread_count": 2,
      "created_at": "2024-01-20T14:30:00Z",
      "is_archived": false
    }
  ],
  "pagination": { /* ... */ }
}
```

**Logique d'Implémentation Frontend :**
- Tri par dernière activité (message ou appel)
- Badge de notification pour messages non lus
- Indicateur de présence en ligne
- Pull-to-refresh pour actualiser
- Lazy loading avec pagination

### 2. Messages d'une Conversation

**Endpoint :** `GET /conversations/{conversation_id}/messages`

**Paramètres de Requête :**
```
page: 1
per_page: 50
before_message_id: uuid (optionnel, pour pagination inverse)
```

**Réponse Succès (200) :**
```json
{
  "messages": [
    {
      "id": "uuid",
      "client_message_id": "client_123",
      "content": "Salut ! Comment ça va aujourd'hui ?",
      "message_type": "text",
      "sender_id": "uuid",
      "sender_name": "Emma",
      "sent_at": "2024-01-20T15:45:00Z",
      "status": "read",
      "read_at": "2024-01-20T15:47:00Z",
      "media_url": null,
      "media_thumbnail_url": null,
      "is_deleted": false
    },
    {
      "id": "uuid",
      "content": "",
      "message_type": "image",
      "sender_id": "uuid",
      "media_url": "/api/v1/conversations/{conversation_id}/messages/{message_id}/media/",
      "media_download_url": "/api/v1/conversations/{conversation_id}/messages/{message_id}/media/",
      "media_thumbnail_url": null,
      "sent_at": "2024-01-20T16:00:00Z",
      "status": "delivered"
    }
  ],
  "pagination": { /* ... */ }
}
```

**Logique d'Implémentation Frontend :**
- Pagination inverse (messages récents en bas)
- Groupement des messages par date
- Affichage des statuts (envoyé, livré, lu)
- Chargement automatique des anciens messages au scroll
- Gestion des médias uniquement via le transport HTTP authentifié ; ne jamais
  consommer une URL de bucket, une URL signée ou un chemin `/media/...`.

### 3. Envoi de Message Texte

**Endpoint :** `POST /conversations/{conversation_id}/messages/media/`

**Données Requises :**
```json
{
  "content": "Contenu du message",
  "message_type": "text",
  "client_message_id": "unique_client_id"
}
```

**Principe d'Implémentation :**
1. Générer un ID client unique pour éviter les doublons
2. Affichage optimiste immédiat dans l'interface
3. Envoi asynchrone au backend
4. Mise à jour du statut selon la réponse
5. Retry automatique en cas d'échec réseau

**Réponse Succès (201) :**
```json
{
  "message": {
    "id": "uuid",
    "client_message_id": "unique_client_id",
    "content": "Contenu du message",
    "status": "sent",
    "sent_at": "2024-01-20T16:15:00Z"
  }
}
```

**Logique d'Implémentation Frontend :**
- Interface optimiste : affichage immédiat
- États visuels : envoi, envoyé, livré, lu, échec
- Retry automatique avec backoff exponentiel
- Déduplication via client_message_id
- Limitation de caractères (1000 max)

### 4. Envoi de Média (Premium)

**Endpoint :** `POST /conversations/{conversation_id}/messages`

**Format :** `multipart/form-data`

**Sécurité de lecture :** `media_url` et `media_download_url` désignent la
même route API authentifiée. Un compte sans KYC actif reçoit `403
kyc_required`; un non-participant, un message supprimé ou un fichier absent
reste un `404` sans détail. Le client ne doit jamais utiliser de bucket, URL
signée ou chemin `/media/...`.

**Données Requises :**
```
media_file: File (image/video/audio)
message_type: "image|video|audio"
client_message_id: "unique_client_id"
```

**Principe d'Implémentation :**
1. Vérifier l'abonnement premium
2. Validation du fichier (format, taille, durée)
3. Compression/optimisation automatique
4. Upload progressif avec indicateur
5. Génération de thumbnail automatique

**Réponse Succès (201) :**
```json
{
  "message": {
    "id": "uuid",
    "message_type": "image",
    "media_url": "/api/v1/conversations/{conversation_id}/messages/{message_id}/media/",
    "media_download_url": "/api/v1/conversations/{conversation_id}/messages/{message_id}/media/",
    "media_thumbnail_url": null,
    "status": "sent"
  }
}
```

**Logique d'Implémentation Frontend :**
- Progress bar pendant l'upload
- Prévisualisation avant envoi
- Compression automatique selon la qualité de connexion
- Retry en cas d'échec d'upload
- Stockage temporaire local privé uniquement, à purger lors de perte de KYC,
  déconnexion ou suppression du message ; aucun cache HTTP partagé.

### 5. Marquer comme Lu

**Endpoint :** `PUT /conversations/{conversation_id}/messages/{message_id}/read`

**Principe d'Implémentation :**
- Appel automatique quand le message devient visible
- Marquer tous les messages précédents comme lus
- Notification temps réel à l'expéditeur
- Mise à jour du compteur de non-lus

**Réponse Succès (200) :**
```json
{
  "message": "Message marked as read",
  "read_at": "2024-01-20T16:20:00Z"
}
```

**Logique d'Implémentation Frontend :**
- Détection automatique de la visibilité du message
- Batch des appels pour optimiser les performances
- Mise à jour temps réel des statuts de lecture
- Gestion du scroll et de la visibilité

## 📞 Système d'Appels Audio/Vidéo

### 6. Initiation d'Appel

**Endpoint :** `POST /calls/`

**Données Requises :**
```json
{
  "callee_id": "uuid",
  "call_type": "audio|video",
  "offer_sdp": "webrtc_offer_sdp"
}
```

**Principe d'Implémentation WebRTC :**
1. Créer l'offre WebRTC côté appelant
2. Envoyer l'offre au backend
3. Notification push à l'appelé
4. Gestion des candidats ICE
5. Établissement de la connexion P2P

**Réponse Succès (201) :**
```json
{
  "call": {
    "id": "uuid",
    "call_type": "video",
    "status": "initiated",
    "initiated_at": "2024-01-20T16:25:00Z"
  }
}
```

**Logique d'Implémentation Frontend :**
- Interface d'appel en overlay
- Gestion des permissions (micro/caméra)
- Configuration WebRTC automatique
- Fallback gracieux en cas d'échec
- Limitation de durée selon le plan

### 7. Répondre à un Appel

**Endpoint :** `PUT /calls/{call_id}/answer`

**Données Requises :**
```json
{
  "answer_sdp": "webrtc_answer_sdp"
}
```

**Logique d'Implémentation Frontend :**
- Interface de réception d'appel
- Options accepter/refuser avec swipe
- Configuration audio/vidéo automatique
- Gestion des interruptions (appels téléphone)

### 8. Terminer un Appel

**Endpoint :** `PUT /calls/{call_id}/end`

**Données Requises :**
```json
{
  "end_reason": "normal|declined|failed|timeout"
}
```

**Logique d'Implémentation Frontend :**
- Fermeture propre de la connexion WebRTC
- Enregistrement automatique dans l'historique
- Statistiques de qualité d'appel
- Retour à l'interface de chat

## 💭 Indicateurs de Statut

### 9. Indicateur de Frappe

**Endpoint :** `POST /conversations/{conversation_id}/typing`

**Données Requises :**
```json
{
  "is_typing": true
}
```

**Principe d'Implémentation :**
- Envoi automatique quand l'utilisateur tape
- Timeout automatique après 3 secondes sans activité
- Affichage temps réel chez l'autre utilisateur
- Optimisation pour éviter le spam

**Logique d'Implémentation Frontend :**
- Détection du début/fin de frappe
- Debouncing pour éviter les appels excessifs
- Affichage "... est en train d'écrire"
- Masquage automatique après timeout

### 10. Statut de présence

**Endpoint :** `GET /api/v1/conversations/{conversation_id}/presence/`

La réponse REST et l’événement `presence.update` utilisent les champs
`visibility`, `is_online`, `last_active` et `server_timestamp`. Chaque client
au premier plan envoie `presence.heartbeat` toutes les 30 secondes ; le serveur
expire une session silencieuse après 90 secondes.

Si `visibility` vaut `false`, l’interface efface le sous-titre de
l’interlocuteur. Elle ne réutilise jamais une ancienne heure, un statut de
lecture ou une présence calculée localement.
## 🔔 Notifications et Temps Réel

### WebSocket ou Polling
**Choix d'Implémentation :**
- **WebSocket** pour les utilisateurs premium (temps réel)
- **Polling** pour les utilisateurs gratuits (30 secondes)
- Fallback automatique selon la connectivité
- Reconnexion automatique en cas de déconnexion

### Types de Notifications Push
1. **Nouveau message** : Avec preview (si non premium)
2. **Appel entrant** : Avec actions directes
3. **Message lu** : Notification silencieuse
4. **Match** : Première interaction possible

## 🛡️ Modération et Sécurité

### Filtres de Contenu
**Principe d'Implémentation :**
- Détection automatique de contenu inapproprié
- Modération des images par IA
- Système de signalement intégré
- Blocage temporaire en cas d'abus

### Chiffrement des Communications
- Chiffrement TLS pour tous les transports
- Chiffrement optionnel end-to-end (premium)
- Pas de stockage des clés côté serveur
- Option de messages éphémères

## 📊 Limitations et Premium

### Utilisateurs Gratuits
- **Messages texte** : Illimités
- **Médias** : Non disponibles
- **Appels** : Non disponibles
- **Messages vocaux** : Non disponibles
- **Qualité photos** : Compressées

### Utilisateurs Premium
- **Messages texte** : Illimités
- **Médias** : Photos/vidéos HD
- **Appels** : Audio/vidéo illimités
- **Messages vocaux** : Durée étendue
- **Fonctionnalités avancées** : Rappel, notes privées

## 🚨 Gestion d'Erreurs Spécifiques

### Erreurs de Réseau
- **Message non envoyé** : Retry automatique avec indicateur
- **Connexion perdue** : Mode hors ligne avec queue
- **Upload échec** : Retry avec compression additionnelle

### Erreurs d'Appel
- **Permissions refusées** : Guide d'activation
- **WebRTC échec** : Fallback vers messages
- **Qualité dégradée** : Suggestions d'amélioration

### Erreurs Premium
- **Média bloqué** : Redirection vers upgrade
- **Appel non autorisé** : Explication des bénéfices premium
- **Limite atteinte** : Compteur et reset

## 📱 Optimisations Mobile

### Performance
- Cache intelligent des conversations récentes
- Compression adaptative selon la bande passante
- Lazy loading des médias anciens
- Background sync des messages

### UX Mobile
- Interface de chat adaptée au clavier
- Gestes intuitifs (swipe pour répondre)
- Haptic feedback sur les interactions
- Picture-in-picture pour les appels vidéo

Cette documentation couvre tous les aspects de la messagerie nécessaires pour une intégration frontend complète avec le backend HIVMeet.
