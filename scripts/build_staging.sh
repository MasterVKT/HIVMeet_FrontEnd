#!/bin/bash
# scripts/build_staging.sh

echo "🔨 Building HIVMeet for Staging..."

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Build APK for staging
flutter build apk --flavor staging --dart-define=ENV=staging

echo "✅ Staging build complete!"
echo "📱 APK location: build/app/outputs/flutter-apk/app-staging-release.apk"