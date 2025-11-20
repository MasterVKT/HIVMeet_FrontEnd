# 🔧 Configuration URLs Django - Endpoint Firebase Exchange

## 🎯 Problème
L'endpoint `/api/v1/auth/firebase-exchange/` retourne 404. L'URL n'est pas correctement configurée dans Django.

## ✅ Solution : Configuration URLs Step-by-Step

### **1. URLs Principal (myproject/urls.py)**

Dans votre fichier `urls.py` principal :

```python
# myproject/urls.py (ou votre projet principal)
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v1/', include('yourapp.urls')),  # ← Assurez-vous que cette ligne existe
    # ... autres URLs
]
```

### **2. URLs de l'App (yourapp/urls.py)**

Dans le fichier `urls.py` de votre application :

```python
# yourapp/urls.py (remplacez 'yourapp' par le nom de votre app)
from django.urls import path
from . import views

urlpatterns = [
    # Endpoint Firebase Exchange
    path('auth/firebase-exchange/', views.firebase_token_exchange, name='firebase-exchange'),
    
    # Autres endpoints
    path('discovery/', views.discovery_view, name='discovery'),
    path('profiles/', views.profiles_view, name='profiles'),
    # ... autres URLs
]
```

### **3. Vue Firebase Exchange (views.py)**

Assurez-vous que la vue existe dans `views.py` :

```python
# yourapp/views.py
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from firebase_admin import auth
from django.contrib.auth.models import User
from django.db import transaction
import logging

logger = logging.getLogger(__name__)

@api_view(['POST'])
@permission_classes([AllowAny])
def firebase_token_exchange(request):
    """Échange un token Firebase Auth contre des tokens JWT Django"""
    try:
        firebase_token = request.data.get('firebase_token')
        
        if not firebase_token:
            return Response({
                'error': 'firebase_token est requis',
                'code': 'MISSING_TOKEN'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        logger.info(f"🔄 Tentative d'échange token Firebase...")
        
        # Vérifier et décoder le token Firebase Auth
        try:
            decoded_token = auth.verify_id_token(firebase_token)
            logger.info(f"✅ Token Firebase valide pour UID: {decoded_token.get('uid')}")
        except Exception as e:
            logger.error(f"❌ Token Firebase invalide: {str(e)}")
            return Response({
                'error': 'Token Firebase invalide ou expiré',
                'code': 'INVALID_FIREBASE_TOKEN'
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        # Extraire les informations utilisateur
        firebase_uid = decoded_token['uid']
        email = decoded_token.get('email')
        name = decoded_token.get('name', '')
        
        if not email:
            return Response({
                'error': 'Email requis dans le token Firebase',
                'code': 'MISSING_EMAIL'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Récupérer ou créer l'utilisateur Django
        with transaction.atomic():
            user, created = User.objects.get_or_create(
                email=email,
                defaults={
                    'username': email,
                    'first_name': name.split(' ')[0] if name else '',
                    'last_name': ' '.join(name.split(' ')[1:]) if ' ' in name else '',
                    'is_active': True,
                }
            )
            
            if created:
                logger.info(f"👤 Nouvel utilisateur créé: {email}")
            else:
                logger.info(f"👤 Utilisateur existant: {email}")
        
        # Générer des tokens JWT Django
        refresh = RefreshToken.for_user(user)
        access_token = refresh.access_token
        
        logger.info(f"🎯 Tokens JWT générés pour utilisateur ID: {user.id}")
        
        return Response({
            'access': str(access_token),
            'refresh': str(refresh),
            'user': {
                'id': user.id,
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'firebase_uid': firebase_uid,
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        logger.error(f"💥 Erreur inattendue dans firebase_token_exchange: {str(e)}")
        return Response({
            'error': 'Erreur interne du serveur',
            'code': 'INTERNAL_ERROR'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
```

## 🧪 Test de Configuration

### **1. Vérifier les URLs**

Exécutez cette commande Django pour lister toutes les URLs :

```bash
python manage.py show_urls | grep firebase
```

**Résultat attendu :**
```
/api/v1/auth/firebase-exchange/    yourapp.views.firebase_token_exchange    firebase-exchange
```

### **2. Test Direct de l'Endpoint**

Testez directement avec curl :

```bash
curl -X POST http://localhost:8000/api/v1/auth/firebase-exchange/ \
  -H "Content-Type: application/json" \
  -d '{"firebase_token": "test"}'
```

**Résultat attendu :**
- ✅ **200 ou 400** (pas 404) → URL configurée
- ❌ **404** → URL mal configurée

### **3. Logs Django à Surveiller**

Après redémarrage du serveur Django, vous devriez voir :

```bash
🔄 Tentative d'échange token Firebase...
✅ Token Firebase valide pour UID: firebase_uid_here
👤 Utilisateur existant: vekout@yahoo.fr
🎯 Tokens JWT générés pour utilisateur ID: 1
POST /api/v1/auth/firebase-exchange/ 200 OK
```

## 🚨 Diagnostic Rapide

### **Si toujours 404 :**
1. Vérifiez le nom de votre app Django
2. Vérifiez que `include('yourapp.urls')` est dans le urls.py principal
3. Vérifiez que l'app est dans `INSTALLED_APPS` (settings.py)
4. Redémarrez complètement le serveur Django

### **Si 500 Internal Server Error :**
1. Vérifiez que Firebase Admin SDK est installé : `pip install firebase-admin`
2. Vérifiez les variables d'environnement Firebase
3. Consultez les logs Django pour les détails de l'erreur

### **Si 401 Unauthorized :**
1. Vérifiez les clés Firebase Admin SDK
2. Vérifiez que le projet Firebase est correct

---

## ✅ Résultat Final Attendu

**Flutter logs après correction :**
```bash
🔍 DEBUG: Utilisateur Firebase: vekout@yahoo.fr
🔑 Token Firebase récupéré: eyJhbGciOiJSUzI1NiIs...
🔄 Tentative échange token Firebase...
✅ Échange token réussi
✅ Token Django JWT utilisé
🚀 REQUEST: GET http://10.0.2.2:8000/api/v1/discovery/
✅ RESPONSE: 200 OK
```

**L'application devrait alors fonctionner parfaitement !** 🎯 