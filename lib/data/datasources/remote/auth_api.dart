// lib/data/datasources/remote/auth_api.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/exceptions.dart';
import 'package:hivmeet/data/models/user_model.dart';
import 'package:hivmeet/core/network/api_client.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String displayName,
    required DateTime birthDate,
    String? phoneNumber,
  });

  Future<UserModel> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> get authStateChanges;

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> verifyEmail({required String verificationCode});

  Future<void> resendVerificationEmail();

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<String> refreshToken();

  Future<String?> getAuthToken();

  Future<void> deleteAccount({required String password});
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final Dio _dio;
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(
    this._firebaseAuth,
    this._firestore,
    this._dio,
    this._apiClient,
  );

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String displayName,
    required DateTime birthDate,
    String? phoneNumber,
  }) async {
    try {
      // Créer le compte Firebase Auth
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw ServerException(message: 'Échec de création du compte');
      }

      // Mettre à jour le displayName
      await credential.user!.updateDisplayName(displayName);

      // Envoyer l'email de vérification
      await credential.user!.sendEmailVerification();

      // Créer le document utilisateur dans Firestore
      final userModel = UserModel(
        id: credential.user!.uid,
        email: email,
        displayName: displayName,
        isVerified: false,
        isPremium: false,
        lastActive: DateTime.now(),
        isEmailVerified: false,
        notificationSettings: NotificationSettingsModel(),
        blockedUserIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userModel.toFirestore());

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    print('🔥 DEBUG AuthAPI: signIn DÉMARRÉ pour $email');

    try {
      print('🔥 DEBUG AuthAPI: Appel Firebase signInWithEmailAndPassword...');
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ DEBUG AuthAPI: Firebase signIn terminé');

      if (credential.user == null) {
        print('❌ DEBUG AuthAPI: credential.user est null');
        throw ServerException(message: 'Échec de connexion');
      }

      print('✅ DEBUG AuthAPI: Firebase user récupéré: ${credential.user!.uid}');

      // Vérifier que l'email est vérifié (sauf pour les utilisateurs de test)
      final isTestUser = email.contains('test@hivmeet.com') ||
          email.contains('@test.') ||
          email.contains('test@');

      if (!credential.user!.emailVerified && !isTestUser) {
        print('❌ DEBUG AuthAPI: Email non vérifié pour utilisateur non-test');
        throw EmailNotVerifiedException();
      }

      print('✅ DEBUG AuthAPI: Vérification email OK');

      try {
        print('🔥 DEBUG AuthAPI: Tentative accès Firestore...');
        // Récupérer les données utilisateur depuis Firestore
        final doc = await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        UserModel userModel;

        if (doc.exists) {
          print('✅ DEBUG AuthAPI: Document Firestore existant trouvé');
          // Utilisateur existe dans Firestore
          userModel = UserModel.fromFirestore(doc);

          // Mettre à jour lastActive
          try {
            print('🔥 DEBUG AuthAPI: Mise à jour lastActive...');
            await doc.reference.update({
              'lastActive': FieldValue.serverTimestamp(),
            });
            print('✅ DEBUG AuthAPI: lastActive mis à jour');
          } catch (updateError) {
            print(
                '❌ DEBUG AuthAPI: Erreur mise à jour lastActive: $updateError');
            // Continue sans bloquer
          }
        } else {
          // Utilisateur n'existe pas dans Firestore, créer un document
          print(
              '🔥 DEBUG AuthAPI: Création nouveau document Firestore pour: ${credential.user!.email}');

          userModel = UserModel(
            id: credential.user!.uid,
            email: credential.user!.email ?? '',
            displayName: credential.user!.displayName ?? 'Utilisateur',
            isVerified: false,
            isPremium: false,
            lastActive: DateTime.now(),
            isEmailVerified: credential.user!.emailVerified,
            notificationSettings: NotificationSettingsModel(
              newMatchNotifications: true,
              newMessageNotifications: true,
              profileLikeNotifications: true,
              appUpdateNotifications: true,
              promotionalNotifications: false,
            ),
            blockedUserIds: [],
            createdAt: credential.user!.metadata.creationTime ?? DateTime.now(),
            updatedAt: DateTime.now(),
          );

          try {
            print('🔥 DEBUG AuthAPI: Sauvegarde document Firestore...');
            await _firestore
                .collection('users')
                .doc(credential.user!.uid)
                .set(userModel.toFirestore());
            print('✅ DEBUG AuthAPI: Document Firestore créé avec succès');
          } catch (createError) {
            print(
                '❌ DEBUG AuthAPI: Erreur création document Firestore: $createError');
            // Continue avec l'utilisateur minimal
          }
        }

        print('✅ DEBUG AuthAPI: UserModel créé, retour...');
        return userModel;
      } catch (firestoreError) {
        // Si Firestore n'est pas configuré, retourner un utilisateur minimal
        print(
            '❌ DEBUG AuthAPI: Erreur Firestore, création utilisateur minimal: $firestoreError');

        return UserModel(
          id: credential.user!.uid,
          email: credential.user!.email ?? '',
          displayName: credential.user!.displayName ?? 'Utilisateur',
          isVerified: false,
          isPremium: false,
          lastActive: DateTime.now(),
          isEmailVerified: credential.user!.emailVerified,
          notificationSettings: NotificationSettingsModel(
            newMatchNotifications: true,
            newMessageNotifications: true,
            profileLikeNotifications: true,
            appUpdateNotifications: true,
            promotionalNotifications: false,
          ),
          blockedUserIds: [],
          createdAt: credential.user!.metadata.creationTime ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('❌ DEBUG AuthAPI: FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      print('❌ DEBUG AuthAPI: Exception générale: $e');
      print('Type exception: ${e.runtimeType}');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw ServerException(message: 'Échec de déconnexion');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException(message: 'Impossible de récupérer l\'utilisateur');
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;

      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) return null;

        return UserModel.fromFirestore(doc);
      } catch (e) {
        // Gestion d'erreur si Firestore n'est pas configuré ou indisponible
        print('Erreur Firestore dans authStateChanges: $e');

        // Retourner un utilisateur minimal basé sur FirebaseAuth seulement
        return UserModel(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'Utilisateur',
          isVerified: false,
          isPremium: false,
          lastActive: DateTime.now(),
          isEmailVerified: user.emailVerified,
          notificationSettings: NotificationSettingsModel(
            newMatchNotifications: true,
            newMessageNotifications: true,
            profileLikeNotifications: true,
            appUpdateNotifications: true,
            promotionalNotifications: false,
          ),
          blockedUserIds: [],
          createdAt: user.metadata.creationTime ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    });
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw ServerException(message: 'Impossible d\'envoyer l\'email');
    }
  }

  @override
  Future<void> verifyEmail({required String verificationCode}) async {
    try {
      // Dans Firebase, la vérification se fait via un lien
      // Le code ici pourrait être utilisé pour une vérification personnalisée côté backend
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw UnauthorizedException();
      }

      await user.reload();
      if (!user.emailVerified) {
        throw ServerException(message: 'Email non vérifié');
      }

      // Mettre à jour le statut dans Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'isEmailVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException(message: 'Échec de vérification');
    }
  }

  @override
  Future<void> resendVerificationEmail() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw UnauthorizedException();
      }

      await user.sendEmailVerification();
    } catch (e) {
      throw ServerException(message: 'Impossible de renvoyer l\'email');
    }
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || user.email == null) {
        throw UnauthorizedException();
      }

      // Ré-authentifier l'utilisateur
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw ServerException(message: 'Impossible de modifier le mot de passe');
    }
  }

  @override
  Future<String> refreshToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw UnauthorizedException();
      }

      final token = await user.getIdToken(true);
      if (token == null) {
        throw ServerException(message: 'Impossible de générer le token');
      }
      return token;
    } catch (e) {
      throw ServerException(message: 'Impossible de rafraîchir le token');
    }
  }

  @override
  Future<String?> getAuthToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      return await user.getIdToken();
    } catch (e) {
      throw ServerException(message: 'Impossible de récupérer le token');
    }
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || user.email == null) {
        throw UnauthorizedException();
      }

      // Ré-authentifier avant suppression
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      // Marquer le compte comme supprimé dans Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'deletedAt': FieldValue.serverTimestamp(),
        'status': 'deleted',
      });

      // Supprimer le compte Firebase Auth
      await user.delete();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw ServerException(message: 'Impossible de supprimer le compte');
    }
  }

  ServerException _handleFirebaseAuthException(
      firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        throw EmailAlreadyInUseException();
      case 'invalid-email':
        throw InvalidEmailException();
      case 'weak-password':
        throw WeakPasswordException();
      case 'user-not-found':
        throw UserNotFoundException();
      case 'wrong-password':
        throw WrongPasswordException();
      case 'user-disabled':
        throw UserDisabledException();
      default:
        throw ServerException(
            message: e.message ?? 'Erreur d\'authentification');
    }
  }
}

