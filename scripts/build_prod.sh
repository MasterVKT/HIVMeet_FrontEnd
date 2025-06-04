#!/bin/bash
# scripts/build_prod.sh

echo "🔨 Building HIVMeet for Production..."

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Build App Bundle for production (Google Play)
flutter build appbundle --flavor prod --dart-define=ENV=production

# Build IPA for production (App Store)
# Uncomment when building for iOS
# flutter build ios --flavor prod --dart-define=ENV=production

echo "✅ Production build complete!"
echo "📱 AAB location: build/app/outputs/bundle/prodRelease/app-prod-release.aab"