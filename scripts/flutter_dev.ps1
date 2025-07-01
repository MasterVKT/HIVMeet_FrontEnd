param(
    [string]$Device = "emulator-5554"
)

Write-Host "🚀 HIVMeet - Lancement en mode développement" -ForegroundColor Cyan
Write-Host "Device: $Device" -ForegroundColor Yellow

# Étape 1: Build APK
Write-Host "`n📦 Construction de l'APK..." -ForegroundColor Yellow
flutter build apk --debug

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors de la construction" -ForegroundColor Red
    exit 1
}

# Étape 2: Corriger l'emplacement APK
Write-Host "`n🔧 Correction de l'emplacement APK..." -ForegroundColor Yellow
if (!(Test-Path "build\app\outputs")) {
    New-Item -ItemType Directory -Path "build\app\outputs" -Force | Out-Null
}

if (Test-Path "android\app\build\outputs\flutter-apk") {
    Copy-Item -Path "android\app\build\outputs\flutter-apk" -Destination "build\app\outputs\" -Recurse -Force
    Write-Host "✅ APK disponible pour Flutter" -ForegroundColor Green
}

# Étape 3: Installation
Write-Host "`n📱 Installation sur $Device..." -ForegroundColor Yellow
flutter install -d $Device

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors de l'installation" -ForegroundColor Red
    exit 1
}

# Étape 4: Attachement pour hot reload
Write-Host "`n🔗 Connexion pour hot reload..." -ForegroundColor Yellow
Write-Host "✅ L'application est installée et prête!" -ForegroundColor Green
Write-Host "🔥 Lancement de Flutter attach pour le hot reload..." -ForegroundColor Cyan

flutter attach -d $Device 