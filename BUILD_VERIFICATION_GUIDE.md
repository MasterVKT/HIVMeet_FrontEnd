# HIVMeet Build Verification Guide

**Version**: 1.0
**Date**: February 28, 2026
**Task**: 002 - Discovery Page Spec Compliance (Phase 8.5)
**Purpose**: Comprehensive build process testing for clean build, release build, and asset bundling verification

---

## Executive Summary

This guide provides comprehensive procedures for testing the full HIVMeet Flutter build process to ensure:
- ✅ Clean builds complete without errors
- ✅ Release builds (Android APK/AAB, iOS IPA) are production-ready
- ✅ Asset bundling works correctly (translations, images, fonts)
- ✅ No build warnings or configuration issues
- ✅ Build performance meets targets
- ✅ Output artifacts are deployment-ready

**Total Test Procedures**: 45 checks across 6 categories
**Estimated Execution Time**: 90-120 minutes
**Priority**: P0 (Critical) - MANDATORY before deployment

---

## Test Execution Summary

| Category | Test Count | Priority | Time Est. | Status |
|----------|-----------|----------|-----------|--------|
| Clean Build Verification | 8 tests | P0 | 15 min | ⬜ Not Started |
| Release Build Verification (Android) | 10 tests | P0 | 25 min | ⬜ Not Started |
| Release Build Verification (iOS) | 10 tests | P0 | 30 min | ⬜ Not Started |
| Asset Bundling Verification | 7 tests | P0 | 10 min | ⬜ Not Started |
| Configuration Validation | 6 tests | P0 | 10 min | ⬜ Not Started |
| Build Warnings/Errors Audit | 4 tests | P0 | 20 min | ⬜ Not Started |

**TOTAL**: 45 tests | 110 minutes

---

## Prerequisites and Preparation

### Required Tools and Environment

**Flutter SDK:**
- Version: 3.24.0 or higher (check with `flutter --version`)
- Channels: Stable (recommended)

**Platform-Specific SDKs:**
- **Android**: Android Studio, Android SDK 23-35, Gradle 7.5+
- **iOS**: Xcode 15+, CocoaPods, macOS 12+ (for iOS builds)

**Build Tools:**
- `flutter doctor` - Must show all green checkmarks
- Git - For version control verification
- Java JDK 11+ (for Android builds)

**Test Environment:**
```bash
# Verify environment before starting
flutter doctor -v
flutter pub get
flutter clean
```

### Pre-Test Checklist

- [ ] All dependencies installed (`flutter pub get` completed successfully)
- [ ] `flutter doctor` shows no critical issues
- [ ] Git working directory is clean (no uncommitted changes)
- [ ] Sufficient disk space (minimum 10 GB free)
- [ ] No background build processes running
- [ ] Terminal/shell has write permissions to project directory

---

## Part 1: Clean Build Verification (8 Tests - P0)

### Test 1.1: Flutter Clean Command
**Priority**: P0 (Critical)
**Estimated Time**: 1 minute

**Test Steps:**
1. Open terminal in project root directory
2. Run the following command:
   ```bash
   flutter clean
   ```

**Expected Result:**
```
Deleting .dart_tool...
Deleting build...
```

**Success Criteria:**
- ✅ Command completes in <10 seconds
- ✅ No error messages
- ✅ `build/` directory deleted
- ✅ `.dart_tool/` directory deleted

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Notes:**
_[Document any issues or deviations]_

---

### Test 1.2: Dependencies Installation
**Priority**: P0 (Critical)
**Estimated Time**: 2 minutes

**Test Steps:**
1. After `flutter clean`, run:
   ```bash
   flutter pub get
   ```

**Expected Result:**
```
Running "flutter pub get" in hivmeet...
Resolving dependencies...
Got dependencies!
```

**Success Criteria:**
- ✅ All dependencies resolve without conflicts
- ✅ No deprecation warnings
- ✅ No version conflicts
- ✅ `pubspec.lock` is updated
- ✅ Completes in <60 seconds

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Notes:**
_[Document any dependency conflicts or warnings]_

---

### Test 1.3: Code Generation
**Priority**: P0 (Critical)
**Estimated Time**: 3 minutes

**Test Steps:**
1. Run code generation:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

**Expected Result:**
```
[INFO] Generating build script...
[INFO] Generating build script completed, took XXXms
[INFO] Creating build script snapshot......
[INFO] Running build...
[INFO] Build completed successfully
```

**Success Criteria:**
- ✅ All generated files created without errors
- ✅ No conflicting outputs
- ✅ Injectable, Retrofit, JSON serialization files generated
- ✅ Completes in <180 seconds

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Notes:**
_[Document any code generation errors]_

---

### Test 1.4: Static Analysis (flutter analyze)
**Priority**: P0 (Critical)
**Estimated Time**: 3 minutes

**Test Steps:**
1. Run static analysis:
   ```bash
   flutter analyze
   ```

**Expected Result:**
```
Analyzing hivmeet...
No issues found!
```

**Success Criteria:**
- ✅ Zero errors
- ✅ Zero warnings (or only acceptable warnings documented below)
- ✅ Zero lints (or only acceptable lints documented below)
- ✅ Completes in <120 seconds

**Acceptable Warnings** (document if any):
- _[List any known acceptable warnings]_

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Notes:**
_[Document any unexpected warnings or errors]_

---

### Test 1.5: Debug Build - Android
**Priority**: P0 (Critical)
**Estimated Time**: 5 minutes

**Test Steps:**
1. Build Android debug APK:
   ```bash
   flutter build apk --debug
   ```

**Expected Result:**
```
Running Gradle task 'assembleDebug'...
✓ Built build/app/outputs/flutter-apk/app-debug.apk (XX.X MB).
```

