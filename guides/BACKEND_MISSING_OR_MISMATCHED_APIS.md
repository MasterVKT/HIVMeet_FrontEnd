# Backend: APIs manquantes ou divergences constatées (Frontend aligné)

Date: 2025-09-23

## Contexte
Suite à l’alignement du frontend avec `FRONTEND_BACKEND_ALIGNMENT_NOTES.md`, nous avons ajusté endpoints, headers et parsing des réponses. Voici les points backend à vérifier/corriger pour garantir l’intégration sans erreurs.

## 1) Authentification
- Échange Firebase → Django JWT
  - Frontend appelle désormais `POST /api/v1/auth/firebase-exchange/` avec `{ id_token, firebase_token }`.
  - Attendu en réponse: `{ access_token, refresh_token, user }` avec alias acceptés `{ token|access, refresh }`.

- Refresh token
  - Frontend appelle `POST /api/v1/auth/refresh-token/` avec `{ refresh_token }`.
  - Réponse attendue: `{ access_token, refresh_token }` + alias `{ token|access, refresh }`.

## 2) Discovery / Matching
- Liste des profils: `GET /api/v1/discovery/profiles` (alias `/api/v1/discovery/` accepté).
  - Pagination attendue: `{ count, next, previous, results: [...] }`.
- Interactions: like/dislike/superlike/rewind/liked-me sous `POST/GET /api/v1/discovery/interactions/...`.
- Boost: `POST /api/v1/discovery/boost/activate`.
- Likes reçus: `GET /api/v1/user-profiles/likes-received/` (premium).
- Profil/me (filtres): `GET|PUT /api/v1/user-profiles/me/`.

## 3) Messagerie
- Conversations: `GET /api/v1/conversations/` avec pagination `{ count, next, previous, results }`.
- Messages: `GET /api/v1/conversations/{id}/messages/` avec `page`/`page_size`.
- Envoi texte: `POST /api/v1/conversations/{id}/messages/`.
- Média (premium): `POST /api/v1/conversations/{id}/messages/media/`.
- Marquer lus: `PUT /api/v1/conversations/{id}/messages/mark-as-read/`.
- Suppression: `DELETE /api/v1/conversations/{id}/messages/{message_id}/`.
- Appels: `POST /api/v1/calls/initiate|{id}/answer|{id}/ice-candidate|{id}/terminate`.
- Appel premium: `POST /api/v1/conversations/calls/initiate-premium/`.

Note: Le frontend tolère aussi des clés alternatives (`data`) mais attend prioritairement `results`.

## 4) Ressources / Feed
- Catégories: `GET /api/v1/content/resource-categories` → réponse idéalement `{ results: [...] }` (le frontend tolère `categories`).
- Ressources: `GET /api/v1/content/resources`.
- Détail ressource: `GET /api/v1/content/resources/{id}`.
- Favoris: `POST /api/v1/content/resources/{id}/favorite`, Liste: `GET /api/v1/content/favorites`.
- Feed posts: `GET|POST /api/v1/feed/posts`, Likes: `POST /api/v1/feed/posts/{id}/like`, Commentaires: `GET|POST /api/v1/feed/posts/{id}/comments`.
- Pagination: `{ count, next, previous, results }`.

## 5) Abonnements
- Plans: `GET /api/v1/subscriptions/plans/` (réponse: `{ results|plans: [...] }`).
- Abonnement courant: `GET /api/v1/subscriptions/current/` (réponse: `{ subscription: {...} }`).
- Achat: `POST /api/v1/subscriptions/purchase/`.
- Annulation: `POST /api/v1/subscriptions/current/cancel/`.
- Réactivation: `POST /api/v1/subscriptions/current/reactivate/`.

## 6) Internationalisation
- `Accept-Language` supporté (`fr|en`). Le frontend l’envoie systématiquement.

## 7) Points d’attention / divergences potentielles
- Health check: Frontend appelle `/health/simple/` (OK) et peut ping `/fr/admin/login/` pour accessibilité (OK si 200/302).
- Endpoint `/api/v1/discovery/` sans auth renvoie 401 (attendu). Une fois authentifié, la réponse doit suivre la pagination standard.
- Certaines anciennes clés `{ data, profiles, matches, categories, resources }` sont encore tolérées par le frontend, mais il est recommandé d’harmoniser vers `{ results }`.

## 8) Logs d’erreurs récents (backend)
- 401 NotAuthenticated sur `GET /api/v1/discovery/` puis 401 sur `POST /api/v1/auth/login`. Cela suggère:
  - Soit des identifiants invalides au login,
  - Soit un chemin différent attendu par le backend pour le login. Le frontend utilise désormais `POST /api/v1/auth/login`.

## 9) Actions backend proposées si divergences constatées
- Vérifier que tous les endpoints ci-dessus existent et respectent la pagination `{ count, next, previous, results }`.
- S’assurer que l’alias `/api/v1/discovery/` renvoie le même payload que `/api/v1/discovery/profiles`.
- Confirmer la présence des alias de clés pour tokens (`access_token`/`refresh_token` et alias `token|access`, `refresh`).
- Harmoniser les réponses catégories/ressources vers `{ results }` à terme.

---
Si une divergence est observée, merci de répondre avec l’exemple de requête et la réponse complète (status + body) pour ajustement.

