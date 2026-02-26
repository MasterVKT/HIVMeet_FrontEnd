# HIVMeet - Dating App for People Living with HIV/AIDS

A Flutter-based dating application designed specifically for people living with HIV/AIDS, providing a safe, supportive, and stigma-free environment to connect and build meaningful relationships.

## Project Overview

**Tech Stack:**
- **Frontend:** Flutter (Dart) - iOS & Android
- **Backend:** Django (Python) + Django REST Framework
- **Database:** PostgreSQL
- **Architecture:** Clean Architecture + BLoC Pattern
- **State Management:** flutter_bloc
- **Dependency Injection:** get_it + injectable
- **Languages:** French (primary), English (secondary)

**Key Features:**
- Profile discovery with swipe interface
- Advanced matching algorithm
- Secure messaging
- Verification system
- Premium subscriptions
- Community support

## Getting Started

### Prerequisites

- Flutter SDK 3.19.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / Xcode (for mobile development)
- Git

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/your-org/hivmeet.git
cd hivmeet
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Generate dependency injection code:**
```bash
flutter pub run build_runner build
```

4. **Run the app:**
```bash
# Development mode
flutter run --debug

# Release mode
flutter run --release

# Specific device
flutter devices
flutter run -d <device-id>
```

### Building

```bash
# Android APK
flutter build apk --release

# iOS IPA
flutter build ios --release

# App Bundle (for Google Play)
flutter build appbundle --release
```

## Project Structure

```
lib/
├── core/                       # Core utilities and configuration
│   ├── config/                # App configuration (theme, routes, constants)
│   ├── error/                 # Error handling (failures, exceptions)
│   ├── events/                # Global app events
│   ├── services/              # Core services (localization, analytics)
│   ├── usecases/              # Base use case interface
│   └── utils/                 # Helper utilities
│
├── data/                       # Data layer (external)
│   ├── models/                # DTOs and response models
│   ├── repositories/          # Repository implementations
│   └── services/              # API services (Dio HTTP client)
│
├── domain/                     # Domain layer (business logic)
│   ├── entities/              # Business entities
│   ├── repositories/          # Repository interfaces
│   └── usecases/              # Business use cases
│
├── presentation/               # Presentation layer (UI)
│   ├── blocs/                 # BLoC state management
│   ├── pages/                 # Full-screen pages
│   └── widgets/               # Reusable UI components
│
└── injection.dart             # Dependency injection setup
```

## Discovery Page - Core Feature

The Discovery page is the main user-facing feature for profile discovery and matching.

### Architecture

**Files:**
- `lib/presentation/pages/discovery/discovery_page.dart` - UI layer
- `lib/presentation/blocs/discovery/discovery_bloc.dart` - Business logic
- `lib/presentation/blocs/discovery/discovery_event.dart` - Events
- `lib/presentation/blocs/discovery/discovery_state.dart` - States
- `lib/presentation/pages/discovery/discovery_constants.dart` - Constants

### Key Features

**1. Swipe Interface**
- Swipe right → Like
- Swipe left → Dislike
- Swipe up → Super Like (premium only)
- Alternative: Action buttons for accessibility

**2. Card Stack**
- Current profile displayed full-screen
- Next 2 profiles previewed in background (scaled/faded)
- Smooth animations (60 FPS target)
- Optimistic UI updates

**3. Match Detection**
- Automatic match detection on mutual likes
- Celebratory modal with animations
- Direct navigation to conversation

**4. Daily Limits (Free Users)**
- 50 likes per day
- 1 super like per day
- Visual limit indicator
- Upgrade CTA when limit reached

**5. Premium Features**
- Unlimited likes
- 5 super likes per day
- Rewind last swipe
- Verified profiles filter

**6. Auto-Pagination**
- Automatically loads more profiles when queue is low (≤2 remaining)
- Cursor-based pagination
- ID-based deduplication
- Seamless UX (no loading interruptions)

### State Flow

```
DiscoveryInitial
  ↓
DiscoveryLoading
  ↓
DiscoveryLoaded ←→ ProfileSwiping ←→ MatchFound
  ↓
NoMoreProfiles / DailyLimitReached / DiscoveryError
```

### Events

- `LoadDiscoveryProfiles` - Load initial/fresh profiles
- `SwipeProfile` - Handle like/dislike/super like
- `RewindLastSwipe` - Undo last swipe (premium)
- `UpdateFilters` - Apply new discovery filters
- `LoadDailyLimit` - Fetch daily limit info
- `LoadMoreProfiles` - Pagination

### Complex Logic

**Swipe Workflow:**
1. Validate (profile exists, limit not reached)
2. Emit ProfileSwiping state (optimistic UI)
3. Call backend API (like/dislike/super_like)
4. Detect match (if mutual like)
5. Remove profile from queue
6. Auto-load more if queue low
7. Update daily limit
8. Emit DiscoveryLoaded or MatchFound

**Deduplication:**
- Maintains Set of existing profile IDs
- Filters new profiles to prevent duplicates
- Critical for smooth UX

**Background Loading:**
- Daily limit loaded asynchronously (non-blocking)
- Profile pagination happens in background
- Errors silently ignored (graceful degradation)

**Interaction Revocation:**
- Listens to global AppEvents
- Auto-refreshes profiles when user revokes interaction
- Prevents stale data

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/presentation/blocs/discovery/discovery_bloc_test.dart

# Integration tests
flutter test integration_test/
```

## Code Quality

```bash
# Analyze code
flutter analyze

# Format code
flutter format lib/ test/

# Check for unused dependencies
flutter pub deps
```

## Internationalization

All text is fully translated in French and English:

```dart
// ✅ CORRECT - Internationalized
Text(LocalizationService.translate('discovery.likes_remaining',
  params: {'count': count.toString()}
))

// ❌ WRONG - Hardcoded
Text('$count likes restants')
```

**Translation Files:**
- `assets/translations/intl_fr.arb` - French
- `assets/translations/intl_en.arb` - English

## Configuration

**API Base URL:** `lib/core/config/constants.dart`

```dart
class Constants {
  static const String baseApiUrl = kDebugMode
      ? 'http://10.0.2.2:8000'  // Android emulator
      : 'https://api.hivmeet.com';
}
```

**Theme:** `lib/core/config/theme/app_theme.dart`

**Routes:** `lib/core/config/routes.dart`

## Documentation

- **Architecture:** `.claude/rules/architecture.md`
- **Backend Integration:** `.claude/rules/backend-integration.md`
- **Testing:** `.claude/rules/testing.md`
- **UI Standards:** `.claude/rules/ui-standards.md`
- **Specifications:** `.claude/rules/specifications.md`
- **API Documentation:** `API_DOCUMENTATION.md`

## Contributing

1. Read `CLAUDE.md` for development guidelines
2. Follow Clean Architecture principles
3. Use BLoC pattern for state management
4. Write tests for all new features
5. Ensure full i18n coverage (FR/EN)
6. Run `flutter analyze` before committing
7. Create descriptive commit messages

## License

[License information here]

## Contact

[Contact information here]

---

**Built with ❤️ for the HIV/AIDS community**
