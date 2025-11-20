// test/domain/usecases/auth/update_password_test.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/auth_repository.dart';
import 'package:hivmeet/domain/usecases/auth/update_password.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late UpdatePassword usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = UpdatePassword(mockRepository);
  });

  const tCurrentPassword = 'oldPassword123';
  const tNewPassword = 'newPassword456';
  const tParams = UpdatePasswordParams(
    currentPassword: tCurrentPassword,
    newPassword: tNewPassword,
  );

  group('UpdatePassword', () {
    test('should update password successfully with valid credentials',
        () async {
      // arrange
      when(() => mockRepository.updatePassword(
            currentPassword: any(named: 'currentPassword'),
            newPassword: any(named: 'newPassword'),
          )).thenAnswer((_) async => const Right(null));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Right(null));
      verify(() => mockRepository.updatePassword(
            currentPassword: tCurrentPassword,
            newPassword: tNewPassword,
          )).called(1);
    });

    test('should return ServerFailure when new password is same as current',
        () async {
      // arrange
      const tSamePasswordParams = UpdatePasswordParams(
        currentPassword: 'password123',
        newPassword: 'password123',
      );

      // act
      final result = await usecase(tSamePasswordParams);

      // assert
      expect(result, isA<Left>());
      expect(
        (result as Left).value,
        isA<ServerFailure>().having(
          (f) => f.message,
          'message',
          'Le nouveau mot de passe doit être différent de l\'ancien',
        ),
      );
      verifyNever(() => mockRepository.updatePassword(
            currentPassword: any(named: 'currentPassword'),
            newPassword: any(named: 'newPassword'),
          ));
    });

    test('should return WeakPasswordFailure when new password is too short',
        () async {
      // arrange
      const tWeakPasswordParams = UpdatePasswordParams(
        currentPassword: 'oldPassword123',
        newPassword: '12345', // Moins de 6 caractères
      );

      // act
      final result = await usecase(tWeakPasswordParams);

      // assert
      expect(result, const Left(WeakPasswordFailure()));
      verifyNever(() => mockRepository.updatePassword(
            currentPassword: any(named: 'currentPassword'),
            newPassword: any(named: 'newPassword'),
          ));
    });

    test('should return UnauthorizedFailure when user not authenticated',
        () async {
      // arrange
      when(() => mockRepository.updatePassword(
            currentPassword: any(named: 'currentPassword'),
            newPassword: any(named: 'newPassword'),
          )).thenAnswer((_) async => const Left(UnauthorizedFailure()));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(UnauthorizedFailure()));
      verify(() => mockRepository.updatePassword(
            currentPassword: tCurrentPassword,
            newPassword: tNewPassword,
          )).called(1);
    });

    test('should return WrongCredentialsFailure when current password is wrong',
        () async {
      // arrange
      when(() => mockRepository.updatePassword(
            currentPassword: any(named: 'currentPassword'),
            newPassword: any(named: 'newPassword'),
          )).thenAnswer((_) async => const Left(WrongCredentialsFailure()));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(WrongCredentialsFailure()));
      verify(() => mockRepository.updatePassword(
            currentPassword: tCurrentPassword,
            newPassword: tNewPassword,
          )).called(1);
    });

    test('should return WeakPasswordFailure from repository', () async {
      // arrange
      const tWeakPasswordParams = UpdatePasswordParams(
        currentPassword: 'oldPassword123',
        newPassword: 'weak12', // Valide côté client mais rejeté par backend
      );
      when(() => mockRepository.updatePassword(
            currentPassword: any(named: 'currentPassword'),
            newPassword: any(named: 'newPassword'),
          )).thenAnswer((_) async => const Left(WeakPasswordFailure()));

      // act
      final result = await usecase(tWeakPasswordParams);

      // assert
      expect(result, const Left(WeakPasswordFailure()));
      verify(() => mockRepository.updatePassword(
            currentPassword: 'oldPassword123',
            newPassword: 'weak12',
          )).called(1);
    });

    test('should return ServerFailure on network error', () async {
      // arrange
      const tFailure = ServerFailure(message: 'Erreur réseau');
      when(() => mockRepository.updatePassword(
            currentPassword: any(named: 'currentPassword'),
            newPassword: any(named: 'newPassword'),
          )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockRepository.updatePassword(
            currentPassword: tCurrentPassword,
            newPassword: tNewPassword,
          )).called(1);
    });
  });
}