@injectable
class AuthApi {
  final ApiClient _apiClient;

  const AuthApi(this._apiClient);

  /// Échange du token Firebase contre des tokens JWT
  /// POST /auth/firebase-exchange/
  Future<Response<Map<String, dynamic>>> exchangeFirebaseToken({
    required String firebaseIdToken,
  }) async {
    final data = {
      // Alignement backend: préférer id_token, garder compat
      'id_token': firebaseIdToken,
      'firebase_token': firebaseIdToken,
    };

    return await _apiClient.post('/auth/firebase-exchange/', data: data);
  }

  /// Actualisation du token JWT
  /// POST /auth/refresh-token
  Future<Response<Map<String, dynamic>>> refreshToken({
    required String refreshToken,
  }) async {
    final data = {
      'refresh_token': refreshToken,
    };

    return await _apiClient.post('/auth/refresh-token/', data: data);
  }

  /// Enregistrement du token FCM
  /// POST /auth/fcm-token
  Future<Response<Map<String, dynamic>>> registerFCMToken({
    required String fcmToken,
    required String deviceType, // "android|ios"
    String? deviceId,
  }) async {
    final data = {
      'fcm_token': fcmToken,
      'device_type': deviceType,
    };

    if (deviceId != null) {
      data['device_id'] = deviceId;
    }

    return await _apiClient.post('/auth/fcm-token', data: data);
  }

