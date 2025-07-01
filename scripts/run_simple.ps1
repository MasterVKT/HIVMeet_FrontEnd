#!/usr/bin/env powershell

# Script de lancement simple pour HIVMeet
# Résout le problème de localisation de l'APK avec le nouveau plugin Gradle

Write-Host "🚀 Lancement de HIVMeet..." -ForegroundColor Green

# Vérifier si Flutter est installé
try {
    flutter --version | Out-Null
    Write-Host "✅ Flutter détecté" -ForegroundColor Green
} catch {
    Write-Host "❌ Flutter non trouvé. Veuillez installer Flutter." -ForegroundColor Red
    exit 1
}

# Vérifier les appareils connectés
Write-Host "📱 Vérification des appareils..." -ForegroundColor Yellow
$devices = flutter devices --machine | ConvertFrom-Json
if ($devices.Count -eq 0) {
    Write-Host "❌ Aucun appareil détecté. Veuillez connecter un appareil ou lancer un émulateur." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Appareils détectés: $($devices.Count)" -ForegroundColor Green

# Nettoyer le projet
Write-Host "🧹 Nettoyage du projet..." -ForegroundColor Yellow
flutter clean | Out-Null

# Récupérer les dépendances
Write-Host "📦 Récupération des dépendances..." -ForegroundColor Yellow
flutter pub get | Out-Null

# Compiler l'APK
Write-Host "🔨 Compilation de l'APK..." -ForegroundColor Yellow
flutter build apk --debug

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Compilation réussie!" -ForegroundColor Green
    
    # Installer l'APK sur le premier appareil
    $deviceId = $devices[0].id
    Write-Host "📲 Installation sur l'appareil: $deviceId" -ForegroundColor Yellow
    
    # Installer l'APK directement
    adb -s $deviceId install -r "android\app\build\outputs\apk\debug\app-debug.apk"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "🎉 Application installée avec succès!" -ForegroundColor Green
        Write-Host "📱 Vous pouvez maintenant lancer HIVMeet sur votre appareil." -ForegroundColor Cyan
        
        # Optionnel: lancer l'application
        Write-Host "🚀 Lancement de l'application..." -ForegroundColor Yellow
        adb -s $deviceId shell am start -n com.hivmeet.app/com.hivmeet.app.MainActivity
        
        Write-Host "✨ HIVMeet est maintenant en cours d'exécution!" -ForegroundColor Green
    } else {
        Write-Host "❌ Erreur lors de l'installation" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "❌ Erreur lors de la compilation" -ForegroundColor Red
    exit 1
} 