**Success Criteria:**
- ✅ Build completes without errors
- ✅ APK file created in `build/app/outputs/flutter-apk/app-debug.apk`
- ✅ APK size is reasonable (<100 MB for debug)
- ✅ Completes in <300 seconds (5 minutes)
- ✅ No Gradle dependency resolution errors

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Notes:**
_[Document build time, APK size, any warnings]_

---

### Test 1.6: Debug Build - iOS (macOS only)
**Priority**: P0 (Critical)
**Estimated Time**: 5 minutes

**Test Steps:**
1. Build iOS debug app:
   ```bash
   flutter build ios --debug --no-codesign
   ```

**Expected Result:**
```
Building com.hivmeet.hivmeet for device (ios-release)...
Automatically signing iOS for device deployment using specified development team...
Running pod install...
Running Xcode build...
Xcode build done.
```

**Success Criteria:**
- ✅ Build completes without errors
- ✅ Xcode build succeeds
- ✅ CocoaPods dependencies resolve
- ✅ Completes in <300 seconds (5 minutes)
- ✅ No code signing errors (with --no-codesign)

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked | ⬜ N/A (Windows/Linux)

**Notes:**
_[Document build time, any Xcode warnings, CocoaPods issues]_

---

### Test 1.7: Hot Reload Functionality
**Priority**: P0 (Critical)
**Estimated Time**: 3 minutes

**Test Steps:**
1. Start app in debug mode on emulator/device:
   ```bash
   flutter run --debug
   ```
2. Make a small UI change (e.g., change text in Discovery page)
3. Press `r` in terminal for hot reload
4. Verify change appears in app

**Expected Result:**
```
Performing hot reload...
Reloaded 1 of X libraries in XXXms.
```

**Success Criteria:**
- ✅ Hot reload completes in <2 seconds
- ✅ UI change visible in app
- ✅ App state preserved
- ✅ No errors or exceptions

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Notes:**
_[Document hot reload time, any state loss issues]_

---

### Test 1.8: Hot Restart Functionality
**Priority**: P0 (Critical)
**Estimated Time**: 3 minutes

**Test Steps:**
1. While app is running in debug mode
2. Make a code change (e.g., modify a BLoC event)
3. Press `R` in terminal for hot restart
4. Verify app restarts with changes

**Expected Result:**
```
Performing hot restart...
Restarted application in XXXms.
```

**Success Criteria:**
- ✅ Hot restart completes in <5 seconds
- ✅ Code changes applied
- ✅ App launches successfully
- ✅ No build errors

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Notes:**
_[Document hot restart time, any issues]_

---

## Part 2: Release Build Verification - Android (10 Tests - P0)

### Test 2.1: Release APK Build
**Priority**: P0 (Critical)
**Estimated Time**: 6 minutes

**Test Steps:**
1. Build release APK:
   ```bash
   flutter build apk --release
   ```

**Expected Result:**
```
Running Gradle task 'assembleRelease'...
✓ Built build/app/outputs/flutter-apk/app-release.apk (XX.X MB).
```

**Success Criteria:**
- ✅ Build completes without errors
- ✅ APK created at `build/app/outputs/flutter-apk/app-release.apk`
- ✅ APK size is optimized (<30 MB target)
- ✅ Completes in <360 seconds (6 minutes)
- ✅ No ProGuard/R8 errors

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**APK Size**: _________ MB

**Build Time**: _________ seconds

**Notes:**
_[Document any build warnings, optimization issues]_

---

### Test 2.2: Release AAB Build (Android App Bundle)
**Priority**: P0 (Critical)
**Estimated Time**: 6 minutes

**Test Steps:**
1. Build Android App Bundle for Play Store:
   ```bash
   flutter build appbundle --release
   ```

**Expected Result:**
```
Running Gradle task 'bundleRelease'...
✓ Built build/app/outputs/bundle/release/app-release.aab (XX.X MB).
```

**Success Criteria:**
- ✅ Build completes without errors
- ✅ AAB created at `build/app/outputs/bundle/release/app-release.aab`
- ✅ AAB size is optimized (<25 MB target)
- ✅ Completes in <360 seconds (6 minutes)
- ✅ No bundle errors

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**AAB Size**: _________ MB

**Build Time**: _________ seconds

**Notes:**
_[Document AAB size, build time]_

---

### Test 2.3: ProGuard/R8 Configuration
**Priority**: P0 (Critical)
**Estimated Time**: 2 minutes

**Test Steps:**
1. Verify ProGuard/R8 is enabled in `android/app/build.gradle`:
   ```gradle
   buildTypes {
       release {
           minifyEnabled true
           shrinkResources true
           proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
       }
   }
   ```

**Expected Result:**
- ProGuard/R8 enabled in release build
- `proguard-rules.pro` exists and contains necessary keep rules

**Success Criteria:**
- ✅ `minifyEnabled true` in release build type
- ✅ `shrinkResources true` in release build type
- ✅ ProGuard rules file exists
- ✅ No reflection/serialization classes stripped incorrectly

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Notes:**
_[Document ProGuard warnings, any keep rules added]_

---

### Test 2.4: Gradle Build Configuration
**Priority**: P0 (Critical)
**Estimated Time**: 2 minutes

**Test Steps:**
1. Verify `android/app/build.gradle` configuration:
   - Correct `applicationId`: `com.hivmeet.hivmeet`
   - `minSdk`: 23 (Android 6.0)
   - `targetSdk`: 35 (Android 15)
   - `compileSdk`: 35

**Expected Result:**
```gradle
android {
    namespace 'com.hivmeet.hivmeet'
    compileSdk 35

    defaultConfig {
        applicationId "com.hivmeet.hivmeet"
        minSdk 23
        targetSdk 35
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }
}
```

