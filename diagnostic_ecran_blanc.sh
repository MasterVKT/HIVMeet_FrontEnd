#!/bin/bash
# Script de diagnostic rapide pour écran blanc

echo "🔍 DIAGNOSTIC ÉCRAN BLANC - HIVMeet"
echo "===================================="
echo ""

# Test 1 : Vérifier que Flutter fonctionne
echo "Test 1 : Vérification Flutter..."
flutter doctor --version
echo ""

# Test 2 : Nettoyer le build
echo "Test 2 : Nettoyage du build..."
flutter clean
echo ""

# Test 3 : Récupérer les dépendances
echo "Test 3 : Récupération des dépendances..."
flutter pub get
echo ""

# Test 4 : Vérifier les erreurs de compilation
echo "Test 4 : Vérification des erreurs..."
flutter analyze | grep -i "error\|exception"
echo ""

echo "✅ Diagnostic terminé !"
echo ""
echo "Prochaines étapes :"
echo "1. Lancez : flutter run"
echo "2. Partagez les logs complets (surtout les lignes avec DEBUG, Error, Exception)"
echo "3. Notez à quel moment l'écran reste blanc (au démarrage, après connexion, etc.)"
