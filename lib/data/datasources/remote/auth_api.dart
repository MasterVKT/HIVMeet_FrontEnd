// lib/data/datasources/remote/auth_api.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/exceptions.dart';
import 'package:hivmeet/data/models/user_model.dart';

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

  AuthRemoteDataSourceImpl(
    this._firebaseAuth,
    this._firestore,
    this._dio,
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
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw ServerException(message: 'Échec de connexion');
      }

      // Vérifier que l'email est vérifié
      if (!credential.user!.emailVerified) {
        throw EmailNotVerifiedException();
      }

      // Récupérer les données utilisateur depuis Firestore
      final doc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!doc.exists) {
        throw ServerException(message: 'Données utilisateur introuvables');
      }

      // Mettre à jour lastActive
      await doc.reference.update({
        'lastActive': FieldValue.serverTimestamp(),
      });

      return UserModel.fromFirestore(doc);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
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

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc);
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

  ServerException _handleFirebaseAuthException(firebase_auth.FirebaseAuthException e) {
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
        throw ServerException(message: e.message ?? 'Erreur d\'authentification');
    }
  }
}
