Write-Host "Correction du probleme flutter run..." -ForegroundColor Yellow

if (!(Test-Path "build\app\outputs")) {
    New-Item -ItemType Directory -Path "build\app\outputs" -Force | Out-Null
    Write-Host "Dossier cree" -ForegroundColor Green
}

if (Test-Path "android\app\build\outputs\flutter-apk") {
    Copy-Item -Path "android\app\build\outputs\flutter-apk" -Destination "build\app\outputs\" -Recurse -Force
    Write-Host "APK copie avec succes" -ForegroundColor Green
    Get-ChildItem "build\app\outputs\flutter-apk\*.apk"
} else {
    Write-Host "Aucun APK trouve. Executez: flutter build apk --debug" -ForegroundColor Red
    exit 1
}

Write-Host "Vous pouvez maintenant utiliser flutter install" -ForegroundColor Green 