**Success Criteria:**
- ✅ Application ID matches package name
- ✅ minSdk, targetSdk, compileSdk are correct
- ✅ Version code and version name set correctly
- ✅ Namespace defined

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Notes:**
_[Document any configuration issues]_

---

### Test 2.5: APK Installation Test
**Priority**: P0 (Critical)
**Estimated Time**: 3 minutes

**Test Steps:**
1. Install release APK on Android device/emulator:
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```
2. Launch app manually
3. Navigate to Discovery page
4. Test basic functionality (swipe, filters, match modal)

**Expected Result:**
- APK installs successfully
- App launches without crashes
- All features work correctly
- No runtime errors

**Success Criteria:**
- ✅ APK installs without errors
- ✅ App launches in <5 seconds
- ✅ Discovery page loads successfully
- ✅ Swipe gestures work
- ✅ No crashes or ANR (Application Not Responding)

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Notes:**
_[Document installation issues, runtime errors]_

---

### Test 2.6: Release Build Optimization Verification
**Priority**: P0 (Critical)
**Estimated Time**: 2 minutes

**Test Steps:**
1. Verify release build optimizations:
   - Dead code elimination
   - Tree shaking
   - Resource shrinking
   - Obfuscation (if enabled)

2. Check APK contents:
   ```bash
   unzip -l build/app/outputs/flutter-apk/app-release.apk | grep -E "(lib|assets)"
   ```

**Expected Result:**
- APK contains only necessary libraries
- Unused code removed
- Resources optimized

**Success Criteria:**
- ✅ APK size significantly smaller than debug (<30 MB)
- ✅ No debug symbols in release APK
- ✅ Unused resources removed
- ✅ Flutter engine optimized

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Debug APK Size**: _________ MB
**Release APK Size**: _________ MB
**Size Reduction**: _________%

**Notes:**
_[Document optimization gains]_

---

### Test 2.7: Multi-ABI Support Verification
**Priority**: P0 (Critical)
**Estimated Time**: 2 minutes

**Test Steps:**
1. Verify APK contains all required ABIs:
   ```bash
   unzip -l build/app/outputs/flutter-apk/app-release.apk | grep -E "lib/(armeabi-v7a|arm64-v8a|x86_64)"
   ```

**Expected Result:**
APK should contain native libraries for:
- `arm64-v8a` (64-bit ARM, modern devices)
- `armeabi-v7a` (32-bit ARM, older devices)
- `x86_64` (optional, for emulators)

**Success Criteria:**
- ✅ `arm64-v8a` libraries present (REQUIRED)
- ✅ `armeabi-v7a` libraries present (REQUIRED)
- ✅ All ABIs contain libflutter.so, libapp.so

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**ABIs Found:**
- ⬜ arm64-v8a
- ⬜ armeabi-v7a
- ⬜ x86_64

**Notes:**
_[Document ABI configuration]_

---

### Test 2.8: Google Services Configuration
**Priority**: P0 (Critical)
**Estimated Time**: 2 minutes

**Test Steps:**
1. Verify `google-services.json` exists in `android/app/`
2. Verify Firebase plugin in `android/app/build.gradle`:
   ```gradle
   id 'com.google.gms.google-services'
   ```
3. Check Firebase dependencies

**Expected Result:**
- Firebase configured correctly
- All Firebase services accessible

**Success Criteria:**
- ✅ `google-services.json` file exists
- ✅ Firebase plugin applied in build.gradle
- ✅ Package name matches Firebase project
- ✅ Firebase services initialize at runtime

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Notes:**
_[Document Firebase configuration issues]_

---

### Test 2.9: Kotlin Version Compatibility
**Priority**: P0 (Critical)
**Estimated Time**: 2 minutes

**Test Steps:**
1. Verify Kotlin version in `android/build.gradle`:
   ```gradle
   ext.kotlin_version = '1.9.0' // or higher
   ```
2. Check for Kotlin compatibility issues in build logs

**Expected Result:**
- Compatible Kotlin version
- No Kotlin compilation errors

**Success Criteria:**
- ✅ Kotlin version ≥ 1.9.0
- ✅ No Kotlin/Java interop errors
- ✅ No deprecation warnings

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Kotlin Version**: _________

**Notes:**
_[Document Kotlin issues]_

---

### Test 2.10: Android Manifest Verification
**Priority**: P0 (Critical)
**Estimated Time**: 2 minutes

**Test Steps:**
1. Review `android/app/src/main/AndroidManifest.xml`:
   - Correct package name
   - Required permissions only
   - Deep linking configuration (if applicable)
   - Internet permission
   - Camera permission (for profile photos)
   - Location permission (for distance filters)

**Expected Result:**
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.hivmeet.hivmeet">

    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <!-- Other necessary permissions -->
</manifest>
```

**Success Criteria:**
- ✅ Package name correct: `com.hivmeet.hivmeet`
- ✅ Only necessary permissions declared
- ✅ No excessive permissions
- ✅ Deep linking configured (if required)

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Permissions Declared:**
- ⬜ INTERNET
- ⬜ ACCESS_FINE_LOCATION
- ⬜ CAMERA
- ⬜ Other: _________________

**Notes:**
_[Document manifest issues]_

---

## Part 3: Release Build Verification - iOS (10 Tests - P0)

**Note**: iOS build tests require macOS with Xcode. Skip this section if building on Windows/Linux.

### Test 3.1: CocoaPods Dependency Installation
**Priority**: P0 (Critical)
**Estimated Time**: 4 minutes

**Test Steps:**
1. Navigate to iOS directory:
   ```bash
   cd ios
   pod install
   cd ..
   ```

**Expected Result:**
```
Analyzing dependencies
Downloading dependencies
Installing <packages>
Generating Pods project
Pod installation complete!
```

