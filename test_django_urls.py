#!/usr/bin/env python3
"""
Script de diagnostic rapide pour vérifier la configuration Django Firebase Exchange
"""

import requests
import json

# Configuration
BASE_URL = "http://localhost:8000"  # ou http://127.0.0.1:8000
FIREBASE_EXCHANGE_URL = f"{BASE_URL}/api/v1/auth/firebase-exchange/"

def test_endpoint_exists():
    """Test si l'endpoint firebase-exchange existe"""
    print("🔍 Test 1: Vérification existence endpoint...")
    
    try:
        # Test avec un token fictif pour voir si l'endpoint répond (pas 404)
        response = requests.post(
            FIREBASE_EXCHANGE_URL,
            json={"firebase_token": "test_token"},
            timeout=5
        )
        
        print(f"📊 Status Code: {response.status_code}")
        
        if response.status_code == 404:
            print("❌ PROBLÈME: Endpoint retourne 404 - URL mal configurée")
            print("🔧 Solution: Vérifiez la configuration des URLs Django")
            return False
        elif response.status_code in [400, 401]:
            print("✅ SUCCESS: Endpoint existe (erreur normale avec token fictif)")
            return True
        elif response.status_code == 500:
            print("⚠️  WARNING: Endpoint existe mais erreur serveur")
            print("🔧 Solution: Vérifiez la configuration Firebase Admin SDK")
            return True
        else:
            print(f"✅ SUCCESS: Endpoint répond (status: {response.status_code})")
            return True
            
    except requests.exceptions.ConnectionError:
        print("❌ ERREUR: Impossible de se connecter au serveur Django")
        print("🔧 Solution: Vérifiez que le serveur Django est démarré")
        return False
    except Exception as e:
        print(f"❌ ERREUR: {e}")
        return False

def test_discovery_endpoint():
    """Test si l'endpoint discovery existe"""
    print("\n🔍 Test 2: Vérification endpoint discovery...")
    
    try:
        response = requests.get(f"{BASE_URL}/api/v1/discovery/", timeout=5)
        print(f"📊 Status Code: {response.status_code}")
        
        if response.status_code == 404:
            print("❌ PROBLÈME: Endpoint discovery retourne 404")
            return False
        elif response.status_code == 401:
            print("✅ SUCCESS: Endpoint discovery existe (erreur auth normale)")
            return True
        else:
            print(f"✅ SUCCESS: Endpoint discovery répond (status: {response.status_code})")
            return True
            
    except Exception as e:
        print(f"❌ ERREUR: {e}")
        return False

def main():
    print("🚀 DIAGNOSTIC DJANGO FIREBASE EXCHANGE")
    print("=" * 50)
    
    # Test 1: Firebase Exchange Endpoint
    firebase_ok = test_endpoint_exists()
    
    # Test 2: Discovery Endpoint  
    discovery_ok = test_discovery_endpoint()
    
    print("\n📋 RÉSUMÉ")
    print("=" * 50)
    
    if firebase_ok and discovery_ok:
        print("✅ Configuration Django OK - URLs fonctionnelles")
        print("🎯 Le problème peut être au niveau de:")
        print("   - Configuration Firebase Admin SDK")
        print("   - Variables d'environnement")
        print("   - Clés Firebase")
    elif firebase_ok and not discovery_ok:
        print("⚠️  Firebase Exchange OK, Discovery KO")
        print("🔧 Vérifiez la configuration URL de discovery")
    elif not firebase_ok:
        print("❌ Firebase Exchange KO - URL mal configurée")
        print("🔧 Suivez le guide BACKEND_URL_CONFIGURATION.md")
    
    print("\n💡 PROCHAINES ÉTAPES:")
    if not firebase_ok:
        print("1. Vérifiez urls.py principal et app")
        print("2. Redémarrez le serveur Django")
        print("3. Relancez ce test")
    else:
        print("1. Vérifiez firebase_config.py")
        print("2. Vérifiez variables d'environnement Firebase")
        print("3. Testez avec Flutter")

if __name__ == "__main__":
    main() 