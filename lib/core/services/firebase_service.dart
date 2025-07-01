// lib/core/services/firebase_service.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

@singleton
class FirebaseService {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  FirebaseStorage? _storage;
  FirebaseMessaging? _messaging;

  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;
  FirebaseStorage get storage => _storage ?? FirebaseStorage.instance;
  FirebaseMessaging get messaging => _messaging ?? FirebaseMessaging.instance;

  @PostConstruct(preResolve: true)
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;
      _messaging = FirebaseMessaging.instance;

      // Configure Firestore settings
      _firestore!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Configure Firebase Auth settings
      await _auth!.setLanguageCode('fr');
    } catch (e) {
      throw Exception('Failed to initialize Firebase: $e');
    }
  }

  Future<void> requestNotificationPermission() async {
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await messaging.getToken();
      // Store token for later use
      if (kDebugMode) {
        print('FCM Token: $token');
      }
    }
  }
}
