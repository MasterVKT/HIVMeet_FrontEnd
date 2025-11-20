// lib/domain/usecases/chat/send_media_message.dart

import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';

/// Use case pour envoyer un message média (image/vidéo/audio)
///
/// Cette opération:
/// - Upload le fichier média
/// - Crée le message avec l'URL du média
/// - Supporte différents types de média (image, video, voice)
///
/// Erreurs possibles:
/// - [ServerFailure]: Erreur lors de l'upload ou l'envoi
/// - [NetworkFailure]: Pas de connexion réseau
@injectable
class SendMediaMessage {
  final MessageRepository repository;

  SendMediaMessage(this.repository);

  Future<Either<Failure, Message>> call(SendMediaMessageParams params) async {
    // Validation côté client
    if (!await params.mediaFile.exists()) {
      return Left(
        ServerFailure(message: 'Le fichier média n\'existe pas'),
      );
    }

    // Validation de la taille du fichier (max 50 MB)
    final fileSizeInBytes = await params.mediaFile.length();
    final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
    if (fileSizeInMB > 50) {
      return Left(
        ServerFailure(
          message: 'Le fichier est trop volumineux (max 50 MB). Taille: ${fileSizeInMB.toStringAsFixed(1)} MB',
        ),
      );
    }

    return await repository.sendMessage(
      conversationId: params.conversationId,
      content: '', // Vide pour les médias
      type: params.type,
      mediaFile: params.mediaFile,
    );
  }
}

class SendMediaMessageParams extends Equatable {
  final String conversationId;
  final File mediaFile;
  final MessageType type;

  const SendMediaMessageParams({
    required this.conversationId,
    required this.mediaFile,
    required this.type,
  });

  /// Factory pour message image
  factory SendMediaMessageParams.image({
    required String conversationId,
    required File imageFile,
  }) {
    return SendMediaMessageParams(
      conversationId: conversationId,
      mediaFile: imageFile,
      type: MessageType.image,
    );
  }

  /// Factory pour message vidéo
  factory SendMediaMessageParams.video({
    required String conversationId,
    required File videoFile,
  }) {
    return SendMediaMessageParams(
      conversationId: conversationId,
      mediaFile: videoFile,
      type: MessageType.video,
    );
  }

  /// Factory pour message vocal
  factory SendMediaMessageParams.voice({
    required String conversationId,
    required File audioFile,
  }) {
    return SendMediaMessageParams(
      conversationId: conversationId,
      mediaFile: audioFile,
      type: MessageType.voice,
    );
  }

  @override
  List<Object> get props => [conversationId, mediaFile, type];
}