**Success Criteria:**
- ✅ All pods install without errors
- ✅ No version conflicts
- ✅ Podfile.lock updated
- ✅ Completes in <240 seconds (4 minutes)

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked | ⬜ N/A

**Notes:**
_[Document CocoaPods warnings, version conflicts]_

---

### Test 3.2: iOS Release Build
**Priority**: P0 (Critical)
**Estimated Time**: 8 minutes

**Test Steps:**
1. Build iOS release app:
   ```bash
   flutter build ios --release --no-codesign
   ```

**Expected Result:**
```
Building com.hivmeet.hivmeet for device (ios-release)...
Running pod install...
Running Xcode build...
Xcode archive done.
Built /path/to/Runner.app
```

**Success Criteria:**
- ✅ Build completes without errors
- ✅ Xcode build succeeds
- ✅ App bundle created
- ✅ Completes in <480 seconds (8 minutes)
- ✅ No code signing errors (with --no-codesign)

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked | ⬜ N/A

**Build Time**: _________ seconds

**Notes:**
_[Document Xcode build warnings, errors]_

---

### Test 3.3: iOS IPA Archive Build
**Priority**: P0 (Critical)
**Estimated Time**: 10 minutes

**Test Steps:**
1. Build iOS archive for App Store:
   ```bash
   flutter build ipa --release
   ```

**Expected Result:**
```
Building com.hivmeet.hivmeet for device (ios-release)...
Running Xcode build...
Xcode archive done.
Built IPA to build/ios/ipa/hivmeet.ipa
```

**Success Criteria:**
- ✅ IPA file created
- ✅ Archive is valid
- ✅ Completes in <600 seconds (10 minutes)
- ✅ Code signing configured (or skipped with --no-codesign)

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked | ⬜ N/A

**IPA Size**: _________ MB

**Notes:**
_[Document IPA size, signing issues]_

---

### Test 3.4: Xcode Project Configuration
**Priority**: P0 (Critical)
**Estimated Time**: 3 minutes

**Test Steps:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Verify project settings:
   - Bundle Identifier: `com.hivmeet.hivmeet`
   - Deployment Target: iOS 13.0 or higher
   - Team/Code Signing configured
   - App capabilities enabled (Push Notifications, Background Modes)

**Expected Result:**
- All settings correct
- No Xcode warnings in project navigator

**Success Criteria:**
- ✅ Bundle ID matches: `com.hivmeet.hivmeet`
- ✅ Deployment target ≥ iOS 13.0
- ✅ Code signing identity set
- ✅ Required capabilities enabled

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked | ⬜ N/A

**Notes:**
_[Document Xcode configuration issues]_

---

### Test 3.5: Info.plist Configuration
**Priority**: P0 (Critical)
**Estimated Time**: 2 minutes

**Test Steps:**
1. Review `ios/Runner/Info.plist`:
   - Correct Bundle ID
   - Required permissions (Camera, Location, Photos)
   - URL schemes (for deep linking)
   - Firebase configuration

**Expected Result:**
```xml
<key>CFBundleIdentifier</key>
<string>com.hivmeet.hivmeet</string>

<key>NSCameraUsageDescription</key>
<string>HIVMeet needs camera access to upload profile photos</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>HIVMeet uses your location to find matches nearby</string>
```

**Success Criteria:**
- ✅ Bundle ID correct
- ✅ All required permissions with user-friendly descriptions
- ✅ Deep linking URL schemes configured
- ✅ Firebase GoogleService-Info.plist included

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked | ⬜ N/A

**Notes:**
_[Document Info.plist issues]_

---

### Test 3.6: Firebase Configuration (iOS)
**Priority**: P0 (Critical)
**Estimated Time**: 2 minutes

**Test Steps:**
1. Verify `GoogleService-Info.plist` exists in `ios/Runner/`
2. Check bundle ID matches Firebase project
3. Verify Firebase SDK initialization

**Expected Result:**
- Firebase configured correctly
- Bundle ID matches Firebase console

**Success Criteria:**
- ✅ `GoogleService-Info.plist` file exists
- ✅ Bundle ID matches: `com.hivmeet.hivmeet`
- ✅ Firebase services initialize at runtime

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked | ⬜ N/A

**Notes:**
_[Document Firebase configuration issues]_

---

### Test 3.7: iOS Build Optimization Verification
**Priority**: P0 (Critical)
**Estimated Time**: 2 minutes

**Test Steps:**
1. Verify release build optimizations:
   - Dead code stripping enabled
   - Swift optimization level: `-O` (Optimize for Speed)
   - Bitcode: Disabled (deprecated by Apple)

2. Check build settings in Xcode:
   - `DEAD_CODE_STRIPPING = YES`
   - `SWIFT_OPTIMIZATION_LEVEL = -O`

**Expected Result:**
- Optimizations enabled in release configuration
- App size minimized

**Success Criteria:**
- ✅ Dead code stripping enabled
- ✅ Swift optimization enabled
- ✅ IPA size optimized (<60 MB target)

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked | ⬜ N/A

**IPA Size**: _________ MB

**Notes:**
_[Document optimization settings]_

---

### Test 3.8: iOS Simulator Installation Test
**Priority**: P0 (Critical)
**Estimated Time**: 3 minutes

**Test Steps:**
1. Build for iOS Simulator:
   ```bash
   flutter build ios --simulator
   ```
2. Install on iOS Simulator
3. Test basic functionality (Discovery page, swipes, filters)

**Expected Result:**
- App installs and runs on Simulator
- All features functional
- No crashes

**Success Criteria:**
- ✅ Build completes successfully
- ✅ App installs on Simulator
- ✅ App launches in <5 seconds
- ✅ Discovery page works correctly
- ✅ No runtime errors

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked | ⬜ N/A

