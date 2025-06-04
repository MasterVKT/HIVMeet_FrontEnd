// lib/data/repositories/auth_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/exceptions.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/data/datasources/local/auth_local_datasource.dart';
import 'package:hivmeet/data/datasources/remote/auth_api.dart';
import 'package:hivmeet/domain/entities/user.dart';
import 'package:hivmeet/domain/repositories/auth_repository.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
  );

  @override
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String displayName,
    required DateTime birthDate,
    String? phoneNumber,
  }) async {
    try {
      final userModel = await _remoteDataSource.signUp(
        email: email,
        password: password,
        displayName: displayName,
        birthDate: birthDate,
        phoneNumber: phoneNumber,
      );

      // Cache l'utilisateur localement
      await _localDataSource.cacheUser(userModel);

      return Right(userModel.toEntity());
    } on EmailAlreadyInUseException {
      return const Left(EmailAlreadyInUseFailure());
    } on InvalidEmailException {
      return const Left(InvalidEmailFailure());
    } on WeakPasswordException {
      return const Left(WeakPasswordFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await _remoteDataSource.signIn(
        email: email,
        password: password,
      );

      // Cache l'utilisateur et le token
      await _localDataSource.cacheUser(userModel);
      
      final token = await _remoteDataSource.getAuthToken();
      if (token != null) {
        await _localDataSource.cacheAuthToken(token);
      }

      return Right(userModel.toEntity());
    } on UserNotFoundException {
      return const Left(UserNotFoundFailure());
    } on WrongPasswordException {
      return const Left(WrongCredentialsFailure());
    } on EmailNotVerifiedException {
      return const Left(EmailNotVerifiedFailure());
    } on UserDisabledException {
      return const Left(UserDisabledFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      await _localDataSource.clearAllAuthData();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      // Essayer d'abord de récupérer depuis le cache
      final cachedUser = await _localDataSource.getCachedUser();
      if (cachedUser != null) {
        return Right(cachedUser.toEntity());
      }

      // Sinon, récupérer depuis le serveur
      final userModel = await _remoteDataSource.getCurrentUser();
      if (userModel != null) {
        await _localDataSource.cacheUser(userModel);
        return Right(userModel.toEntity());
      }

      return const Right(null);
    } on CacheException {
      // Si le cache échoue, continuer avec le serveur
      try {
        final userModel = await _remoteDataSource.getCurrentUser();
        return Right(userModel?.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<User?> get authStateChanges {
    return _remoteDataSource.authStateChanges.map((userModel) {
      if (userModel != null) {
        // Cache l'utilisateur à chaque changement d'état
        _localDataSource.cacheUser(userModel);
        return userModel.toEntity();
      }
      return null;
    });
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({required String email}) async {
    try {
      await _remoteDataSource.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on UserNotFoundException {
      return const Left(UserNotFoundFailure());
    } on InvalidEmailException {
      return const Left(InvalidEmailFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> verifyEmail({required String verificationCode}) async {
    try {
      await _remoteDataSource.verifyEmail(verificationCode: verificationCode);
      return const Right(null);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resendVerificationEmail() async {
    try {
      await _remoteDataSource.resendVerificationEmail();
      return const Right(null);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right(null);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on WrongPasswordException {
      return const Left(WrongCredentialsFailure());
    } on WeakPasswordException {
      return const Left(WeakPasswordFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> refreshToken() async {
    try {
      final newToken = await _remoteDataSource.refreshToken();
      await _localDataSource.cacheAuthToken(newToken);
      return Right(newToken);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> getAuthToken() async {
    try {
      // Essayer d'abord le cache
      final cachedToken = await _localDataSource.getCachedAuthToken();
      if (cachedToken != null) {
        return Right(cachedToken);
      }

      // Sinon récupérer depuis Firebase
      final token = await _remoteDataSource.getAuthToken();
      if (token != null) {
        await _localDataSource.cacheAuthToken(token);
      }
      return Right(token);
    } on CacheException {
      // Si le cache échoue, continuer avec le serveur
      try {
        final token = await _remoteDataSource.getAuthToken();
        return Right(token);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount({required String password}) async {
    try {
      await _remoteDataSource.deleteAccount(password: password);
      await _localDataSource.clearAllAuthData();
      return const Right(null);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on WrongPasswordException {
      return const Left(WrongCredentialsFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
