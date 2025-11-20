@echo off
echo 🚀 Démarrage du backend de test HIVMeet...
echo.
echo 📍 URL backend: http://localhost:8000
echo 📍 URL pour émulateur: http://10.0.2.2:8000
echo 📱 Admin: http://localhost:8000/admin/
echo 🔧 Health: http://localhost:8000/api/v1/health/
echo 🔐 Firebase Exchange: http://localhost:8000/api/v1/auth/firebase-exchange/
echo.
echo ⚡ Pour arrêter: Ctrl+C
echo.

REM Vérifier si Python est installé
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python n'est pas installé ou pas dans le PATH
    echo 💡 Installez Python depuis https://python.org
    pause
    exit /b 1
)

REM Vérifier si Flask est installé
python -c "import flask" >nul 2>&1
if errorlevel 1 (
    echo 📦 Installation de Flask...
    pip install flask flask-cors
    if errorlevel 1 (
        echo ❌ Erreur lors de l'installation de Flask
        pause
        exit /b 1
    )
)

echo ✅ Démarrage du serveur de test...
echo.
python test_backend_simulation.py

pause 