**Notes:**
_[Document installation issues, runtime errors]_

---

### Test 3.9: iOS Device Installation Test (Optional)
**Priority**: P1 (High)
**Estimated Time**: 5 minutes

**Test Steps:**
1. Connect physical iOS device
2. Build and install release app:
   ```bash
   flutter build ios --release
   flutter install --release
   ```
3. Test on device

**Expected Result:**
- App installs on physical device
- All features work correctly
- Performance is smooth

**Success Criteria:**
- ✅ App installs successfully
- ✅ App launches quickly
- ✅ Discovery page swipes are smooth (60fps)
- ✅ No crashes or performance issues

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked | ⬜ N/A

**Device Tested**: _________________

**Notes:**
_[Document device-specific issues]_

---

### Test 3.10: Xcode Build Warnings Audit
**Priority**: P0 (Critical)
**Estimated Time**: 3 minutes

**Test Steps:**
1. Build in Xcode and review build log
2. Check for warnings in:
   - Swift code
   - Objective-C code
   - CocoaPods
   - Firebase SDK

**Expected Result:**
- Zero critical warnings
- Only acceptable warnings documented

**Success Criteria:**
- ✅ No Swift deprecation warnings
- ✅ No CocoaPods warnings
- ✅ No Firebase configuration warnings
- ✅ No code signing warnings

**Acceptable Warnings** (if any):
- _[List known acceptable warnings]_

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked | ⬜ N/A

**Total Warnings**: _________

**Notes:**
_[Document unexpected warnings]_

---

## Part 4: Asset Bundling Verification (7 Tests - P0)

### Test 4.1: Translation Files Bundling
**Priority**: P0 (Critical)
**Estimated Time**: 2 minutes

**Test Steps:**
1. Verify translation files in `assets/translations/`:
   - `en.json` (English)
   - `fr.json` (French)

2. Check files are listed in `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/translations/
   ```

3. Build app and verify files are included:
   ```bash
   # For Android APK
   unzip -l build/app/outputs/flutter-apk/app-release.apk | grep "assets/translations"
   ```

**Expected Result:**
```
assets/translations/en.json
assets/translations/fr.json
```

**Success Criteria:**
- ✅ Both translation files exist
- ✅ Files listed in pubspec.yaml
- ✅ Files included in APK/IPA
- ✅ No missing translation keys

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Translation Files Found:**
- ⬜ en.json (_____ keys)
- ⬜ fr.json (_____ keys)

**Notes:**
_[Document missing files, key count mismatches]_

---

### Test 4.2: Image Assets Bundling
**Priority**: P0 (Critical)
**Estimated Time**: 2 minutes

**Test Steps:**
1. Verify image assets in `assets/images/`:
   - App logo
   - Placeholder images
   - Onboarding images
   - Other required images

2. Check images are listed in `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/images/
   ```

3. Verify images load in app

**Expected Result:**
- All required images present
- Images display correctly in app

**Success Criteria:**
- ✅ All image files exist
- ✅ Images listed in pubspec.yaml
- ✅ Images load without errors
- ✅ Image quality acceptable

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Images Found**: _________ files

**Notes:**
_[Document missing images, quality issues]_

---

### Test 4.3: Icon Assets Bundling
**Priority**: P0 (Critical)
**Estimated Time**: 2 minutes

**Test Steps:**
1. Verify icon assets in `assets/icons/`:
   - Navigation icons
   - Action button icons
   - Status icons

2. Check icons are listed in `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/icons/
   ```

3. Verify icons display correctly in app

**Expected Result:**
- All required icons present
- Icons render correctly at all sizes

**Success Criteria:**
- ✅ All icon files exist
- ✅ Icons listed in pubspec.yaml
- ✅ Icons load without errors
- ✅ Icons scale correctly

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Icons Found**: _________ files

**Notes:**
_[Document missing icons, rendering issues]_

---

### Test 4.4: Font Assets Bundling
**Priority**: P0 (Critical)
**Estimated Time**: 1 minute

**Test Steps:**
1. Verify Google Fonts dependency in `pubspec.yaml`:
   ```yaml
   dependencies:
     google_fonts: ^6.1.0
   ```

2. Check font usage in app (e.g., in theme configuration)

3. Verify fonts display correctly

**Expected Result:**
- Fonts load correctly from Google Fonts
- Text displays with correct typography

**Success Criteria:**
- ✅ Google Fonts dependency present
- ✅ Fonts load at runtime
- ✅ Typography consistent across app
- ✅ No font fallback issues

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Notes:**
_[Document font loading issues]_

---

### Test 4.5: pubspec.yaml Asset Declaration Audit
**Priority**: P0 (Critical)
**Estimated Time**: 2 minutes

**Test Steps:**
1. Review `pubspec.yaml` asset declarations:
   ```yaml
   flutter:
     uses-material-design: true
     assets:
       - assets/images/
       - assets/icons/
       - assets/translations/
   ```

2. Verify all asset directories are declared
3. Check for typos or incorrect paths

**Expected Result:**
- All asset directories declared
- Paths are correct
- No missing declarations

**Success Criteria:**
- ✅ `assets/images/` declared
- ✅ `assets/icons/` declared
- ✅ `assets/translations/` declared
- ✅ `uses-material-design: true` set
- ✅ No trailing slashes missing

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Notes:**
_[Document asset declaration issues]_

---

### Test 4.6: Asset Loading Performance Test
**Priority**: P0 (Critical)
**Estimated Time**: 2 minutes

**Test Steps:**
1. Launch app and navigate to Discovery page
2. Observe asset loading time:
   - Profile images
   - Icons
   - Translations

3. Check for loading delays or flickering

