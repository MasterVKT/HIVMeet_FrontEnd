# Script de nettoyage et reconstruction complète HIVMeet
Write-Host "🧹 Nettoyage complet du projet HIVMeet..." -ForegroundColor Yellow

# Arrêter tous les processus Gradle
Write-Host "Arrêt des processus Gradle..." -ForegroundColor Cyan
try {
    Get-Process -Name "*gradle*" -ErrorAction SilentlyContinue | Stop-Process -Force
    Get-Process -Name "*java*" -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like "*gradle*" } | Stop-Process -Force
} catch {
    Write-Host "Aucun processus Gradle à arrêter" -ForegroundColor Gray
}

# Nettoyer Flutter
Write-Host "Nettoyage Flutter..." -ForegroundColor Cyan
flutter clean

# Nettoyer Gradle Android
Write-Host "Nettoyage Gradle Android..." -ForegroundColor Cyan
Set-Location android
try {
    .\gradlew clean --no-daemon
} catch {
    Write-Host "Erreur lors du nettoyage Gradle, continuation..." -ForegroundColor Yellow
}
Set-Location ..

# Supprimer les dossiers de cache manuellement
Write-Host "Suppression des caches manuellement..." -ForegroundColor Cyan
$cachePaths = @(
    "build",
    ".dart_tool",
    "android\.gradle",
    "android\app\build",
    "android\build",
    "ios\build",
    "ios\Pods",
    "ios\.symlinks"
)

foreach ($path in $cachePaths) {
    if (Test-Path $path) {
        Write-Host "Suppression de $path..." -ForegroundColor Gray
        Remove-Item -Recurse -Force $path -ErrorAction SilentlyContinue
    }
}

# Récupérer les dépendances
Write-Host "Récupération des dépendances..." -ForegroundColor Cyan
flutter pub get

# Générer les fichiers auto-générés
Write-Host "Génération des fichiers..." -ForegroundColor Cyan
flutter packages pub run build_runner build --delete-conflicting-outputs

# Construire l'APK
Write-Host "Construction de l'APK..." -ForegroundColor Green
flutter build apk --debug

Write-Host "✅ Nettoyage et reconstruction terminés !" -ForegroundColor Green 