  /// Suppression du token FCM
  /// DELETE /auth/fcm-token
  Future<Response<Map<String, dynamic>>> removeFCMToken({
    required String fcmToken,
  }) async {
    return await _apiClient.delete('/auth/fcm-token', queryParameters: {
      'fcm_token': fcmToken,
    });
  }

  /// Vérification de l'email
  /// POST /auth/verify-email
  Future<Response<Map<String, dynamic>>> verifyEmail({
    required String verificationCode,
  }) async {
    final data = {
      'verification_code': verificationCode,
    };

    return await _apiClient.post('/auth/verify-email', data: data);
  }

  /// Renvoyer l'email de vérification
  /// POST /auth/resend-verification
  Future<Response<Map<String, dynamic>>> resendVerificationEmail() async {
    return await _apiClient.post('/auth/resend-verification');
  }

  /// Récupération des informations utilisateur
  /// GET /auth/me
  Future<Response<Map<String, dynamic>>> getCurrentUser() async {
    return await _apiClient.get('/auth/me');
  }

  /// Mise à jour des informations utilisateur
  /// PUT /auth/me
  Future<Response<Map<String, dynamic>>> updateUserInfo({
    String? displayName,
    String? email,
    String? phone,
    DateTime? birthDate,
  }) async {
    final data = <String, dynamic>{};

    if (displayName != null) data['display_name'] = displayName;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    if (birthDate != null) data['birth_date'] = birthDate.toIso8601String();

    return await _apiClient.put('/auth/me', data: data);
  }

  /// Changement de mot de passe
  /// POST /auth/change-password
  Future<Response<Map<String, dynamic>>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final data = {
      'current_password': currentPassword,
      'new_password': newPassword,
    };

    return await _apiClient.post('/auth/change-password', data: data);
  }

  /// Suppression de compte
  /// DELETE /auth/delete-account
  Future<Response<Map<String, dynamic>>> deleteAccount({
    required String password,
    required String reason,
    String? feedback,
  }) async {
    final data = {
      'password': password,
      'reason': reason,
    };

    if (feedback != null) {
      data['feedback'] = feedback;
    }

    return await _apiClient.delete('/auth/delete-account', data: data);
  }

  /// Déconnexion
  /// POST /auth/logout
  Future<Response<Map<String, dynamic>>> logout({
    String? fcmToken,
  }) async {
    final data = <String, dynamic>{};

    if (fcmToken != null) {
      data['fcm_token'] = fcmToken;
    }

    return await _apiClient.post('/auth/logout', data: data);
  }

  /// Signaler un utilisateur
  /// POST /auth/report-user
  Future<Response<Map<String, dynamic>>> reportUser({
    required String reportedUserId,
    required String reason,
    String? description,
  }) async {
    final data = {
      'reported_user_id': reportedUserId,
      'reason': reason,
    };

    if (description != null) {
      data['description'] = description;
    }

    return await _apiClient.post('/auth/report-user', data: data);
  }

  /// Bloquer un utilisateur
  /// POST /auth/block-user
  Future<Response<Map<String, dynamic>>> blockUser({
    required String blockedUserId,
  }) async {
    final data = {
      'blocked_user_id': blockedUserId,
    };

    return await _apiClient.post('/auth/block-user', data: data);
  }

  /// Débloquer un utilisateur
  /// DELETE /auth/block-user
  Future<Response<Map<String, dynamic>>> unblockUser({
    required String blockedUserId,
  }) async {
    return await _apiClient.delete('/auth/block-user', queryParameters: {
      'blocked_user_id': blockedUserId,
    });
  }

  /// Liste des utilisateurs bloqués
  /// GET /auth/blocked-users
  Future<Response<Map<String, dynamic>>> getBlockedUsers({
    int page = 1,
    int perPage = 20,
  }) async {
    return await _apiClient.get('/auth/blocked-users', queryParameters: {
      'page': page,
      'per_page': perPage,
    });
  }
}