**Expected Result:**
- Assets load quickly (<500ms)
- No flickering or layout shifts
- Smooth transitions

**Success Criteria:**
- ✅ Images load in <500ms
- ✅ Icons display immediately
- ✅ Translations load instantly
- ✅ No layout shifts during asset loading

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Average Asset Load Time**: _________ ms

**Notes:**
_[Document slow asset loading, performance issues]_

---

### Test 4.7: Asset Size Optimization Check
**Priority**: P0 (Critical)
**Estimated Time**: 2 minutes

**Test Steps:**
1. Check asset file sizes:
   ```bash
   du -sh assets/images/*
   du -sh assets/icons/*
   ```

2. Verify images are optimized:
   - No unnecessarily large files
   - Appropriate resolution for mobile
   - Compressed formats (WebP, PNG)

**Expected Result:**
- All assets optimized for mobile
- Total asset size reasonable (<10 MB)

**Success Criteria:**
- ✅ No images >1 MB
- ✅ Icons are SVG or optimized PNG
- ✅ Total asset size <10 MB
- ✅ No uncompressed images

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Total Asset Size**: _________ MB

**Largest Asset**: _________ (_________ MB)

**Notes:**
_[Document oversized assets, optimization opportunities]_

---

## Part 5: Configuration Validation (6 Tests - P0)

### Test 5.1: pubspec.yaml Dependency Versions
**Priority**: P0 (Critical)
**Estimated Time**: 3 minutes

**Test Steps:**
1. Review all dependencies in `pubspec.yaml`
2. Check for:
   - Outdated packages (run `flutter pub outdated`)
   - Version conflicts
   - Deprecated packages
   - Missing dependencies

**Expected Result:**
```
All dependencies up-to-date or with acceptable versions
No major version conflicts
```

**Success Criteria:**
- ✅ Flutter SDK version: ≥3.24.0
- ✅ Dart SDK version: ≥3.2.0
- ✅ No deprecated packages
- ✅ No major version conflicts
- ✅ All critical packages up-to-date

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Outdated Packages**: _________

**Deprecated Packages**: _________

**Notes:**
_[Document dependency issues, version conflicts]_

---

### Test 5.2: Environment Configuration Validation
**Priority**: P0 (Critical)
**Estimated Time**: 2 minutes

**Test Steps:**
1. Verify environment configuration files:
   - `.env.dev`
   - `.env.staging`
   - `.env.prod`

2. Check that sensitive data is NOT committed:
   - API keys
   - Secret keys
   - Tokens

3. Verify `.gitignore` includes environment files

**Expected Result:**
- Environment files exist
- No secrets committed to Git
- `.gitignore` configured correctly

**Success Criteria:**
- ✅ Environment files present
- ✅ No API keys in Git
- ✅ `.gitignore` includes `.env*`
- ✅ Configuration structure correct

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Notes:**
_[Document configuration issues, security concerns]_

---

### Test 5.3: Constants Configuration Validation
**Priority**: P0 (Critical)
**Estimated Time**: 2 minutes

**Test Steps:**
1. Review `lib/core/config/constants.dart`:
   - Base API URLs configured correctly
   - Environment-based configuration working
   - No hardcoded production URLs in debug builds

**Expected Result:**
```dart
class Constants {
  static const String baseApiUrl = kDebugMode
      ? 'http://localhost:8000'  // Dev
      : 'https://api.hivmeet.com'; // Production
}
```

**Success Criteria:**
- ✅ API URLs configured per environment
- ✅ Debug mode uses dev URLs
- ✅ Release mode uses production URLs
- ✅ No hardcoded sensitive data

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Notes:**
_[Document configuration issues]_

---

### Test 5.4: Firebase Configuration Validation
**Priority**: P0 (Critical)
**Estimated Time**: 2 minutes

**Test Steps:**
1. Verify Firebase configuration files:
   - **Android**: `android/app/google-services.json`
   - **iOS**: `ios/Runner/GoogleService-Info.plist`

2. Check package names match:
   - Android: `com.hivmeet.hivmeet`
   - iOS: `com.hivmeet.hivmeet`

3. Verify Firebase is initialized in `lib/main.dart`

**Expected Result:**
- Firebase configured correctly for both platforms
- Package names consistent

**Success Criteria:**
- ✅ Firebase config files exist
- ✅ Package names match
- ✅ Firebase initialized in main.dart
- ✅ All Firebase services accessible

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Notes:**
_[Document Firebase configuration issues]_

---

### Test 5.5: Build Configuration Consistency Check
**Priority**: P0 (Critical)
**Estimated Time**: 2 minutes

**Test Steps:**
1. Verify version consistency across:
   - `pubspec.yaml`: `version: 1.0.0+1`
   - Android: `versionCode` and `versionName` in build.gradle
   - iOS: `CFBundleShortVersionString` and `CFBundleVersion` in Info.plist

**Expected Result:**
- Version numbers consistent across all platforms
- Version code increments correctly

**Success Criteria:**
- ✅ pubspec.yaml version: `1.0.0+1`
- ✅ Android versionName: `1.0.0`
- ✅ Android versionCode: `1`
- ✅ iOS version: `1.0.0`
- ✅ iOS build number: `1`

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Version Numbers:**
- pubspec.yaml: _________________
- Android versionName: _________________
- Android versionCode: _________________
- iOS version: _________________
- iOS build: _________________

**Notes:**
_[Document version inconsistencies]_

---

### Test 5.6: Deep Linking Configuration Check
**Priority**: P1 (High)
**Estimated Time**: 2 minutes

**Test Steps:**
1. Verify deep linking configuration:
   - **Android**: `AndroidManifest.xml` intent filters
   - **iOS**: `Info.plist` URL schemes

2. Test deep link (if applicable):
   ```
   hivmeet://profile/12345
   ```

