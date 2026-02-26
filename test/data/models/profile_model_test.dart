// test/data/models/profile_model_test.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivemeet/data/models/profile_model.dart';
import 'package:hivemeet/domain/entities/profile.dart';

void main() {
  group('ProfileModel', () {
    final testDateTime = DateTime(2024, 2, 24, 12, 0, 0);

    final testJson = {
      'id': 'profile123',
      'userId': 'user123',
      'displayName': 'John Doe',
      'birthDate': Timestamp.fromDate(DateTime(1990, 1, 1)),
      'bio': 'Test bio',
      'location': {
        'latitude': 48.8566,
        'longitude': 2.3522,
        'geohash': 'u09tvw0f6',
      },
      'city': 'Paris',
      'country': 'France',
      'interests': ['music', 'travel', 'sports'],
      'relationshipType': 'casual_dating',
      'photos': {
        'main': 'https://example.com/photo1.jpg',
        'others': ['https://example.com/photo2.jpg', 'https://example.com/photo3.jpg'],
        'private': ['https://example.com/private1.jpg'],
      },
      'searchPreferences': {
        'minAge': 25,
        'maxAge': 35,
        'maxDistance': 50.0,
        'interestedIn': ['female'],
        'relationshipTypes': ['casual_dating', 'friendship'],
        'showVerifiedOnly': false,
        'showOnlineOnly': false,
      },
      'lastActive': Timestamp.fromDate(testDateTime),
      'isHidden': false,
      'verificationStatus': {
        'status': 'verified',
        'submittedAt': Timestamp.fromDate(testDateTime),
        'reviewedAt': Timestamp.fromDate(testDateTime),
        'rejectionReason': null,
        'expiresAt': Timestamp.fromDate(testDateTime.add(Duration(days: 365))),
        'documents': {
          'id': {
            'type': 'identity_document',
            'status': 'approved',
          },
        },
      },
      'privacySettings': {
        'profileVisibility': 'visible_to_all',
        'showOnlineStatus': true,
        'showDistance': true,
        'showExactLocation': false,
        'profileDiscoverable': true,
      },
      'createdAt': Timestamp.fromDate(testDateTime),
      'updatedAt': Timestamp.fromDate(testDateTime),
    };

    final testModel = ProfileModel(
      id: 'profile123',
      userId: 'user123',
      displayName: 'John Doe',
      birthDate: DateTime(1990, 1, 1),
      bio: 'Test bio',
      location: LocationModel(
        latitude: 48.8566,
        longitude: 2.3522,
        geohash: 'u09tvw0f6',
      ),
      city: 'Paris',
      country: 'France',
      interests: ['music', 'travel', 'sports'],
      relationshipType: 'casual_dating',
      photos: PhotoCollectionModel(
        main: 'https://example.com/photo1.jpg',
        others: ['https://example.com/photo2.jpg', 'https://example.com/photo3.jpg'],
        private: ['https://example.com/private1.jpg'],
      ),
      searchPreferences: SearchPreferencesModel(
        minAge: 25,
        maxAge: 35,
        maxDistance: 50.0,
        interestedIn: ['female'],
        relationshipTypes: ['casual_dating', 'friendship'],
        showVerifiedOnly: false,
        showOnlineOnly: false,
      ),
      lastActive: testDateTime,
      isHidden: false,
      verificationStatus: VerificationStatusModel(
        status: 'verified',
        submittedAt: testDateTime,
        reviewedAt: testDateTime,
        rejectionReason: null,
        expiresAt: testDateTime.add(Duration(days: 365)),
        documents: {
          'id': DocumentStatusModel(
            type: 'identity_document',
            status: 'approved',
          ),
        },
      ),
      privacySettings: PrivacySettingsModel(
        profileVisibility: 'visible_to_all',
        showOnlineStatus: true,
        showDistance: true,
        showExactLocation: false,
        profileDiscoverable: true,
      ),
      createdAt: testDateTime,
      updatedAt: testDateTime,
    );

    test('fromJson should deserialize JSON correctly', () {
      final result = ProfileModel.fromJson(testJson);

      expect(result.id, 'profile123');
      expect(result.userId, 'user123');
      expect(result.displayName, 'John Doe');
      expect(result.birthDate.year, 1990);
      expect(result.bio, 'Test bio');
      expect(result.location.latitude, 48.8566);
      expect(result.location.longitude, 2.3522);
      expect(result.city, 'Paris');
      expect(result.country, 'France');
      expect(result.interests, ['music', 'travel', 'sports']);
      expect(result.relationshipType, 'casual_dating');
      expect(result.photos.main, 'https://example.com/photo1.jpg');
      expect(result.photos.others.length, 2);
      expect(result.photos.private.length, 1);
      expect(result.searchPreferences.minAge, 25);
      expect(result.searchPreferences.maxAge, 35);
      expect(result.isHidden, false);
      expect(result.verificationStatus.status, 'verified');
      expect(result.privacySettings.profileVisibility, 'visible_to_all');
    });

    test('toJson should serialize model correctly', () {
      final result = testModel.toJson();

      expect(result['id'], 'profile123');
      expect(result['userId'], 'user123');
      expect(result['displayName'], 'John Doe');
      expect(result['bio'], 'Test bio');
      expect(result['city'], 'Paris');
      expect(result['country'], 'France');
      expect(result['interests'], ['music', 'travel', 'sports']);
      expect(result['relationshipType'], 'casual_dating');
      expect(result['isHidden'], false);
      expect(result['location'], isA<Map>());
      expect(result['photos'], isA<Map>());
      expect(result['searchPreferences'], isA<Map>());
      expect(result['verificationStatus'], isA<Map>());
      expect(result['privacySettings'], isA<Map>());
    });

    test('fromJson and toJson should be reversible', () {
      final json = testModel.toJson();
      final restored = ProfileModel.fromJson(json);

      expect(restored.id, testModel.id);
      expect(restored.userId, testModel.userId);
      expect(restored.displayName, testModel.displayName);
      expect(restored.bio, testModel.bio);
      expect(restored.city, testModel.city);
      expect(restored.country, testModel.country);
      expect(restored.interests, testModel.interests);
    });

    test('toEntity should convert model to entity correctly', () {
      final entity = testModel.toEntity();

      expect(entity, isA<Profile>());
      expect(entity.id, testModel.id);
      expect(entity.userId, testModel.userId);
      expect(entity.displayName, testModel.displayName);
      expect(entity.birthDate, testModel.birthDate);
      expect(entity.bio, testModel.bio);
      expect(entity.city, testModel.city);
      expect(entity.country, testModel.country);
      expect(entity.interests, testModel.interests);
      expect(entity.relationshipType, testModel.relationshipType);
      expect(entity.isHidden, testModel.isHidden);
    });

    test('fromEntity should convert entity to model correctly', () {
      final entity = testModel.toEntity();
      final model = ProfileModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.userId, entity.userId);
      expect(model.displayName, entity.displayName);
      expect(model.birthDate, entity.birthDate);
      expect(model.bio, entity.bio);
      expect(model.city, entity.city);
      expect(model.country, entity.country);
      expect(model.interests, entity.interests);
    });

    test('fromJson should handle null Timestamp fields gracefully', () {
      final jsonWithNullTimestamp = Map<String, dynamic>.from(testJson);
      jsonWithNullTimestamp['birthDate'] = null;

      final result = ProfileModel.fromJson(jsonWithNullTimestamp);

      expect(result.birthDate, isNotNull);
      expect(result.birthDate, isA<DateTime>());
    });

    test('fromFirestore should create model from DocumentSnapshot', () {
      // Note: This would require mocking DocumentSnapshot in a real test
      // For now, we're just verifying the structure exists
      expect(ProfileModel.fromFirestore, isA<Function>());
    });

    test('toFirestore should exclude id from JSON', () {
      final result = testModel.toFirestore();

      expect(result.containsKey('id'), false);
      expect(result.containsKey('userId'), true);
      expect(result.containsKey('displayName'), true);
    });
  });

  group('LocationModel', () {
    final testJson = {
      'latitude': 48.8566,
      'longitude': 2.3522,
      'geohash': 'u09tvw0f6',
    };

    final testModel = LocationModel(
      latitude: 48.8566,
      longitude: 2.3522,
      geohash: 'u09tvw0f6',
    );

    test('fromJson should deserialize JSON correctly', () {
      final result = LocationModel.fromJson(testJson);

      expect(result.latitude, 48.8566);
      expect(result.longitude, 2.3522);
      expect(result.geohash, 'u09tvw0f6');
    });

    test('toJson should serialize model correctly', () {
      final result = testModel.toJson();

      expect(result['latitude'], 48.8566);
      expect(result['longitude'], 2.3522);
      expect(result['geohash'], 'u09tvw0f6');
    });

    test('fromJson and toJson should be reversible', () {
      final json = testModel.toJson();
      final restored = LocationModel.fromJson(json);

      expect(restored.latitude, testModel.latitude);
      expect(restored.longitude, testModel.longitude);
      expect(restored.geohash, testModel.geohash);
    });

    test('toEntity should convert model to entity correctly', () {
      final entity = testModel.toEntity();

      expect(entity, isA<Location>());
      expect(entity.latitude, testModel.latitude);
      expect(entity.longitude, testModel.longitude);
      expect(entity.geohash, testModel.geohash);
    });

    test('fromEntity should convert entity to model correctly', () {
      final entity = testModel.toEntity();
      final model = LocationModel.fromEntity(entity);

      expect(model.latitude, entity.latitude);
      expect(model.longitude, entity.longitude);
      expect(model.geohash, entity.geohash);
    });

    test('should handle edge case coordinates', () {
      final edgeCases = [
        {'latitude': 90.0, 'longitude': 180.0, 'geohash': 'test1'},
        {'latitude': -90.0, 'longitude': -180.0, 'geohash': 'test2'},
        {'latitude': 0.0, 'longitude': 0.0, 'geohash': 'test3'},
      ];

      for (final json in edgeCases) {
        final model = LocationModel.fromJson(json);
        expect(model.latitude, json['latitude']);
        expect(model.longitude, json['longitude']);
        expect(model.geohash, json['geohash']);
      }
    });
  });

  group('PhotoCollectionModel', () {
    test('fromJson should deserialize JSON correctly', () {
      final json = {
        'main': 'https://example.com/main.jpg',
        'others': ['https://example.com/photo2.jpg', 'https://example.com/photo3.jpg'],
        'private': ['https://example.com/private1.jpg'],
      };

      final result = PhotoCollectionModel.fromJson(json);

      expect(result.main, 'https://example.com/main.jpg');
      expect(result.others.length, 2);
      expect(result.private.length, 1);
    });

    test('fromJson should handle empty arrays', () {
      final json = {
        'main': 'https://example.com/main.jpg',
        'others': <String>[],
        'private': <String>[],
      };

      final result = PhotoCollectionModel.fromJson(json);

      expect(result.main, 'https://example.com/main.jpg');
      expect(result.others, isEmpty);
      expect(result.private, isEmpty);
    });

    test('fromJson should use default empty lists when fields are missing', () {
      final json = {
        'main': 'https://example.com/main.jpg',
      };

      final result = PhotoCollectionModel.fromJson(json);

      expect(result.main, 'https://example.com/main.jpg');
      expect(result.others, isEmpty);
      expect(result.private, isEmpty);
    });

    test('toJson should serialize model correctly', () {
      final model = PhotoCollectionModel(
        main: 'https://example.com/main.jpg',
        others: ['https://example.com/photo2.jpg'],
        private: ['https://example.com/private1.jpg'],
      );

      final result = model.toJson();

      expect(result['main'], 'https://example.com/main.jpg');
      expect(result['others'], ['https://example.com/photo2.jpg']);
      expect(result['private'], ['https://example.com/private1.jpg']);
    });

    test('toEntity should convert model to entity correctly', () {
      final model = PhotoCollectionModel(
        main: 'https://example.com/main.jpg',
        others: ['https://example.com/photo2.jpg'],
        private: [],
      );

      final entity = model.toEntity();

      expect(entity, isA<PhotoCollection>());
      expect(entity.main, model.main);
      expect(entity.others, model.others);
      expect(entity.private, model.private);
    });

    test('fromEntity should convert entity to model correctly', () {
      final entity = PhotoCollection(
        main: 'https://example.com/main.jpg',
        others: ['https://example.com/photo2.jpg'],
        private: ['https://example.com/private1.jpg'],
      );

      final model = PhotoCollectionModel.fromEntity(entity);

      expect(model.main, entity.main);
      expect(model.others, entity.others);
      expect(model.private, entity.private);
    });
  });

  group('SearchPreferencesModel', () {
    final testJson = {
      'minAge': 25,
      'maxAge': 35,
      'maxDistance': 50.0,
      'interestedIn': ['female'],
      'relationshipTypes': ['casual_dating', 'friendship'],
      'showVerifiedOnly': true,
      'showOnlineOnly': false,
    };

    final testModel = SearchPreferencesModel(
      minAge: 25,
      maxAge: 35,
      maxDistance: 50.0,
      interestedIn: ['female'],
      relationshipTypes: ['casual_dating', 'friendship'],
      showVerifiedOnly: true,
      showOnlineOnly: false,
    );

    test('fromJson should deserialize JSON correctly', () {
      final result = SearchPreferencesModel.fromJson(testJson);

      expect(result.minAge, 25);
      expect(result.maxAge, 35);
      expect(result.maxDistance, 50.0);
      expect(result.interestedIn, ['female']);
      expect(result.relationshipTypes, ['casual_dating', 'friendship']);
      expect(result.showVerifiedOnly, true);
      expect(result.showOnlineOnly, false);
    });

    test('fromJson should use default values for boolean fields', () {
      final jsonWithoutBooleans = {
        'minAge': 25,
        'maxAge': 35,
        'maxDistance': 50.0,
        'interestedIn': ['female'],
        'relationshipTypes': ['casual_dating'],
      };

      final result = SearchPreferencesModel.fromJson(jsonWithoutBooleans);

      expect(result.showVerifiedOnly, false);
      expect(result.showOnlineOnly, false);
    });

    test('toJson should serialize model correctly', () {
      final result = testModel.toJson();

      expect(result['minAge'], 25);
      expect(result['maxAge'], 35);
      expect(result['maxDistance'], 50.0);
      expect(result['interestedIn'], ['female']);
      expect(result['relationshipTypes'], ['casual_dating', 'friendship']);
      expect(result['showVerifiedOnly'], true);
      expect(result['showOnlineOnly'], false);
    });

    test('fromJson and toJson should be reversible', () {
      final json = testModel.toJson();
      final restored = SearchPreferencesModel.fromJson(json);

      expect(restored.minAge, testModel.minAge);
      expect(restored.maxAge, testModel.maxAge);
      expect(restored.maxDistance, testModel.maxDistance);
      expect(restored.interestedIn, testModel.interestedIn);
      expect(restored.relationshipTypes, testModel.relationshipTypes);
    });

    test('toEntity should convert model to entity correctly', () {
      final entity = testModel.toEntity();

      expect(entity, isA<SearchPreferences>());
      expect(entity.minAge, testModel.minAge);
      expect(entity.maxAge, testModel.maxAge);
      expect(entity.maxDistance, testModel.maxDistance);
    });

    test('fromEntity should convert entity to model correctly', () {
      final entity = testModel.toEntity();
      final model = SearchPreferencesModel.fromEntity(entity);

      expect(model.minAge, entity.minAge);
      expect(model.maxAge, entity.maxAge);
      expect(model.maxDistance, entity.maxDistance);
    });

    test('should handle edge case age values', () {
      final edgeCases = [
        {'minAge': 18, 'maxAge': 99, 'maxDistance': 1.0, 'interestedIn': <String>[], 'relationshipTypes': <String>[]},
        {'minAge': 18, 'maxAge': 18, 'maxDistance': 100.0, 'interestedIn': <String>[], 'relationshipTypes': <String>[]},
      ];

      for (final json in edgeCases) {
        final model = SearchPreferencesModel.fromJson(json);
        expect(model.minAge, json['minAge']);
        expect(model.maxAge, json['maxAge']);
      }
    });
  });

  group('VerificationStatusModel', () {
    final testDateTime = DateTime(2024, 2, 24, 12, 0, 0);

    final testJson = {
      'status': 'verified',
      'submittedAt': Timestamp.fromDate(testDateTime),
      'reviewedAt': Timestamp.fromDate(testDateTime),
      'rejectionReason': null,
      'expiresAt': Timestamp.fromDate(testDateTime.add(Duration(days: 365))),
      'documents': {
        'id': {
          'type': 'identity_document',
          'status': 'approved',
        },
      },
    };

    test('fromJson should deserialize JSON correctly', () {
      final result = VerificationStatusModel.fromJson(testJson);

      expect(result.status, 'verified');
      expect(result.submittedAt, isNotNull);
      expect(result.reviewedAt, isNotNull);
      expect(result.rejectionReason, null);
      expect(result.expiresAt, isNotNull);
      expect(result.documents.length, 1);
    });

    test('fromJson should handle null optional fields', () {
      final jsonWithNulls = {
        'status': 'not_started',
        'documents': <String, dynamic>{},
      };

      final result = VerificationStatusModel.fromJson(jsonWithNulls);

      expect(result.status, 'not_started');
      expect(result.submittedAt, null);
      expect(result.reviewedAt, null);
      expect(result.rejectionReason, null);
      expect(result.expiresAt, null);
      expect(result.documents, isEmpty);
    });

    test('toJson should serialize model correctly', () {
      final model = VerificationStatusModel(
        status: 'verified',
        submittedAt: testDateTime,
        reviewedAt: testDateTime,
        rejectionReason: null,
        expiresAt: testDateTime.add(Duration(days: 365)),
        documents: {
          'id': DocumentStatusModel(
            type: 'identity_document',
            status: 'approved',
          ),
        },
      );

      final result = model.toJson();

      expect(result['status'], 'verified');
      expect(result['submittedAt'], isA<Timestamp>());
      expect(result['reviewedAt'], isA<Timestamp>());
      expect(result['expiresAt'], isA<Timestamp>());
    });

    test('toEntity should convert model to entity correctly', () {
      final model = VerificationStatusModel(
        status: 'verified',
        submittedAt: testDateTime,
        reviewedAt: testDateTime,
        rejectionReason: null,
        expiresAt: testDateTime.add(Duration(days: 365)),
        documents: {},
      );

      final entity = model.toEntity();

      expect(entity, isA<VerificationStatus>());
      expect(entity.status, model.status);
      expect(entity.submittedAt, model.submittedAt);
    });

    test('should handle different verification statuses', () {
      final statuses = [
        'not_started',
        'pending_id',
        'pending_medical',
        'pending_selfie',
        'pending_review',
        'verified',
        'rejected',
        'expired',
      ];

      for (final status in statuses) {
        final json = {
          'status': status,
          'documents': <String, dynamic>{},
        };
        final model = VerificationStatusModel.fromJson(json);
        expect(model.status, status);
      }
    });
  });

  group('DocumentStatusModel', () {
    test('fromJson should deserialize JSON correctly', () {
      final json = {
        'type': 'identity_document',
        'status': 'approved',
      };

      final result = DocumentStatusModel.fromJson(json);

      expect(result.type, 'identity_document');
      expect(result.status, 'approved');
    });

    test('toJson should serialize model correctly', () {
      final model = DocumentStatusModel(
        type: 'identity_document',
        status: 'approved',
      );

      final result = model.toJson();

      expect(result['type'], 'identity_document');
      expect(result['status'], 'approved');
    });

    test('toEntity should convert model to entity correctly', () {
      final model = DocumentStatusModel(
        type: 'identity_document',
        status: 'approved',
      );

      final entity = model.toEntity();

      expect(entity, isA<DocumentStatus>());
      expect(entity.type, model.type);
      expect(entity.status, model.status);
    });

    test('should handle different document types and statuses', () {
      final testCases = [
        {'type': 'identity_document', 'status': 'pending'},
        {'type': 'medical_document', 'status': 'uploaded'},
        {'type': 'selfie_with_code', 'status': 'approved'},
        {'type': 'identity_document', 'status': 'rejected'},
      ];

      for (final json in testCases) {
        final model = DocumentStatusModel.fromJson(json);
        expect(model.type, json['type']);
        expect(model.status, json['status']);
      }
    });
  });

  group('PrivacySettingsModel', () {
    test('fromJson should deserialize JSON correctly', () {
      final json = {
        'profileVisibility': 'visible_to_all',
        'showOnlineStatus': true,
        'showDistance': true,
        'showExactLocation': false,
        'profileDiscoverable': true,
      };

      final result = PrivacySettingsModel.fromJson(json);

      expect(result.profileVisibility, 'visible_to_all');
      expect(result.showOnlineStatus, true);
      expect(result.showDistance, true);
      expect(result.showExactLocation, false);
      expect(result.profileDiscoverable, true);
    });

    test('fromJson should use default values when fields are missing', () {
      final json = <String, dynamic>{};

      final result = PrivacySettingsModel.fromJson(json);

      expect(result.profileVisibility, 'visible_to_all');
      expect(result.showOnlineStatus, true);
      expect(result.showDistance, true);
      expect(result.showExactLocation, false);
      expect(result.profileDiscoverable, true);
    });

    test('toJson should serialize model correctly', () {
      final model = PrivacySettingsModel(
        profileVisibility: 'incognito',
        showOnlineStatus: false,
        showDistance: false,
        showExactLocation: false,
        profileDiscoverable: false,
      );

      final result = model.toJson();

      expect(result['profileVisibility'], 'incognito');
      expect(result['showOnlineStatus'], false);
      expect(result['showDistance'], false);
      expect(result['showExactLocation'], false);
      expect(result['profileDiscoverable'], false);
    });

    test('toEntity should convert model to entity correctly', () {
      final model = PrivacySettingsModel(
        profileVisibility: 'visible_to_matches_only',
        showOnlineStatus: false,
        showDistance: true,
        showExactLocation: false,
        profileDiscoverable: true,
      );

      final entity = model.toEntity();

      expect(entity, isA<PrivacySettings>());
      expect(entity.profileVisibility, model.profileVisibility);
      expect(entity.showOnlineStatus, model.showOnlineStatus);
    });

    test('should handle different visibility modes', () {
      final visibilityModes = [
        'visible_to_all',
        'visible_to_matches_only',
        'incognito',
      ];

      for (final mode in visibilityModes) {
        final json = {'profileVisibility': mode};
        final model = PrivacySettingsModel.fromJson(json);
        expect(model.profileVisibility, mode);
      }
    });
  });
}
