# Data Models Tests

## Overview

This directory contains comprehensive unit tests for all data models used in the HIVMeet application, with a focus on Discovery page related models.

## Test Coverage

### 1. ProfileModel Tests (`profile_model_test.dart`)
**Lines:** 733 | **Test Cases:** 41 | **Groups:** 7

Tests cover:
- **ProfileModel**: Serialization, deserialization, entity conversion, Firestore integration
- **LocationModel**: JSON operations, entity conversion, edge case coordinates
- **PhotoCollectionModel**: Empty arrays, missing fields, default values
- **SearchPreferencesModel**: Age range validation, boolean defaults, entity conversion
- **VerificationStatusModel**: Status variations, null fields, document handling
- **DocumentStatusModel**: Type and status combinations, entity conversion
- **PrivacySettingsModel**: Visibility modes, default values, entity conversion

### 2. MatchModel Tests (`match_model_test.dart`)
**Lines:** 373 | **Test Cases:** 18 | **Groups:** 2

Tests cover:
- **MatchModel**: Match data serialization, profile embedding, message handling
- **SwipeActionModel**: Swipe type parsing, timestamp handling, entity conversion

### 3. MessageModel Tests (`message_model_test.dart`)
**Lines:** 296 | **Test Cases:** 16 | **Groups:** 1

Tests cover:
- Message type variations (text, image, video, audio)
- Message status transitions (sent, delivered, read, failed)
- Reactions map handling
- Media URLs validation
- Content edge cases (empty, long, special characters)

### 4. UserModel Tests (`user_model_test.dart`)
**Lines:** 423 | **Test Cases:** 21 | **Groups:** 2

Tests cover:
- **UserModel**: Premium status, blocked users, verification states
- **NotificationSettingsModel**: All notification preferences, defaults

## Test Categories

All model tests verify:

### ✅ Serialization & Deserialization
- `fromJson()` correctly parses JSON to model
- `toJson()` correctly converts model to JSON
- Round-trip reversibility (fromJson → toJson → fromJson)

### ✅ Entity Conversion
- `toEntity()` converts model to domain entity
- `fromEntity()` converts domain entity to model
- Bidirectional conversion preserves data

### ✅ Edge Cases
- Null/optional fields
- Empty collections
- Default values
- Missing fields
- Invalid data gracefully handled

### ✅ Business Logic
- Computed properties (age, isOnline, etc.)
- Validation rules (age ranges, coordinates)
- Type parsing (enums, statuses)

### ✅ Data Integrity
- Timestamp precision
- Special characters in strings
- Long content handling
- Collection operations

## Running Tests

```bash
# Run all model tests
flutter test test/data/models/

# Run specific model test
flutter test test/data/models/profile_model_test.dart

# Run with coverage
flutter test --coverage test/data/models/
```

## Test Statistics

| File | Lines | Test Cases | Groups | Coverage Area |
|------|-------|------------|--------|---------------|
| profile_model_test.dart | 733 | 41 | 7 | Profile and all nested models |
| match_model_test.dart | 373 | 18 | 2 | Match and SwipeAction models |
| message_model_test.dart | 296 | 16 | 1 | Message model |
| user_model_test.dart | 423 | 21 | 2 | User and NotificationSettings |
| **TOTAL** | **1825** | **96** | **12** | **All data models** |

## Dependencies

- `flutter_test`: Testing framework
- `cloud_firestore`: Timestamp handling (mocked)
- `equatable`: Entity equality testing

## Notes

- All tests follow the Arrange-Act-Assert pattern
- Tests are isolated and can run in any order
- Mock data uses realistic values
- Edge cases cover boundary conditions
- Comprehensive validation of all model properties
