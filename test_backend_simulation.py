#!/usr/bin/env python3
"""
Script de simulation du backend Django pour tester la connectivité Flutter
Usage: python test_backend_simulation.py
"""

from flask import Flask, jsonify, request
from flask_cors import CORS
import time
import json

app = Flask(__name__)
CORS(app)  # Permettre toutes les origines pour le test

@app.route('/admin/')
def admin():
    """Simulation de la page d'admin Django"""
    return '''
    <!DOCTYPE html>
    <html>
    <head><title>Django Administration</title></head>
    <body>
        <h1>Django Administration</h1>
        <p>Backend de test opérationnel !</p>
    </body>
    </html>
    '''

@app.route('/api/v1/discovery/')
def discovery():
    """Simulation de l'endpoint discovery (nécessite auth)"""
    auth_header = request.headers.get('Authorization')
    
    if not auth_header:
        return jsonify({
            'code': 'MISSING_TOKEN',
            'message': 'Token d\'authentification requis',
            'detail': 'Aucun token fourni dans les headers'
        }), 401
    
    if not auth_header.startswith('Bearer '):
        return jsonify({
            'code': 'INVALID_TOKEN_FORMAT',
            'message': 'Format de token invalide',
            'detail': 'Le token doit commencer par "Bearer "'
        }), 401
    
    token = auth_header[7:]  # Enlever "Bearer "
    
    if token != 'valid-test-token':
        return jsonify({
            'code': 'INVALID_TOKEN',
            'message': 'Token invalide',
            'detail': 'Token non reconnu'
        }), 401
    
    # Simulation de données de discovery
    return jsonify({
        'profiles': [
            {
                'id': 1,
                'name': 'Alice',
                'age': 28,
                'bio': 'Aime la nature et les voyages',
                'photos': ['photo1.jpg']
            },
            {
                'id': 2,
                'name': 'Bob',
                'age': 32,
                'bio': 'Passionné de cuisine',
                'photos': ['photo2.jpg']
            }
        ],
        'has_more': True,
        'next_page': 2
    })

@app.route('/api/v1/auth/firebase-exchange/', methods=['POST'])
def firebase_exchange():
    """Simulation de l'endpoint d'échange Firebase → Django JWT"""
    
    if not request.is_json:
        return jsonify({
            'code': 'INVALID_CONTENT_TYPE',
            'message': 'Content-Type doit être application/json'
        }), 400
    
    data = request.get_json()
    firebase_token = data.get('firebase_token')
    
    if not firebase_token:
        return jsonify({
            'code': 'MISSING_FIREBASE_TOKEN',
            'message': 'firebase_token requis',
            'detail': 'Le token Firebase doit être fourni'
        }), 400
    
    # Simulation d'une validation Firebase
    if len(firebase_token) < 50:
        return jsonify({
            'code': 'INVALID_FIREBASE_TOKEN',
            'message': 'Token Firebase invalide',
            'detail': 'Token trop court'
        }), 400
    
    # Simulation de la génération de tokens Django
    return jsonify({
        'access_token': 'valid-test-token',
        'refresh_token': 'valid-refresh-token',
        'token_type': 'Bearer',
        'expires_in': 3600,
        'user': {
            'id': 1,
            'email': 'test@example.com',
            'display_name': 'Utilisateur Test',
            'profile_complete': True
        },
        'message': 'Échange de tokens réussi'
    })

@app.route('/api/v1/health/')
def health():
    """Endpoint de santé pour vérifier que l'API fonctionne"""
    return jsonify({
        'status': 'ok',
        'timestamp': time.time(),
        'version': '1.0.0-test',
        'message': 'Backend de test opérationnel'
    })

@app.errorhandler(404)
def not_found(error):
    return jsonify({
        'code': 'NOT_FOUND',
        'message': 'Endpoint non trouvé',
        'detail': f'Aucun endpoint configuré pour: {request.path}'
    }), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({
        'code': 'INTERNAL_ERROR',
        'message': 'Erreur interne du serveur',
        'detail': str(error)
    }), 500

if __name__ == '__main__':
    print("🚀 Démarrage du backend de test HIVMeet")
    print("📍 URL: http://0.0.0.0:8000")
    print("📍 URL Émulateur: http://10.0.2.2:8000")
    print("🔧 Admin: http://0.0.0.0:8000/admin/")
    print("🔧 Health: http://0.0.0.0:8000/api/v1/health/")
    print("🔧 Discovery: http://0.0.0.0:8000/api/v1/discovery/")
    print("🔧 Firebase Exchange: http://0.0.0.0:8000/api/v1/auth/firebase-exchange/")
    print("\n✅ Le serveur est prêt pour les tests Flutter !")
    print("⚡ Pour tester depuis Flutter, utilisez les outils de diagnostic intégrés")
    
    app.run(
        host='0.0.0.0',
        port=8000,
        debug=True,
        use_reloader=False  # Éviter les redémarrages en boucle
    ) 