**Expected Result:**
- Deep links configured correctly
- App handles deep links appropriately

**Success Criteria:**
- ✅ Deep link URL scheme configured
- ✅ Intent filters set up (Android)
- ✅ URL schemes set up (iOS)
- ✅ Deep links navigate correctly (if implemented)

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked | ⬜ N/A

**Notes:**
_[Document deep linking issues]_

---

## Part 6: Build Warnings/Errors Audit (4 Tests - P0)

### Test 6.1: Flutter Analyze Output Review
**Priority**: P0 (Critical)
**Estimated Time**: 5 minutes

**Test Steps:**
1. Run comprehensive static analysis:
   ```bash
   flutter analyze --no-pub
   ```

2. Review all warnings and errors
3. Categorize issues:
   - **Critical**: Must fix before release
   - **High**: Should fix before release
   - **Medium**: Nice to fix
   - **Low**: Informational only

**Expected Result:**
```
Analyzing hivmeet...
No issues found!
```

**Success Criteria:**
- ✅ Zero errors
- ✅ Zero critical warnings
- ✅ All warnings documented and justified

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Total Errors**: _________
**Total Warnings**: _________
**Total Lints**: _________

**Unresolved Issues:**
| Issue | Severity | File | Justification/Plan |
|-------|----------|------|-------------------|
| | | | |

**Notes:**
_[Document all warnings and errors]_

---

### Test 6.2: Gradle Build Warnings Review (Android)
**Priority**: P0 (Critical)
**Estimated Time**: 5 minutes

**Test Steps:**
1. Build Android release with verbose output:
   ```bash
   flutter build apk --release --verbose
   ```

2. Review Gradle build log for:
   - Deprecated API usage
   - Dependency warnings
   - ProGuard/R8 warnings
   - Build configuration warnings

**Expected Result:**
- No critical Gradle warnings
- All warnings documented

**Success Criteria:**
- ✅ No deprecated Gradle API usage
- ✅ No unresolved dependency conflicts
- ✅ No ProGuard/R8 reflection warnings
- ✅ All warnings acceptable

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Gradle Warnings Found**: _________

**Unresolved Warnings:**
| Warning | Severity | File | Justification/Plan |
|---------|----------|------|-------------------|
| | | | |

**Notes:**
_[Document Gradle warnings]_

---

### Test 6.3: Xcode Build Warnings Review (iOS)
**Priority**: P0 (Critical)
**Estimated Time**: 5 minutes

**Test Steps:**
1. Build iOS release in Xcode or via command line:
   ```bash
   flutter build ios --release --no-codesign --verbose
   ```

2. Review Xcode build log for:
   - Swift warnings
   - Objective-C warnings
   - CocoaPods warnings
   - Deprecation warnings

**Expected Result:**
- No critical Xcode warnings
- All warnings documented

**Success Criteria:**
- ✅ No Swift deprecation warnings
- ✅ No CocoaPods compatibility warnings
- ✅ No code signing warnings
- ✅ All warnings acceptable

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked | ⬜ N/A

**Xcode Warnings Found**: _________

**Unresolved Warnings:**
| Warning | Severity | File | Justification/Plan |
|---------|----------|------|-------------------|
| | | | |

**Notes:**
_[Document Xcode warnings]_

---

### Test 6.4: Runtime Warnings Audit
**Priority**: P0 (Critical)
**Estimated Time**: 5 minutes

**Test Steps:**
1. Launch app in release mode
2. Monitor console/logcat for runtime warnings:
   ```bash
   # Android
   adb logcat -s flutter

   # iOS
   idevicesyslog | grep Runner
   ```

3. Navigate through all main features
4. Document any runtime warnings

**Expected Result:**
- No critical runtime warnings
- No unhandled exceptions
- No memory warnings

**Success Criteria:**
- ✅ No unhandled exceptions
- ✅ No memory leak warnings
- ✅ No asset loading errors
- ✅ No API connection warnings

**Status**: ⬜ Pass | ⬜ Fail | ⬜ Blocked

**Runtime Warnings Found**: _________

**Unresolved Warnings:**
| Warning | Severity | Context | Justification/Plan |
|---------|----------|---------|-------------------|
| | | | |

**Notes:**
_[Document runtime warnings]_

---

## Build Performance Metrics

### Build Time Benchmarks

| Build Type | Target Time | Actual Time | Status |
|------------|-------------|-------------|--------|
| `flutter clean` | <10 seconds | _________ | ⬜ |
| `flutter pub get` | <60 seconds | _________ | ⬜ |
| Code generation | <180 seconds | _________ | ⬜ |
| `flutter analyze` | <120 seconds | _________ | ⬜ |
| Android debug APK | <300 seconds | _________ | ⬜ |
| Android release APK | <360 seconds | _________ | ⬜ |
| Android release AAB | <360 seconds | _________ | ⬜ |
| iOS debug (no sign) | <300 seconds | _________ | ⬜ |
| iOS release (no sign) | <480 seconds | _________ | ⬜ |
| iOS IPA | <600 seconds | _________ | ⬜ |

**Total Clean Build Time (Android)**: _________ minutes
**Total Clean Build Time (iOS)**: _________ minutes

---

### Output Artifact Sizes

| Artifact | Target Size | Actual Size | Status |
|----------|-------------|-------------|--------|
| Android debug APK | <100 MB | _________ MB | ⬜ |
| Android release APK | <30 MB | _________ MB | ⬜ |
| Android release AAB | <25 MB | _________ MB | ⬜ |
| iOS release IPA | <60 MB | _________ MB | ⬜ |

**Size Reduction (Debug → Release)**: _________%

---

## QA Sign-Off

### Build Verification Summary

