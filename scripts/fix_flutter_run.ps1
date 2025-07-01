# Script pour corriger definitivement le probleme flutter run
param(
    [string]$Device = ""
)

Write-Host "Correction definitive du probleme flutter run..." -ForegroundColor Cyan

# Etape 1: Build APK avec Gradle directement
Write-Host "Construction de l'APK avec Gradle..." -ForegroundColor Yellow
Set-Location android
.\gradlew assembleDebug
$gradleResult = $LASTEXITCODE
Set-Location ..

if ($gradleResult -ne 0) {
    Write-Host "Erreur lors de la construction Gradle" -ForegroundColor Red
    exit 1
}

# Etape 2: Copier l'APK au bon endroit
Write-Host "Copie de l'APK vers l'emplacement Flutter..." -ForegroundColor Yellow

# Creer la structure attendue par Flutter
if (!(Test-Path "build\app\outputs")) {
    New-Item -ItemType Directory -Path "build\app\outputs" -Force | Out-Null
}

# Copier depuis android/app/build vers build/app
if (Test-Path "android\app\build\outputs\flutter-apk") {
    Copy-Item -Path "android\app\build\outputs\flutter-apk" -Destination "build\app\outputs\" -Recurse -Force
    Write-Host "APK copie avec succes" -ForegroundColor Green
    
    # Lister les APK disponibles
    Write-Host "APK disponibles:" -ForegroundColor Cyan
    Get-ChildItem "build\app\outputs\flutter-apk\*.apk" | ForEach-Object {
        $size = [math]::Round($_.Length / 1MB, 1)
        Write-Host "   - $($_.Name) ($size MB)" -ForegroundColor White
    }
} else {
    Write-Host "Aucun APK trouve" -ForegroundColor Red
    exit 1
}

Write-Host "Correction terminee !" -ForegroundColor Green
Write-Host "Vous pouvez maintenant utiliser:" -ForegroundColor Cyan
Write-Host "  flutter install" -ForegroundColor White
Write-Host "  flutter attach" -ForegroundColor White
Write-Host "  flutter run (devrait fonctionner maintenant)" -ForegroundColor Yellow 