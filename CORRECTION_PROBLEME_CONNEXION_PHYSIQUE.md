# Correction - Problème de connexion sur appareil physique

**Date**: 2026-07-26  
**Statut**: À vérifier  
**Sévérité**: Critique (bloque l'authentification)

---

## 🐛 Problème

Lors du login sur un **appareil physique**, l'application affiche "Service indisponible" avec l'erreur :
```
Erreur de connexion: Erreur réseau: null
```

---

## 🔍 Diagnostic

### Analyse des logs

1. ✅ **Firebase Auth fonctionne** :
   ```
   D/FirebaseAuth(30730): Notifying id token listeners about user ( jqDyfrQLrLgoIG0tg8WRXZDk6Rt2 ).
   ```

2. ❌ **Échec réseau après authentification Firebase** :
   ```
   🐠 [BLOC] Résultat de signInWithEmailAndPassword: success=false
   🚨 [BLOC] Connexion échouée: Erreur de connexion: Erreur réseau: null
   ```

3. ⚠️ **App Check manquant** (warning, pas bloquant) :
   ```
   W/LocalRequestInterceptor(30730): Error getting App Check token; using placeholder token instead.
   ```

### Cause racine identifiée

**Configuration URL backend dans `lib/core/config/app_config.dart`** :

```dart
if (_isPhysicalDevice) {
  // Physical device: use the host machine's LAN IP.
  return 'http://192.168.1.118:8000';
}
```

**Problèmes possibles** :

1. ❌ **IP incorrecte** : `192.168.1.118` n'est pas l'IP de votre machine
2. ❌ **Backend non démarré** : Le serveur backend n'est pas en écoute sur le port 8000
3. ❌ **Firewall** : Le port 8000 est bloqué par le firewall Windows
4. ❌ **Réseau différent** : L'appareil et la machine ne sont pas sur le même réseau WiFi

---

## ✅ Solution

### Étape 1 : IP de votre machine (DÉJÀ FAIT)

Votre IP actuelle est : **`10.241.252.68`**

Cette IP a déjà été configurée dans `app_config.dart`. Si vous changez de réseau, vous devrez la mettre à jour.

Pour vérifier votre IP à l'avenir :

```powershell
ipconfig
```

Recherchez l'adresse IPv4 sous votre connexion WiFi/Ethernet :
```
Carte Wi-Fi :
   Adresse IPv4 . . . . . . . . . . . : 192.168.x.x
```

### Étape 2 : Mettre à jour l'URL backend

**Option A : Modifier `app_config.dart`** (DÉJÀ FAIT ✅)

L'IP a été mise à jour automatiquement dans `lib/core/config/app_config.dart` :

```dart
if (_isPhysicalDevice) {
  return 'http://10.241.252.68:8000'; // IP actuelle configurée
}
```

**Si vous changez de réseau**, mettez à jour cette ligne avec la nouvelle IP.

**Option B : Utiliser --dart-define** (recommandé)

Lancez l'application avec l'IP correcte :

```powershell
flutter run --dart-define=API_URL=http://192.168.x.x:8000
```

Ou avec votre script :

```powershell
.\run_flutter_multi.ps1 --dart-define=API_URL=http://192.168.x.x:8000
```

### Étape 3 : Vérifier que le backend est démarré ✅

**STATUT** : Backend déjà démarré et accessible

1. ✅ Backend démarré sur le port 8000 (PID 4740)
2. ✅ Accessible depuis la machine locale
3. ⚠️ Les endpoints API retournent 400 (normal pour des requêtes GET sans contexte)

Pour tester avec un endpoint d'authentification :
```powershell
# Test de login (à adapter selon votre backend)
```

### Étape 4 : Configurer le firewall Windows

Si le backend est démarré mais inaccessible :

1. Ouvrez "Pare-feu Windows Defender avec sécurité avancée"
2. Cliquez sur "Règles de trafic entrant" → "Nouvelle règle"
3. Sélectionnez "Port" → "TCP" → Port spécifique : `8000`
4. Autoriser la connexion
5. Appliquez à tous les profils (Domaine, Privé, Public)

### Étape 5 : Vérifier le réseau

Assurez-vous que :
- ✅ Votre machine et l'appareil sont sur le **même réseau WiFi**
- ✅ Le réseau n'est pas isolé (certains réseaux "invité" isolent les appareils)
- ✅ Le WiFi n'utilise pas de VLAN séparé

---

## 🧪 Validation

Après avoir appliqué la correction :

1. ✅ Redémarrez l'application sur l'appareil physique
2. ✅ Tentez de vous connecter avec `max.weber@test.com`
3. ✅ Vérifiez dans les logs :
   ```
   ✅ [BLOC] Connexion réussie
   ```
4. ✅ Confirmez que la navigation vers l'écran suivant fonctionne

---

## 📝 Notes techniques

### Pourquoi Firebase Auth réussit mais pas le backend ?

- **Firebase Auth** : Utilise les serveurs cloud de Firebase (accessible depuis internet)
- **Backend API** : Hébergé localement sur votre machine (nécessite connectivité LAN)

### App Check Warning

Le warning `No AppCheckProvider installed` n'est **PAS** la cause du problème. C'est une configuration optionnelle de sécurité Firebase.

---

## 🔗 Fichiers concernés

- `lib/core/config/app_config.dart` - Configuration URL backend
- `lib/data/datasources/remote/auth_api.dart` - Appel API d'authentification
- `lib/presentation/blocs/auth/auth_bloc_simple.dart` - Gestion état de connexion

---

## 🚀 Prochaines étapes

1. [x] ✅ Identifier l'IP réelle de votre machine avec `ipconfig` → **10.241.252.68**
2. [x] ✅ Mettre à jour la configuration avec la bonne IP → **DÉJÀ FAIT**
3. [ ] Vérifier que le backend est démarré et accessible
4. [ ] Tester la connexion sur l'appareil physique
5. [ ] Documenter l'IP dans un fichier `.env.local` ou README

---

**Si le problème persiste** : Fournir les logs complets après avoir corrigé l'IP.