**Total Tests**: 45
**Tests Passed**: _________
**Tests Failed**: _________
**Tests Blocked/N/A**: _________

**Pass Rate**: _________%

### Critical Issues Found

| Issue ID | Description | Severity | Status | Resolution |
|----------|-------------|----------|--------|------------|
| | | | | |

### Sign-Off Decision

**Build Status**: ⬜ APPROVED | ⬜ APPROVED WITH CONDITIONS | ⬜ REJECTED

**QA Engineer**: _________________
**Date**: _________________
**Signature**: _________________

**Conditions for Approval** (if applicable):
- _[List any conditions that must be met before deployment]_

**Comments:**
_[Additional notes, observations, recommendations]_

---

## Appendix A: Common Build Issues and Solutions

### Issue 1: Gradle Build Failure
**Symptom**: `FAILURE: Build failed with an exception.`

**Solutions**:
1. Clean build cache:
   ```bash
   flutter clean
   cd android && ./gradlew clean && cd ..
   ```
2. Update Gradle wrapper:
   ```bash
   cd android && ./gradlew wrapper --gradle-version=7.5 && cd ..
   ```
3. Invalidate caches (Android Studio): File → Invalidate Caches / Restart

---

### Issue 2: CocoaPods Installation Failure (iOS)
**Symptom**: `pod install` fails with dependency conflicts

**Solutions**:
1. Clear CocoaPods cache:
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   pod cache clean --all
   pod install --repo-update
   cd ..
   ```
2. Update CocoaPods:
   ```bash
   sudo gem install cocoapods
   ```

---

### Issue 3: Out of Memory During Build
**Symptom**: Gradle/Xcode runs out of memory

**Solutions**:
1. Increase Gradle memory (Android):
   Edit `android/gradle.properties`:
   ```properties
   org.gradle.jvmargs=-Xmx2048m -XX:MaxPermSize=512m
   ```
2. Close other applications
3. Build with verbose output to identify memory-intensive steps

---

### Issue 4: Asset Not Found at Runtime
**Symptom**: `Unable to load asset: assets/...`

**Solutions**:
1. Verify asset declared in `pubspec.yaml`
2. Check file path (case-sensitive on Linux/macOS)
3. Run `flutter clean && flutter pub get`
4. Rebuild app completely

---

### Issue 5: Version Conflict (Dependency Resolution)
**Symptom**: `Because X depends on Y which doesn't match any versions...`

**Solutions**:
1. Update all dependencies:
   ```bash
   flutter pub upgrade
   ```
2. Use dependency overrides in `pubspec.yaml`:
   ```yaml
   dependency_overrides:
     package_name: ^version
   ```
3. Check for incompatible packages

---

## Appendix B: Build Verification Checklist (Quick Reference)

**Pre-Build:**
- [ ] `flutter doctor` shows all green checkmarks
- [ ] Git working directory is clean
- [ ] Dependencies installed (`flutter pub get`)

**Clean Build:**
- [ ] `flutter clean` completes successfully
- [ ] Code generation succeeds
- [ ] `flutter analyze` passes with zero errors

**Debug Build:**
- [ ] Android debug APK builds successfully
- [ ] iOS debug build succeeds (macOS only)
- [ ] Hot reload and hot restart work

**Release Build:**
- [ ] Android release APK builds (<30 MB)
- [ ] Android release AAB builds (<25 MB)
- [ ] iOS release IPA builds (<60 MB, macOS only)
- [ ] ProGuard/R8 optimization working (Android)
- [ ] Dead code stripping working (iOS)

**Asset Bundling:**
- [ ] Translation files (en.json, fr.json) included
- [ ] Image assets load correctly
- [ ] Icon assets display properly
- [ ] Fonts render correctly

**Configuration:**
- [ ] All dependency versions acceptable
- [ ] Firebase configured for both platforms
- [ ] Version numbers consistent
- [ ] Environment configuration secure

**Quality Checks:**
- [ ] Zero errors in `flutter analyze`
- [ ] Gradle build warnings acceptable
- [ ] Xcode build warnings acceptable
- [ ] No critical runtime warnings

**Installation:**
- [ ] Release APK installs on Android device
- [ ] Release build installs on iOS device (if applicable)
- [ ] App launches without crashes
- [ ] Core features work correctly

---

## Appendix C: Recommended Test Devices

### Android Test Devices
**Minimum Test Set**:
- Android 6.0 (API 23) - Minimum supported version
- Android 10 (API 29) - Mid-range target
- Android 13+ (API 33+) - Latest version

**Device Recommendations**:
- Low-end: Samsung Galaxy A12, Moto G Play
- Mid-range: Google Pixel 6a, Samsung Galaxy A52
- High-end: Google Pixel 8, Samsung Galaxy S23

### iOS Test Devices (macOS Required)
**Minimum Test Set**:
- iOS 13 - Minimum supported version
- iOS 15 - Mid-range target
- iOS 17 - Latest version

**Device Recommendations**:
- iPhone SE (2020/2022) - Small screen, budget
- iPhone 14 - Standard size, modern features
- iPhone 14 Pro Max - Large screen, high-end

---

## Document Metadata

**Version**: 1.0
**Author**: Auto-Claude Agent
**Task ID**: 002 - Discovery Page Spec Compliance
**Subtask ID**: 8.5 - Build Verification Testing
**Last Updated**: February 28, 2026

**Related Documents**:
- `SMOKE_TEST_SUITE.md` - Regression testing guide
- `MANUAL_QA_TEST_PLAN.md` - Manual QA procedures
- `DISCOVERY_PAGE_INTEGRATION_POINTS_MAP.md` - Integration points
- `CLAUDE.md` - Project development rules

**Change Log**:
- 2026-02-28: Initial version created

---

**END OF BUILD VERIFICATION GUIDE**
