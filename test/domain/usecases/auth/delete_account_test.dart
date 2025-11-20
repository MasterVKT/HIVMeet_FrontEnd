// test/domain/usecases/auth/delete_account_test.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/auth_repository.dart';
import 'package:hivmeet/domain/usecases/auth/delete_account.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late DeleteAccount usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = DeleteAccount(mockRepository);
  });

  const tPassword = 'userPassword123';
  const tParams = DeleteAccountParams(password: tPassword);

  group('DeleteAccount', () {
    test('should delete account successfully with valid password', () async {
      // arrange
      when(() => mockRepository.deleteAccount(
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Right(null));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Right(null));
      verify(() => mockRepository.deleteAccount(password: tPassword)).called(1);
    });

    test('should return ServerFailure when password is empty', () async {
      // arrange
      const tEmptyPasswordParams = DeleteAccountParams(password: '');

      // act
      final result = await usecase(tEmptyPasswordParams);

      // assert
      expect(result, isA<Left>());
      expect(
        (result as Left).value,
        isA<ServerFailure>().having(
          (f) => f.message,
          'message',
          'Le mot de passe est requis pour supprimer votre compte',
        ),
      );
      verifyNever(() => mockRepository.deleteAccount(
            password: any(named: 'password'),
          ));
    });

    test('should return UnauthorizedFailure when user not authenticated',
        () async {
      // arrange
      when(() => mockRepository.deleteAccount(
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Left(UnauthorizedFailure()));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(UnauthorizedFailure()));
      verify(() => mockRepository.deleteAccount(password: tPassword)).called(1);
    });

    test('should return WrongCredentialsFailure when password is incorrect',
        () async {
      // arrange
      when(() => mockRepository.deleteAccount(
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Left(WrongCredentialsFailure()));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(WrongCredentialsFailure()));
      verify(() => mockRepository.deleteAccount(password: tPassword)).called(1);
    });

    test('should return ServerFailure on network error', () async {
      // arrange
      const tFailure = ServerFailure(message: 'Erreur réseau');
      when(() => mockRepository.deleteAccount(
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockRepository.deleteAccount(password: tPassword)).called(1);
    });

    test(
        'should return ServerFailure when account deletion fails on server side',
        () async {
      // arrange
      const tFailure = ServerFailure(
        message: 'Impossible de supprimer le compte. Réessayez plus tard.',
      );
      when(() => mockRepository.deleteAccount(
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockRepository.deleteAccount(password: tPassword)).called(1);
    });
  });
}
