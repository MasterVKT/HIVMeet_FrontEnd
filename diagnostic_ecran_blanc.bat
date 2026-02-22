@echo off
REM Script de diagnostic rapide pour écran blanc (Windows)

echo ==================================
echo DIAGNOSTIC ECRAN BLANC - HIVMeet
echo ==================================
echo.

REM Test 1 : Vérifier que Flutter fonctionne
echo Test 1 : Verification Flutter...
flutter --version
echo.

REM Test 2 : Nettoyer le build
echo Test 2 : Nettoyage du build...
flutter clean
echo.

REM Test 3 : Récupérer les dépendances
echo Test 3 : Recuperation des dependances...
flutter pub get
echo.

REM Test 4 : Lancer l'application avec logs détaillés
echo Test 4 : Lancement de l'application...
echo.
echo Les logs vont s'afficher ci-dessous.
echo IMPORTANT : Copiez tous les logs qui s'affichent !
echo.
pause

flutter run --verbose

echo.
echo FIN DU DIAGNOSTIC
echo.
echo Si l'ecran est toujours blanc, partagez les logs complets.
pause
