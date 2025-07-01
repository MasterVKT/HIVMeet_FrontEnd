#!/usr/bin/env powershell

# Script de lancement HIVMeet - Resout le probleme "Gradle build failed to produce an .apk file"
# Ce script utilise la methode de compilation + installation directe

param(
    [Parameter(Mandatory=$false)]
    [switch]$Clean,
    
    [Parameter(Mandatory=$false)]
    [switch]$Release
)

Write-Host "Lancement HIVMeet..." -ForegroundColor Green

# Verifier Flutter
try {
    flutter --version | Out-Null
    Write-Host "Flutter detecte" -ForegroundColor Green
} catch {
    Write-Host "Flutter non trouve" -ForegroundColor Red
    exit 1
}

# Verifier les appareils
Write-Host "Verification des appareils..." -ForegroundColor Yellow
$devices = flutter devices --machine 2>$null | ConvertFrom-Json
if ($devices.Count -eq 0) {
    Write-Host "Aucun appareil/emulateur detecte" -ForegroundColor Red
    Write-Host "Lancez un emulateur ou connectez un appareil" -ForegroundColor Yellow
    exit 1
}

$deviceId = $devices[0].id
Write-Host "Appareil trouve: $deviceId" -ForegroundColor Green

# Nettoyer si demande
if ($Clean) {
    Write-Host "Nettoyage..." -ForegroundColor Yellow
    flutter clean | Out-Null
    Write-Host "Nettoyage termine" -ForegroundColor Green
}

# Recuperer les dependances
Write-Host "Recuperation des dependances..." -ForegroundColor Yellow
flutter pub get | Out-Null

# Compiler l'APK
if ($Release) {
    Write-Host "Compilation APK (Release)..." -ForegroundColor Yellow
    flutter build apk --release
    $apkPath = "android\app\build\outputs\flutter-apk\app-release.apk"
} else {
    Write-Host "Compilation APK (Debug)..." -ForegroundColor Yellow
    flutter build apk --debug
    $apkPath = "android\app\build\outputs\flutter-apk\app-debug.apk"
}

# Verifier si l'APK existe
if (Test-Path $apkPath) {
    Write-Host "APK genere: $apkPath" -ForegroundColor Green
    
    # Installer l'APK
    Write-Host "Installation sur $deviceId..." -ForegroundColor Yellow
    adb -s $deviceId install -r $apkPath
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Installation reussie!" -ForegroundColor Green
        
        # Lancer l'application
        Write-Host "Lancement de l'application..." -ForegroundColor Yellow
        adb -s $deviceId shell am start -n com.hivmeet.app/com.hivmeet.app.MainActivity
        
        Write-Host "HIVMeet lance avec succes!" -ForegroundColor Green
        if ($Release) {
            Write-Host "Mode: Production" -ForegroundColor Cyan
        } else {
            Write-Host "Mode: Developpement" -ForegroundColor Cyan
        }
    } else {
        Write-Host "Erreur lors de l'installation" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "APK non trouve a: $apkPath" -ForegroundColor Red
    Write-Host "Verification des dossiers de sortie..." -ForegroundColor Yellow
    
    # Lister les APKs disponibles
    $apkDir = "android\app\build\outputs"
    if (Test-Path $apkDir) {
        Get-ChildItem -Path $apkDir -Recurse -Filter "*.apk" | ForEach-Object {
            Write-Host "APK trouve: $($_.FullName)" -ForegroundColor Yellow
        }
    }
    exit 1
} 