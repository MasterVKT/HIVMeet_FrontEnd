#!/bin/bash
# scripts/build_dev.sh

echo "🔨 Building HIVMeet for Development..."

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Build APK for dev
flutter build apk --flavor dev --dart-define=ENV=development

echo "✅ Development build complete!"
echo "📱 APK location: build/app/outputs/flutter-apk/app-dev-release.apk"