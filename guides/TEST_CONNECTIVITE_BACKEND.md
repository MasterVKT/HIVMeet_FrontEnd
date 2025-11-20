# 🌐 Test de Connectivité Backend - Guide Diagnostic

## 🎯 **Objectif**
Diagnostiquer les problèmes de connectivité entre Flutter et le backend Django pour résoudre le timeout d'authentification.

## 🔧 **Configuration Actuelle**

### **URLs Configurées**
```dart
// AppConfig.dart
static String get apiBaseUrl {
  if (kDebugMode) {
    return 'http://10.0.2.2:8000';  // ✅ Correct pour émulateur Android
  } else {
    return 'https://api.hivmeet.com';
  }
}

// Endpoint Firebase Exchange
static String get firebaseExchange => '/auth/firebase-exchange/';
// URL complète: http://10.0.2.2:8000/api/v1/auth/firebase-exchange/
```

## 🧪 **Tests de Diagnostic**

### **1. Test de Connectivité Réseau**
```bash
# Dans le terminal Flutter
flutter run

# Observer les logs :
# ✅ "🌐 Test de connectivité backend..."
# ✅ "Backend accessible: 302" ou "Backend accessible: 200"
# ❌ "Backend inaccessible: [erreur]"
```

### **2. Test Manuel Backend**
```bash
# Test 1: Endpoint Admin (doit retourner 302 redirect)
curl -I http://10.0.2.2:8000/admin/

# Test 2: Endpoint Firebase Exchange (doit retourner 400 MISSING_TOKEN)
curl -X POST http://10.0.2.2:8000/api/v1/auth/firebase-exchange/ \
  -H "Content-Type: application/json" \
  -d '{}'

# Réponse attendue:
# {
#   "code": "MISSING_TOKEN",
#   "message": "Le token Firebase est requis"
# }
```

### **3. Test avec Token Firebase Valide**
```bash
# Obtenir un token Firebase depuis l'app
# Puis tester:
curl -X POST http://10.0.2.2:8000/api/v1/auth/firebase-exchange/ \
  -H "Content-Type: application/json" \
  -d '{"firebase_token": "TOKEN_FIREBASE_ICI"}'
```

## 📊 **Logs Attendus - Succès**

### **Logs Flutter (Succès)**
```
🔧 AuthenticationService initialisé
🔐 Tentative de connexion: user@email.com
📡 Vérification connectivité réseau...
✅ Connectivité réseau OK
🌐 Test de connectivité backend...
✅ Backend accessible: 302
✅ Connectivité OK, authentification Firebase...
✅ Connexion Firebase réussie, attente échange tokens...
🔄 Tentative d'échange token Firebase...
🌐 URL: http://10.0.2.2:8000/api/v1/auth/firebase-exchange/
📊 Réponse échange tokens: Status 200
✅ Échange de tokens réussi pour user@email.com
```

### **Logs Django (Succès)**
```
INFO: 🔄 Tentative d'échange token Firebase...
INFO: ✅ Token Firebase valide pour UID: eUcVrZFynGNuVTN1FdrMURQjjSo1
INFO: 👤 Utilisateur existant: user@email.com
INFO: ✅ Email vérifié pour utilisateur: user@email.com
INFO: 🎯 Tokens JWT générés pour utilisateur ID: 1
POST /api/v1/auth/firebase-exchange/ 200 OK
```

## ❌ **Logs d'Erreur - Diagnostic**

### **Erreur 1: Backend Inaccessible**
```
❌ Backend inaccessible: DioException [DioErrorType.connectionTimeout]
```
**Solution :** Vérifier que Django est démarré sur le port 8000

### **Erreur 2: URL Incorrecte**
```
❌ Backend inaccessible: DioException [DioErrorType.badResponse] 404
```
**Solution :** Vérifier que l'URL est correcte (pas de duplication api/v1)

### **Erreur 3: Timeout d'Authentification**
```
⏰ Timeout attente processus authentification (statut: authenticating)
```
**Solution :** Le processus Firebase réussit mais l'échange de tokens échoue

### **Erreur 4: Erreur 500 Backend**
```
❌ Erreur serveur 500 - Problème backend
```
**Solution :** Vérifier les logs Django pour l'erreur spécifique

## 🔍 **Diagnostic Pas à Pas**

### **Étape 1: Vérifier Django**
```bash
# Démarrer Django
python manage.py runserver 0.0.0.0:8000

# Vérifier que le serveur répond
curl http://localhost:8000/admin/
```

### **Étape 2: Vérifier l'Émulateur**
```bash
# Dans Flutter, vérifier l'IP de l'émulateur
adb shell ip addr show eth0

# Doit retourner 10.0.2.2 pour l'émulateur Android
```

### **Étape 3: Test de Connectivité**
```bash
# Dans l'émulateur Android
adb shell ping 10.0.2.2

# Doit retourner des réponses
```

### **Étape 4: Test Endpoint**
```bash
# Test direct depuis l'émulateur
adb shell curl -I http://10.0.2.2:8000/admin/
```

## 🛠️ **Solutions Courantes**

### **Problème 1: Django ne démarre pas**
```bash
# Vérifier les dépendances
pip install -r requirements.txt

# Vérifier les migrations
python manage.py migrate

# Démarrer avec debug
python manage.py runserver 0.0.0.0:8000 --verbosity=2
```

### **Problème 2: Port 8000 occupé**
```bash
# Changer le port dans Django
python manage.py runserver 0.0.0.0:8001

# Mettre à jour AppConfig.dart
return 'http://10.0.2.2:8001';
```

### **Problème 3: Firewall/Proxy**
```bash
# Désactiver temporairement le firewall
# Ou ajouter une exception pour le port 8000
```

### **Problème 4: CORS Django**
```python
# Dans settings.py
CORS_ALLOWED_ORIGINS = [
    "http://10.0.2.2:8000",
    "http://localhost:8000",
]
```

## 📱 **Test dans l'Application**

### **1. Lancer l'App**
```bash
flutter run
```

### **2. Observer les Logs**
- Vérifier que "Backend accessible" apparaît
- Vérifier que l'URL est correcte
- Vérifier que le processus d'authentification se termine

### **3. Test de Connexion**
- Tenter de se connecter avec un compte existant
- Observer les logs de succès/échec
- Vérifier la navigation vers discovery

## 🎯 **Résultat Attendu**

Après correction, l'application doit :
1. ✅ Afficher "Backend accessible" dans les logs
2. ✅ Se connecter à Firebase sans timeout
3. ✅ Échanger les tokens avec Django
4. ✅ Naviguer vers l'écran discovery
5. ✅ Afficher l'utilisateur connecté

**Si le problème persiste, vérifier les logs Django pour des erreurs spécifiques !** 