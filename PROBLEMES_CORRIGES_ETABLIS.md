# Problèmes Identifiés et Solutions - HIVMeet

**Date**: 25 Mars 2026  
**Version APK**: Doit être reconstruite

---

## 📋 Problèmes et Statuts

### 1. Texte "likes" au lieu de "swipes"

**Statut**: ✅ CORRIGÉ dans le code source (FRONTEND)

**Fichiers modifiés**:
- `assets/translations/fr.json`: `"swipes_remaining": "{count} swipes restants"`
- `assets/translations/en.json`: `"swipes_remaining": "{count} swipes remaining"`
- `lib/presentation/pages/discovery/discovery_page.dart`: Clé mise à jour

**Action requise**: Reconstruire l'APK
```bash
flutter clean
flutter pub get
flutter run
```

---

### 2. Compteur pas affiché au lancement

**Cause probable**: Le backend ne retourne pas `daily_likes_remaining` dans la réponse `GET /discovery/profiles/`

**Solution backend requise**: Modifier `discovery/views_discovery.py` pour inclure les infos de limite dans la réponse.

**Voir**: `BACKEND_CORRECTION_SWIPES_COUNTER.md`

---

### 3. 12 swipes au lieu de 10 (off-by-one error)

**Cause**: Le backend vérifie la limite APRÈS le decrement, pas AVANT.

**Solution backend requise**: Vérifier la limite avant d'autoriser le swipe.

**Voir**: `BACKEND_CORRECTION_SWIPES_COUNTER.md`

---

### 4. Profils qui reviennent plusieurs fois

**Cause**: Le système de filtrage ne fonctionne pas correctement.

**Solution backend requise**: Améliorer la logique de filtrage des profils déjà likés/dislikés.

**Voir**: `BACKEND_CORRECTION_INTERACTIONS_DUPLICATES.md`

---

### 5. Historique qui ne tient pas compte des swipes

**Cause probable**: 
1. Données statiques dans le mock repository
2. Endpoint qui ne retourne pas les vraies données

**Actions requises**:
1. Vérifier que `interaction_history_repository_impl.dart` utilise les vraies données
2. Nettoyer les données mockées

---

## 🔧 Actions Immédiates (Frontend)

### Reconstruire l'APK

```bash
cd d:\Projets\HIVMeet\hivmeet
flutter clean
flutter pub get
flutter build apk --debug
```

### Vérifier le service de localisation

S'assurer que `LocalizationService` charge bien les fichiers depuis `assets/translations/`.

---

## 📁 Fichiers de Documentation Créés

| Fichier | Contenu |
|---------|---------|
| `BACKEND_CORRECTION_SWIPES_COUNTER.md` | Solution pour le compteur de likes |
| `BACKEND_CORRECTION_INTERACTIONS_DUPLICATES.md` | Solution pour les profils qui reviennent |
| `BACKEND_CORRECTION_HISTORY.md` | Solution pour l'historique inexact |

---

## 📝 Notes Importantes

1. **Utilisateur premium**: D'après les logs, l'utilisateur actuel (Marie) est **premium**. Les utilisateurs premium n'ont pas de limite de likes, donc le compteur ne devrait PAS s'afficher pour eux.

2. **Compteur pour utilisateurs gratuits**: Le compteur ne devrait s'afficher que pour les utilisateurs NON premium avec `daily_likes_limit != null`.

3. **Réinitialisation**: Après chaque modification du backend, redémarrer le serveur Django.

---

## ✅ Checklist de Validation

Après avoir implémenté les corrections :

- [ ] APK reconstruite avec `flutter clean && flutter pub get`
- [ ] Texte "swipes restants" affiché correctement
- [ ] Compteur affiché dès le chargement (utilisateurs gratuits)
- [ ] Limite de 10 swipes respectée (pas 12)
- [ ] Profils non-dupliqués dans la découverte
- [ ] Historique reflète les vrais swipes effectués

---

**Prochaines étapes**: Implémenter les corrections backend documentées dans les fichiers `.md` du projet.
