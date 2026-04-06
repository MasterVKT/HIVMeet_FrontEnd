@echo off
setlocal

:: Ajouter Git au PATH
set PATH=%PATH%;C:\Program Files\Git\cmd;C:\Program Files\Git\bin

:: Vérifier que Git est accessible
git --version
if errorlevel 1 (
    echo Erreur: Git n'est toujours pas accessible
    pause
    exit /b 1
)

echo Git est accessible
echo Lancement de Flutter...

:: Lancer Flutter avec les arguments passés au script
flutter %*