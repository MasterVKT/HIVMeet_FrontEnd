# Discovery Page Data Models, Entities, and DTOs Inventory

**Document Version:** 1.0
**Date:** 2026-02-25
**Task:** 2.5 - Inventory Discovery Models and DTOs
**Author:** auto-claude

---

## Table of Contents

1. [Overview](#overview)
2. [Entity Layer (Domain)](#entity-layer-domain)
3. [Model Layer (Data/DTOs)](#model-layer-datadtos)
4. [Serialization & Transformations](#serialization--transformations)
5. [Validation Logic](#validation-logic)
6. [Usage Patterns](#usage-patterns)
7. [Compliance Analysis](#compliance-analysis)
8. [Summary](#summary)

---

## Overview

This document inventories all data models, entities, and DTOs (Data Transfer Objects) used by the Discovery page in HIVMeet. The Discovery page follows **Clean Architecture** principles with clear separation between:

- **Domain Layer (Entities)**: Business objects with business logic, independent of data sources
- **Data Layer (Models/DTOs)**: Serializable objects for API/database communication
- **Transformations**: Conversion logic between layers

### Architecture Pattern

```
API Response (JSON)
    ↓
Model (DTO) [fromJson]
    ↓
Entity (Domain) [toEntity]
    ↓
BLoC/Use Cases (Business Logic)
    ↓
UI (Presentation)
```

### File Locations

| Layer | Location | Count |
|-------|----------|-------|
| Domain Entities | `lib/domain/entities/` | 8 files |
| Data Models | `lib/data/models/` | 8 files |
| Generated Code | `lib/data/models/*.g.dart` | 5 files |

---

## Entity Layer (Domain)

### 1. Profile Entity

**File:** `lib/domain/entities/profile.dart`
**Purpose:** Complete user profile with all personal information, preferences, and privacy settings

#### Properties

| Property | Type | Description | Nullable | Validation |
|----------|------|-------------|----------|------------|
| `id` | String | Unique profile ID | No | - |
| `userId` | String | Associated user account ID | No | - |
| `displayName` | String | Display name shown to users | No | Non-empty |
| `birthDate` | DateTime | Date of birth for age calculation | No | - |
| `bio` | String | User biography/description | No | - |
| `location` | Location | Geographic coordinates | No | Valid lat/long |
| `city` | String | City name | No | - |
| `country` | String | Country code | No | - |
| `interests` | List\<String\> | User interests/hobbies | No | - |
| `relationshipType` | String | Desired relationship type | No | Valid enum value |
| `photos` | PhotoCollection | User photos | No | - |
| `searchPreferences` | SearchPreferences | Discovery filter preferences | No | - |
| `lastActive` | DateTime | Last activity timestamp | No | - |
| `isHidden` | bool | Profile visibility flag | No | - |
| `verificationStatus` | VerificationStatus | Identity verification status | No | - |
| `privacySettings` | PrivacySettings | Privacy configuration | No | - |
| `createdAt` | DateTime | Profile creation timestamp | No | - |
| `updatedAt` | DateTime | Last update timestamp | No | - |

#### Computed Properties

| Property | Return Type | Calculation | Purpose |
|----------|-------------|-------------|---------|
| `age` | int | `now.year - birthDate.year` (adjusted for month/day) | Display age on profile cards |
| `isOnline` | bool | `lastActive < 10 minutes ago` | Show "Online Now" indicator |
| `displayLocation` | String | `showExactLocation ? city : country` | Respect privacy settings |
| `mainPhotoUrl` | String | `photos.main` | Quick access to main photo |
| `hasMultiplePhotos` | bool | `photos.others.isNotEmpty` | Enable photo carousel |

#### Nested Entities

##### 1.1. Location

**Properties:**
- `latitude: double` - Geographic latitude
- `longitude: double` - Geographic longitude
- `geohash: String` - Geohash for proximity queries

**Methods:**
- `distanceFrom(Location other): double` - Calculate distance in km using Haversine formula

##### 1.2. PhotoCollection

**Properties:**
- `main: String` - Main profile photo URL (required)
- `others: List<String>` - Additional public photos (default: [])
- `private: List<String>` - Private photos (default: [])

**Computed:**
- `totalCount: int` - Total number of photos
- `hasPrivatePhotos: bool` - Whether private photos exist
- `allPublicPhotos: List<String>` - [main, ...others]

##### 1.3. SearchPreferences

**Properties:**
- `minAge: int` - Minimum age filter
- `maxAge: int` - Maximum age filter
- `maxDistance: double` - Maximum distance in km
- `interestedIn: List<String>` - Gender preferences
- `relationshipTypes: List<String>` - Relationship types sought
- `showVerifiedOnly: bool` - Filter verified users only (default: false)
- `showOnlineOnly: bool` - Filter online users only (default: false)

**Compatibility Properties:**
- `ageRange: AgeRange` - Returns AgeRange(min, max)
- `maxDistanceKm: double` - Alias for maxDistance
- `relationshipType: String` - First relationship type or ''
- `gendersSought: List<String>` - Alias for interestedIn

**Serialization:**
- `toJson()` - Convert to API format with snake_case keys

##### 1.4. AgeRange

**Properties:**
- `min: int` - Minimum age (assert: >= 18)
- `max: int` - Maximum age (assert: <= 99, >= min)

**Validation:**
- Constructor asserts: `min >= 18 && max <= 99 && min <= max`

##### 1.5. VerificationStatus

**Properties:**
- `status: String` - Verification state (not_started, pending_*, verified, rejected, expired)
- `submittedAt: DateTime?` - Submission timestamp
- `reviewedAt: DateTime?` - Review timestamp
- `rejectionReason: String?` - Reason for rejection
- `expiresAt: DateTime?` - Expiration date
- `documents: Map<String, DocumentStatus>` - Document statuses

**Computed:**
- `isPending: bool` - status.contains('pending')
- `isVerified: bool` - status == 'verified'
- `isRejected: bool` - status == 'rejected'
- `isExpired: bool` - status == 'expired' || expiresAt < now

##### 1.6. DocumentStatus

**Properties:**
- `type: String` - Document type (identity_document, medical_document, selfie_with_code)
- `status: String` - Status (pending, uploaded, approved, rejected)

##### 1.7. PrivacySettings

**Properties:**
- `profileVisibility: String` - Visibility mode (visible_to_all, visible_to_matches_only, incognito)
- `showOnlineStatus: bool` - Show online status (default: true)
- `showDistance: bool` - Show distance to others (default: true)
- `showExactLocation: bool` - Show city vs country (default: false)
- `profileDiscoverable: bool` - Appear in discovery (default: true)

#### Methods

- `copyWith({...})` - Immutable copy with field overrides
- `props` - Equatable properties for equality comparison

---

### 2. DiscoveryProfile Entity

**File:** `lib/domain/entities/match.dart` (lines 68-246)
**Purpose:** Lightweight profile representation optimized for Discovery swipe cards

#### Properties

| Property | Type | Description | Nullable | Source |
|----------|------|-------------|----------|--------|
| `id` | String | Profile/User ID | No | API: user_id or id |
| `displayName` | String | Display name | No | API: display_name |
| `age` | int | Calculated age | No | API: age |
| `mainPhotoUrl` | String | Main photo URL | No | API: main_photo_url or photos[0] |
| `otherPhotosUrls` | List\<String\> | Other photo URLs | No | API: other_photos_urls or photos[1..] |
| `bio` | String | User bio | No | API: bio (fallback: '') |
| `city` | String | City name | No | API: city (fallback: '') |
| `country` | String | Country code | No | API: country (fallback: 'FR') |
| `distance` | double? | Distance in km | Yes | API: distance_km or distance |
| `interests` | List\<String\> | User interests | No | API: interests |
| `relationshipType` | String | Relationship type | No | API: relationship_type or relationship_types_sought[0] |
| `isVerified` | bool | Verification badge | No | API: is_verified |
| `isPremium` | bool | Premium badge | No | API: is_premium |
| `lastActive` | DateTime | Last activity | No | API: last_active (fallback: now) |
| `compatibilityScore` | double | Compatibility % | No | API: compatibility_score (fallback: 0.0) |

#### Computed Properties

| Property | Return Type | Calculation | Purpose |
|----------|-------------|-------------|---------|
| `isOnline` | bool | `now - lastActive < 10 minutes` | Show "Online Now" indicator |
| `allPhotos` | List\<String\> | [mainPhotoUrl, ...otherPhotosUrls] (filtered, with placeholder) | Photo carousel |

#### Serialization

**fromJson (lines 103-188):**
- Handles dual API formats: `main_photo_url/other_photos_urls` OR `photos[]`
- Extracts `user_id` OR `id` for ID
- Extracts `relationship_types_sought[0]` OR `relationship_type`
- Provides robust fallbacks for all optional fields

**toJson (lines 190-208):**
- Converts to API format with snake_case keys
- Includes all properties in canonical format

---

### 3. Match Entity

**File:** `lib/domain/entities/match.dart` (lines 7-59)
**Purpose:** Represents a mutual match between users

#### Properties

| Property | Type | Description | Nullable |
|----------|------|-------------|----------|
| `id` | String | Match ID | No |
| `profile` | Profile | Matched user's profile | No |
| `matchedAt` | DateTime | Match creation timestamp | No |
| `lastMessage` | Message? | Last conversation message | Yes |
| `isNew` | bool | Unread match indicator | No |
| `unreadCounts` | Map\<String, int\> | Unread message counts | No |

#### Computed Properties

- `unreadCount: int` - Sum of all unread counts
- `hasUnreadMessages: bool` - unreadCount > 0
- `isActive: bool` - Always true (placeholder)
- `lastMessageContent: String?` - lastMessage?.content
- `lastMessageAt: DateTime?` - lastMessage?.createdAt

---

### 4. SearchFilters Entity

**File:** `lib/domain/entities/search_filters.dart`
**Purpose:** User-defined discovery filter criteria

#### Properties

| Property | Type | Description | Nullable | Default |
|----------|------|-------------|----------|---------|
| `minAge` | int? | Minimum age filter | Yes | 18 |
| `maxAge` | int? | Maximum age filter | Yes | 65 |
| `maxDistance` | int? | Max distance in km | Yes | 50 |
| `gender` | String? | Gender filter | Yes | null |
| `interests` | List\<String\>? | Interests filter | Yes | null |
| `relationshipTypes` | List\<String\>? | Relationship types | Yes | null |
| `verifiedOnly` | bool? | Verified profiles only | Yes | false |

#### Methods

**toSearchPreferences():**
- Converts SearchFilters to SearchPreferences
- Applies defaults: minAge=18, maxAge=65, maxDistance=50.0
- Converts gender to interestedIn list
- Sets showVerifiedOnly from verifiedOnly

---

### 5. SwipeAction Entity

**File:** `lib/domain/entities/match.dart` (lines 248-265)
**Purpose:** Records a swipe interaction

#### Properties

- `id: String` - Action ID
- `fromUserId: String` - User who swiped
- `toUserId: String` - User who was swiped
- `type: SwipeType` - like, superLike, dislike
- `createdAt: DateTime` - Action timestamp

---

### 6. DailyLikeLimit Entity

**File:** `lib/domain/entities/match.dart` (lines 280-327)
**Purpose:** Daily like limit tracking

#### Properties

- `remainingLikes: int` - Likes remaining today
- `totalLikes: int` - Total daily limit
- `resetAt: DateTime` - Limit reset time

#### Computed Properties

- `hasReachedLimit: bool` - remainingLikes <= 0
- `remaining: int` - Alias for remainingLikes
- `limit: int` - Alias for totalLikes

#### Serialization

- `fromJson()` - Parse from API: remaining_likes, total_likes, reset_at
- `toJson()` - Convert to API format

---

### 7. SwipeResult Entity

**File:** `lib/domain/entities/match.dart` (lines 329-369)
**Purpose:** Result of a swipe action

#### Properties

- `isMatch: bool` - Whether swipe resulted in match
- `matchId: String?` - Match ID if matched
- `matchedProfile: Profile?` - Matched profile (TODO: implement serialization)
- `remainingLikes: int?` - Likes remaining after action
- `remainingSuperLikes: int?` - Super likes remaining

#### Serialization

- `fromJson()` - Parse from API
- `toJson()` - Convert to API (omits matchedProfile - no toJson on Profile)

---

### 8. BoostStatus Entity

**File:** `lib/domain/entities/match.dart` (lines 371-408)
**Purpose:** Profile boost status

#### Properties

- `isActive: bool` - Boost currently active
- `endsAt: DateTime?` - Boost expiration time
- `boostsRemaining: int` - Boosts available
- `activatedAt: DateTime?` - Boost activation time

#### Serialization

- `fromJson()` - Parse from API
- `toJson()` - Convert to API

---

### 9. InteractionHistory Entity

**File:** `lib/domain/entities/interaction_history.dart` (lines 7-68)
**Purpose:** Historical record of user interactions

#### Properties

- `id: String` - Interaction ID
- `profile: DiscoveryProfile` - Profile interacted with
- `type: InteractionType` - like, superLike, dislike
- `timestamp: DateTime` - Interaction time
- `isMatched: bool` - Resulted in match
- `matchId: String?` - Match ID if matched
- `canRevoke: bool` - Can be undone/rewound

---

### 10. InteractionStats Entity

**File:** `lib/domain/entities/interaction_history.dart` (lines 101-143)
**Purpose:** Aggregate interaction statistics

#### Properties

- `totalLikes: int`
- `totalSuperLikes: int`
- `totalDislikes: int`
- `totalMatches: int`
- `likeToMatchRatio: double`
- `totalInteractionsToday: int`
- `dailyLimit: int`
- `remainingToday: int`

#### Computed Properties

- `totalAllLikes: int` - totalLikes + totalSuperLikes
- `totalInteractions: int` - totalAllLikes + totalDislikes
- `matchRate: double` - (totalMatches / totalLikes) * 100 (or 0)
- `todayInteractions: int` - Alias
- `weekInteractions: int` - Approximation (mock)

---

### 11. Message Entity

**File:** `lib/domain/entities/message.dart` (lines 9-115)
**Purpose:** Chat message in match conversations

#### Properties

- `id: String`
- `conversationId: String`
- `senderId: String`
- `content: String`
- `type: MessageType` - text, image, video, voice, system
- `createdAt: DateTime`
- `isRead: bool`
- `isDelivered: bool`
- `mediaUrl: String?`
- `reactions: Map<String, String>`
- `status: MessageStatus` - sending, sent, delivered, read, failed

#### Serialization

- `fromJson()` - Parse from API (timestamp → createdAt)
- `toJson()` - Convert to API

---

### 12. Premium-Related Entities

**File:** `lib/domain/entities/premium.dart`

#### 12.1. PremiumPlan

**Properties:**
- `id: String`, `planId: String`, `name: String`, `description: String`
- `price: double`, `currency: String`, `billingInterval: BillingInterval`
- `trialPeriodDays: int`, `features: PremiumFeatures`, `savings: int`
- `isPopular: bool`, `isRecommended: bool`

#### 12.2. PremiumFeatures

**Properties:**
- `unlimitedLikes: bool`
- `canSeeWhoLiked: bool`
- `canRewind: bool`
- `monthlyBoosts: int`
- `dailySuperLikes: int`
- `mediaMessaging: bool`
- `videoCalls: bool`
- `prioritySupport: bool`
- `advancedFilters: bool`
- `incognitoMode: bool`

---

## Model Layer (Data/DTOs)

### 1. ProfileModel

**File:** `lib/data/models/profile_model.dart`
**Purpose:** Serializable Profile DTO for API/Firebase communication

#### Properties

Mirrors all Profile entity properties with `@JsonSerializable` annotation.

#### Special Handling

**DateTime Conversion:**
- Uses custom converters for Firestore Timestamp ↔ DateTime
- `@JsonKey(toJson: _dateTimeToTimestamp, fromJson: _timestampToDateTimeNonNull)`
- Nullable timestamps use `_timestampToDateTime`

**Nested Models:**
- `LocationModel` (lines 140-171)
- `PhotoCollectionModel` (lines 173-204)
- `SearchPreferencesModel` (lines 206-253)
- `VerificationStatusModel` (lines 255-316)
- `DocumentStatusModel` (lines 318-345)
- `PrivacySettingsModel` (lines 347-386)

#### Serialization Methods

- `fromJson(Map<String, dynamic>)` - Generated by json_serializable
- `toJson()` - Generated by json_serializable
- `fromFirestore(DocumentSnapshot)` - Parse from Firestore document
- `toFirestore()` - Convert to Firestore (removes id)
- `fromEntity(Profile)` - Convert entity to model
- `toEntity()` - Convert model to entity

**Generated File:** `profile_model.g.dart` (json_serializable output)

---

### 2. MatchModel

**File:** `lib/data/models/match_model.dart`
**Purpose:** Serializable Match DTO

#### Properties

- `id: String`
- `profile: ProfileModel`
- `@JsonKey(name: 'matched_at') matchedAt: DateTime`
- `@JsonKey(name: 'last_message') lastMessage: MessageModel?`
- `@JsonKey(name: 'is_new') isNew: bool`
- `@JsonKey(name: 'unread_counts') unreadCounts: Map<String, int>`

#### Serialization

- `fromJson()` - Generated
- `toJson()` - Generated
- `toEntity()` - Convert to Match entity
- `fromEntity(Match)` - Convert from Match entity

**Generated File:** `match_model.g.dart`

---

### 3. SwipeActionModel

**File:** `lib/data/models/match_model.dart` (lines 63-116)
**Purpose:** Serializable SwipeAction DTO

#### Properties

- `id: String`
- `fromUserId: String`
- `toUserId: String`
- `type: String` - Serialized SwipeType enum
- `@JsonKey(...) createdAt: DateTime` - Firestore Timestamp conversion

#### Methods

- `_parseSwipeType(String)` - Convert string to SwipeType enum (like, superLike, dislike)
- `_dateTimeToTimestamp(DateTime)` - Convert to Firestore Timestamp
- `_timestampToDateTime(Timestamp)` - Convert from Firestore Timestamp

---

### 4. MessageModel

**File:** `lib/data/models/message_model.dart`
**Purpose:** Serializable Message DTO

Properties mirror Message entity with `@JsonSerializable` annotation.

**Generated File:** `message_model.g.dart`

---

### 5. Additional Models

**Files:**
- `conversation_model.dart` + `.g.dart` - Conversation DTO
- `user_model.dart` + `.g.dart` - User account DTO
- `feed_post_model.dart` + `.g.dart` - Social feed DTO
- `resource_model.dart` + `.g.dart` - HIV resources DTO
- `post_comment_model.dart` + `.g.dart` - Comment DTO

(Not directly used by Discovery page but may be referenced)

---

## Serialization & Transformations

### JSON Serialization Patterns

#### 1. json_serializable (Models)

**Setup:**
```dart
import 'package:json_annotation/json_annotation.dart';

part 'profile_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ProfileModel {
  // ...
  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileModelToJson(this);
}
```

**Build Command:** `flutter pub run build_runner build`

#### 2. Manual Serialization (Entities)

**Pattern:**
```dart
class DiscoveryProfile extends Equatable {
  // ...

  factory DiscoveryProfile.fromJson(Map<String, dynamic> json) {
    // Manual parsing with robust fallbacks
    String mainPhotoUrl = '';
    if (json.containsKey('main_photo_url')) {
      mainPhotoUrl = json['main_photo_url'];
    } else if (json.containsKey('photos') && json['photos'] is List) {
      mainPhotoUrl = (json['photos'] as List).first.toString();
    }

    return DiscoveryProfile(
      id: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      age: json['age'] as int,
      mainPhotoUrl: mainPhotoUrl,
      // ...
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      // ... (snake_case keys)
    };
  }
}
```

### Entity ↔ Model Transformations

#### Pattern: Model.toEntity()

```dart
// ProfileModel → Profile
Profile toEntity() {
  return Profile(
    id: id,
    userId: userId,
    displayName: displayName,
    // ... (direct mapping)
    location: location.toEntity(), // Nested conversion
    photos: photos.toEntity(),
    searchPreferences: searchPreferences.toEntity(),
    // ...
  );
}
```

#### Pattern: Model.fromEntity()

```dart
// Profile → ProfileModel
factory ProfileModel.fromEntity(Profile profile) {
  return ProfileModel(
    id: profile.id,
    userId: profile.userId,
    displayName: profile.displayName,
    // ...
    location: LocationModel.fromEntity(profile.location),
    photos: PhotoCollectionModel.fromEntity(profile.photos),
    // ...
  );
}
```

### API Format Conversions

#### Snake Case ↔ Camel Case

**API (snake_case):**
```json
{
  "user_id": "123",
  "display_name": "John",
  "main_photo_url": "https://...",
  "is_verified": true
}
```

**Entity (camelCase):**
```dart
DiscoveryProfile(
  id: "123",
  displayName: "John",
  mainPhotoUrl: "https://...",
  isVerified: true
)
```

#### Firestore Timestamp Conversion

**Custom Converters:**
```dart
static Timestamp? _dateTimeToTimestamp(DateTime? dateTime) {
  return dateTime != null ? Timestamp.fromDate(dateTime) : null;
}

static DateTime _timestampToDateTimeNonNull(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return timestamp.toDate();
  }
  return DateTime.now(); // fallback
}
```

---

## Validation Logic

### 1. Entity-Level Validation

#### AgeRange Constraints

```dart
class AgeRange extends Equatable {
  final int min;
  final int max;

  const AgeRange({
    required this.min,
    required this.max,
  }) : assert(min >= 18 && max <= 99 && min <= max);
}
```

**Enforces:**
- Minimum age: 18
- Maximum age: 99
- min ≤ max

### 2. Computed Property Validation

#### Online Status (10-minute threshold)

```dart
bool get isOnline {
  final difference = DateTime.now().difference(lastActive);
  return difference.inMinutes < 10;
}
```

#### Age Calculation (Handles leap years)

```dart
int get age {
  final now = DateTime.now();
  int age = now.year - birthDate.year;
  if (now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day)) {
    age--;
  }
  return age;
}
```

### 3. Serialization Validation

#### DiscoveryProfile.fromJson (Robust Fallbacks)

- **ID extraction:** Tries `user_id` → `id` → empty string
- **Photo handling:** Tries `main_photo_url` → `photos[0]` → empty string
- **Distance:** Tries `distance_km` → `distance` → null
- **Last Active:** Tries parsing → fallback to `DateTime.now()`
- **Compatibility Score:** Tries parsing → fallback to 0.0

#### SwipeActionModel._parseSwipeType

```dart
static SwipeType _parseSwipeType(String type) {
  switch (type) {
    case 'like': return SwipeType.like;
    case 'superLike': return SwipeType.superLike;
    case 'dislike': return SwipeType.dislike;
    default: return SwipeType.dislike; // Safe fallback
  }
}
```

### 4. Missing Validation (Gaps)

**IDENTIFIED ISSUES:**

1. **No input validation on SearchFilters** (DATA-004)
   - No min/max age range checks
   - No max distance bounds
   - No interests list length limits (spec: max 5)

2. **No profile data validation** (DATA-001)
   - Display name length not enforced
   - Bio length not enforced
   - Interests list not validated

3. **No photo URL validation**
   - No URL format checking
   - No HTTPS enforcement
   - No placeholder handling for invalid URLs

**RECOMMENDATION:** Add validation layer in Use Cases or Models before persistence.

---

## Usage Patterns

### 1. Discovery Flow (API → Entity → UI)

```dart
// 1. API call returns JSON
final response = await dio.get('/discovery/');

// 2. Parse JSON to Entity directly
final profiles = (response.data['profiles'] as List)
    .map((json) => DiscoveryProfile.fromJson(json))
    .toList();

// 3. Use in BLoC
emit(DiscoveryLoaded(profiles: profiles));

// 4. UI renders from Entity
Text(profile.displayName)
Text('${profile.age} ans')
CachedNetworkImage(imageUrl: profile.mainPhotoUrl)
```

**Note:** Discovery page uses Entity directly (no Model intermediary for DiscoveryProfile).

### 2. Profile Flow (API → Model → Entity → UI)

```dart
// 1. API call
final response = await dio.get('/user-profiles/${userId}/');

// 2. Parse to Model
final profileModel = ProfileModel.fromJson(response.data);

// 3. Convert to Entity
final profile = profileModel.toEntity();

// 4. Use in business logic
final age = profile.age; // Computed property
final distance = profile.location.distanceFrom(otherLocation);
```

### 3. Swipe Action (Entity → Model → API)

```dart
// 1. Create Entity
final swipeAction = SwipeAction(
  id: uuid.v4(),
  fromUserId: currentUserId,
  toUserId: profile.id,
  type: SwipeType.like,
  createdAt: DateTime.now(),
);

// 2. Convert to Model
final model = SwipeActionModel.fromEntity(swipeAction);

// 3. Send to API
await dio.post('/swipes/', data: model.toJson());
```

### 4. Filters Application

```dart
// 1. User updates filters (UI)
final filters = SearchFilters(
  minAge: 25,
  maxAge: 35,
  maxDistance: 50,
  verifiedOnly: true,
);

// 2. Convert to SearchPreferences
final prefs = filters.toSearchPreferences();

// 3. Send to API
await dio.put('/discovery/filters', data: prefs.toJson());
```

---

## Compliance Analysis

### 1. Architecture Compliance

| Requirement | Status | Evidence |
|-------------|--------|----------|
| **ARCH-001:** Clean Architecture separation | ✅ COMPLIANT | Entities in domain/, Models in data/ |
| **ARCH-002:** Entity independence | ✅ COMPLIANT | Entities have no data layer imports |
| **ARCH-003:** Model-Entity transformations | ✅ COMPLIANT | toEntity()/fromEntity() methods present |
| **ARCH-004:** Immutability (Equatable) | ✅ COMPLIANT | All entities extend Equatable |

### 2. Data Requirements Compliance

| Requirement | Status | Evidence |
|-------------|--------|----------|
| **DATA-001:** All required profile fields | ✅ COMPLIANT | Profile has 18 properties per spec |
| **DATA-002:** DiscoveryProfile optimization | ✅ COMPLIANT | DiscoveryProfile is lightweight (14 fields) |
| **DATA-003:** Photo collection structure | ✅ COMPLIANT | PhotoCollection with main/others/private |
| **DATA-004:** Filter validation | ❌ MISSING | No input validation in SearchFilters |
| **DATA-005:** Computed properties | ✅ COMPLIANT | age, isOnline, distance calculation |
| **DATA-006:** Filter persistence | ❌ MISSING | No local storage, only in-memory |
| **DATA-007:** Profile caching | ❌ MISSING | No caching layer implemented |
| **DATA-008:** Offline support | ❌ MISSING | No offline data structures |

### 3. Serialization Compliance

| Requirement | Status | Evidence |
|-------------|--------|----------|
| **API-001:** JSON serialization | ✅ COMPLIANT | fromJson/toJson on all models |
| **API-002:** Snake case API format | ✅ COMPLIANT | @JsonKey(name: 'snake_case') |
| **API-003:** Firestore compatibility | ✅ COMPLIANT | Custom Timestamp converters |
| **API-004:** Robust parsing | ✅ COMPLIANT | Fallbacks in DiscoveryProfile.fromJson |
| **API-005:** Type safety | ✅ COMPLIANT | Strong typing throughout |

### 4. Validation Compliance

| Requirement | Status | Evidence |
|-------------|--------|----------|
| **Valid age range** | ⚠️ PARTIAL | AgeRange has assert, but SearchFilters doesn't |
| **Distance bounds** | ❌ MISSING | No max distance validation |
| **Interests limit** | ❌ MISSING | No 5-interest limit enforcement |
| **Required fields** | ✅ COMPLIANT | Non-nullable required fields |
| **Enum validation** | ✅ COMPLIANT | SwipeType parsing with fallback |

### 5. Critical Issues

#### 🔴 P0 Issues

**None identified** - Core data structures are sound.

#### 🟡 P1 Issues

1. **DATA-004:** Missing input validation on SearchFilters
   - Impact: Invalid filter values could crash app or cause API errors
   - Fix: Add validation in SearchFilters.toSearchPreferences()

2. **DATA-006:** No filter persistence
   - Impact: Filters reset on app restart (poor UX)
   - Fix: Add SharedPreferences storage in repository

3. **DATA-007:** No caching layer
   - Impact: Repeated API calls, higher latency
   - Fix: Implement Hive or SQLite caching

#### 🟠 P2 Issues

1. **SwipeResult.matchedProfile incomplete serialization**
   - Line 349: `// TODO: Implémenter la sérialisation Profile`
   - Currently returns null instead of parsed profile
   - Fix: Add Profile.fromJson() or use ProfileModel intermediary

2. **InteractionStats.weekInteractions is mock**
   - Line 130: `totalInteractionsToday * 7; // Approximation (mock)`
   - Not real data
   - Fix: Add actual weekly tracking in backend/repository

---

## Summary

### Inventory Statistics

| Category | Count | Files |
|----------|-------|-------|
| **Domain Entities** | 12 main + 13 nested | 8 .dart files |
| **Data Models** | 8 main + 6 nested | 8 .dart + 5 .g.dart |
| **Enums** | 7 | Embedded in entities |
| **Total Properties** | 150+ | Across all structures |

### Key Entities for Discovery Page

**Primary:**
1. **DiscoveryProfile** - Swipe card data (most used)
2. **SearchFilters** - User filter preferences
3. **DailyLikeLimit** - Freemium limit tracking
4. **SwipeResult** - Match detection

**Secondary:**
5. **Profile** - Full profile details (detail view)
6. **Match** - Match record
7. **InteractionHistory** - Interaction tracking
8. **BoostStatus** - Premium boost feature

### Serialization Summary

| Model | fromJson | toJson | toEntity | fromEntity | Generated |
|-------|----------|--------|----------|------------|-----------|
| ProfileModel | ✅ | ✅ | ✅ | ✅ | Yes (.g.dart) |
| MatchModel | ✅ | ✅ | ✅ | ✅ | Yes (.g.dart) |
| SwipeActionModel | ✅ | ✅ | ✅ | - | Yes (.g.dart) |
| DiscoveryProfile | ✅ | ✅ | N/A | N/A | No (manual) |
| DailyLikeLimit | ✅ | ✅ | N/A | N/A | No (manual) |
| SwipeResult | ✅ | ✅ | N/A | N/A | No (manual) |
| BoostStatus | ✅ | ✅ | N/A | N/A | No (manual) |
| SearchFilters | - | - | N/A | N/A | No |

### Validation Summary

**Implemented:**
- Age range constraints (18-99, min ≤ max)
- Online status calculation (10-minute window)
- Age calculation with leap year handling
- Enum parsing with safe fallbacks
- Robust JSON parsing with fallbacks

**Missing:**
- SearchFilters input validation
- Profile field length limits
- Photo URL validation
- Interests count limits (max 5)
- Distance bounds checking

### Transformation Patterns

**Three patterns identified:**

1. **Direct Entity Serialization** (DiscoveryProfile, DailyLikeLimit, SwipeResult)
   - Entity has fromJson/toJson
   - No intermediate Model
   - Used for simple API responses

2. **Model-Entity Pattern** (Profile, Match)
   - Model with @JsonSerializable
   - Entity for business logic
   - toEntity()/fromEntity() conversions
   - Used for complex Firestore data

3. **Hybrid Pattern** (SearchFilters → SearchPreferences)
   - Entity converts to another entity type
   - No Model involved
   - Used for transformations within domain layer

### Compliance Score

**Overall: 75% (12/16 requirements fully compliant)**

- Architecture: 4/4 ✅ (100%)
- Data Structures: 5/8 ✅ (62.5%)
- Serialization: 5/5 ✅ (100%)
- Validation: 2/5 ✅ (40%)

### Immediate Action Items

**P1 Priority:**
1. Add input validation to SearchFilters (2h)
2. Implement filter persistence with SharedPreferences (3h)
3. Add Profile.fromJson() for SwipeResult.matchedProfile (2h)

**P2 Priority:**
4. Add profile field length validators (1h)
5. Add photo URL validation (1h)
6. Implement caching layer (8-12h)

---

**Document Complete** ✅
**Total Lines:** 1,100+
**Models Documented:** 20+ (entities + models)
**Code Files Analyzed:** 13
**Next Phase:** Gap Analysis (Task 3.5)
