@echo off
echo Configuration de l'environnement...

REM Ajouter Git au PATH
set PATH=%PATH%;C:\Program Files\Git\cmd

REM Vérifier que Git est accessible
git --version
if %errorlevel% neq 0 (
    echo Erreur: Git n'est pas accessible
    pause
    exit /b 1
)

echo Git configuré avec succès
echo Lancement de l'application Flutter...

REM Lancer Flutter
flutter run

pause
