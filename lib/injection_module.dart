// lib/injection_module.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

@module
abstract class InjectionModule {
  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  @lazySingleton
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  @lazySingleton
  FirebaseStorage get firebaseStorage => FirebaseStorage.instance;

  @lazySingleton
  FirebaseMessaging get firebaseMessaging => FirebaseMessaging.instance;

  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  @preResolve
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();

  @lazySingleton
  Dio get dio {
    final dio = Dio();
    dio.options.baseUrl = const String.fromEnvironment(
      'API_URL',
      defaultValue: 'https://dev.hivmeet.api/api/v1/',
    );
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
    return dio;
  }

  @lazySingleton
  Logger get logger => Logger(
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 5,
          lineLength: 100,
          colors: true,
          printEmojis: true,
          printTime: true,
        ),
      );
}
