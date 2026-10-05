# Test de connectivité - Appareil physique

**Objectif** : Valider que l'appareil physique peut atteindre le backend

---

## ✅ Configuration appliquée

- **IP du backend** : `10.241.252.68:8000`
- **Fichier modifié** : `lib/core/config/app_config.dart`
- **Date** : 2026-07-26

---

## 🧪 Procédure de test

### 1. Redémarrer l'application sur l'appareil physique

```powershell
# Nettoyer et rebuild
flutter clean
flutter pub get

# Lancer avec l'IP explicite (optionnel, déjà dans app_config.dart)
flutter run --dart-define=API_URL=http://10.241.252.68:8000
```

### 2. Observer les logs de connexion

Recherchez ces lignes dans les logs :

**✅ SUCCÈS** :
```
🐞 DEBUG: _handleLogin DÉMARRÉ avec AuthBlocSimple
✅ DEBUG: Validation formulaire OK
Tentative de connexion pour: max.weber@test.com
✅ [BLOC] Connexion réussie
```

**❌ ÉCHEC** (ancien message) :
```
🚨 [BLOC] Connexion échouée: Erreur de connexion: Erreur réseau: null
```

### 3. Tester la connectivité réseau

Si l'échec persiste, testez depuis l'appareil :

**Depuis ADB shell** (si appareil Android connecté) :
```bash
adb shell ping 10.241.252.68
adb shell curl http://10.241.252.68:8000/api/v1/auth/login
```

**Depuis l'application** :
Ajoutez un log dans `auth_api.dart` avant l'appel :
```dart
print('🔍 TEST: Backend URL = http://10.241.252.68:8000');
```

---

## 🔍 Diagnostic si échec persistant

### Check-list réseau

1. **Même réseau WiFi** :
   - [ ] Machine et appareil sur le même réseau
   - [ ] Pas de réseau "invité" avec isolation

2. **Firewall Windows** :
   - [ ] Port 8000 ouvert en entrée
   - [ ] Règle appliquée au profil "Privé"

3. **IP correcte** :
   - [ ] Vérifier avec `ipconfig` (peut changer si vous changez de réseau)
   - [ ] IP commence par `10.241.x.x` ou `192.168.x.x`

4. **Backend accessible** :
   - [ ] `netstat -ano | findstr :8000` montre LISTENING
   - [ ] Backend répond aux requêtes

---

## 🛠️ Solutions rapides

### Problème : IP a changé

```powershell
# 1. Trouver la nouvelle IP
ipconfig | findstr /C:"Adresse IPv4"

# 2. Mettre à jour app_config.dart
# Ligne ~87: return 'http://NOUVELLE_IP:8000';

# 3. Redémarrer l'app
flutter run
```

### Problème : Firewall bloque

```powershell
# Ouvrir le port 8000 (PowerShell Admin)
New-NetFirewallRule -DisplayName "Flutter Backend 8000" -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow
```

### Problème : Backend non démarré

```powershell
# Démarrer le backend (adaptez selon votre setup)
cd ../hivmeet-backend
python manage.py runserver 0.0.0.0:8000
# ou
uvicorn main:app --host 0.0.0.0 --port 8000
```

---

## 📊 Résultats attendus

### Scénario 1 : Succès complet

```
✅ Firebase Auth: OK
✅ Backend API: OK (200)
✅ Token JWT: Reçu et stocké
✅ Navigation: Vers écran d'accueil
```

### Scénario 2 : Échec Firebase

```
❌ FirebaseAuthException: invalid-email / user-not-found / wrong-password
→ Problème d'identifiants, pas de réseau
```

### Scénario 3 : Échec Backend (notre cas précédent)

```
✅ Firebase Auth: OK
❌ Backend API: Erreur réseau: null
→ Problème de connectivité réseau (IP/firewall/backend)
```

---

## 📝 Notes

- L'IP `10.241.252.68` est spécifique à votre configuration actuelle
- Si vous changez de réseau (maison, bureau, café), l'IP changera
- Solution permanente : Utiliser un nom d'hôte ou service de découverte réseau
- En production : Utiliser `https://api.hivmeet.com` (déjà configuré)

---

**Prochaine action** : Tester sur l'appareil physique et reporter les logs.
