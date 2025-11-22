// test/domain/usecases/auth/verify_email_test.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/auth_repository.dart';
import 'package:hivmeet/domain/usecases/auth/verify_email.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late VerifyEmail usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = VerifyEmail(mockRepository);
  });

  const tVerificationCode = '123456';
  const tParams = VerifyEmailParams(verificationCode: tVerificationCode);

  group('VerifyEmail', () {
    test('should verify email successfully with valid code', () async {
      // arrange
      when(() => mockRepository.verifyEmail(
            verificationCode: any(named: 'verificationCode'),
          )).thenAnswer((_) async => const Right(null));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Right(null));
      verify(() => mockRepository.verifyEmail(
            verificationCode: tVerificationCode,
          )).called(1);
    });

    test('should return UnauthorizedFailure when user not authenticated',
        () async {
      // arrange
      when(() => mockRepository.verifyEmail(
            verificationCode: any(named: 'verificationCode'),
          )).thenAnswer((_) async => const Left(UnauthorizedFailure()));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(UnauthorizedFailure()));
      verify(() => mockRepository.verifyEmail(
            verificationCode: tVerificationCode,
          )).called(1);
    });

    test('should return ServerFailure when verification code is invalid',
        () async {
      // arrange
      const tFailure =
          ServerFailure(message: 'Code de vérification invalide ou expiré');
      when(() => mockRepository.verifyEmail(
            verificationCode: any(named: 'verificationCode'),
          )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockRepository.verifyEmail(
            verificationCode: tVerificationCode,
          )).called(1);
    });

    test('should return ServerFailure on network error', () async {
      // arrange
      const tFailure = ServerFailure(message: 'Erreur réseau');
      when(() => mockRepository.verifyEmail(
            verificationCode: any(named: 'verificationCode'),
          )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockRepository.verifyEmail(
            verificationCode: tVerificationCode,
          )).called(1);
    });
  });
}
