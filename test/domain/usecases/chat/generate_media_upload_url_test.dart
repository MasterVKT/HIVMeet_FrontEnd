import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';
import 'package:hivmeet/domain/usecases/chat/generate_media_upload_url.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

void main() {
  late GenerateMediaUploadUrl usecase;
  late MockMessageRepository mockRepository;

  setUp(() {
    mockRepository = MockMessageRepository();
    usecase = GenerateMediaUploadUrl(mockRepository);
  });

  const tParams = GenerateMediaUploadUrlParams(
    fileName: 'photo.jpg',
    contentType: 'image/jpeg',
  );

  const tTarget = MediaUploadTarget(
    uploadUrl: 'https://upload.example.com/signed',
    filePathOnStorage: 'messages/uploads/photo.jpg',
    contentType: 'image/jpeg',
    expiresInSeconds: 900,
  );

  group('GenerateMediaUploadUrl', () {
    test('should return upload target from repository', () async {
      when(() => mockRepository.generateMediaUploadUrl(
            fileName: any(named: 'fileName'),
            contentType: any(named: 'contentType'),
          )).thenAnswer((_) async => const Right(tTarget));

      final result = await usecase(tParams);

      expect(result, const Right(tTarget));
      verify(() => mockRepository.generateMediaUploadUrl(
            fileName: 'photo.jpg',
            contentType: 'image/jpeg',
          )).called(1);
    });

    test('should return failure when repository fails', () async {
      const tFailure = ServerFailure(message: 'Cannot generate upload url');
      when(() => mockRepository.generateMediaUploadUrl(
            fileName: any(named: 'fileName'),
            contentType: any(named: 'contentType'),
          )).thenAnswer((_) async => const Left(tFailure));

      final result = await usecase(tParams);

      expect(result, const Left(tFailure));
    });

    test('params should be equatable', () {
      const paramsA = GenerateMediaUploadUrlParams(
        fileName: 'photo.jpg',
        contentType: 'image/jpeg',
      );
      const paramsB = GenerateMediaUploadUrlParams(
        fileName: 'photo.jpg',
        contentType: 'image/jpeg',
      );

      expect(paramsA, paramsB);
      expect(paramsA.hashCode, paramsB.hashCode);
    });
  });
}
