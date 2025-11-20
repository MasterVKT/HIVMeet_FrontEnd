// lib/domain/usecases/message/send_message.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/core/usecases/usecase.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/domain/repositories/message_repository.dart';

/// Use Case pour envoyer un message dans une conversation
///
/// Features:
/// - Envoi de messages texte
/// - Support messages media (images, vidéos, vocaux)
/// - Retourne le message créé avec son ID
///
/// Usage:
/// ```dart
/// final result = await sendMessage(
///   SendMessageParams(
///     conversationId: 'conv_123',
///     content: 'Salut!',
///     type: MessageType.text,
///   )
/// );
/// ```
@injectable
class SendMessage implements UseCase<Message, SendMessageParams> {
  final MessageRepository repository;

  SendMessage(this.repository);

  @override
  Future<Either<Failure, Message>> call(SendMessageParams params) async {
    return await repository.sendMessage(
      conversationId: params.conversationId,
      content: params.content,
      type: params.type,
      mediaUrl: params.mediaUrl,
    );
  }
}

/// Paramètres pour envoyer un message
class SendMessageParams extends Equatable {
  final String conversationId;
  final String content;
  final MessageType type;
  final String? mediaUrl;

  const SendMessageParams({
    required this.conversationId,
    required this.content,
    this.type = MessageType.text,
    this.mediaUrl,
  });

  /// Factory pour message texte simple
  factory SendMessageParams.text({
    required String conversationId,
    required String content,
  }) {
    return SendMessageParams(
      conversationId: conversationId,
      content: content,
      type: MessageType.text,
    );
  }

  /// Factory pour message avec média
  factory SendMessageParams.media({
    required String conversationId,
    required String mediaUrl,
    required MessageType type,
    String content = '',
  }) {
    return SendMessageParams(
      conversationId: conversationId,
      content: content,
      type: type,
      mediaUrl: mediaUrl,
    );
  }

  @override
  List<Object?> get props => [conversationId, content, type, mediaUrl];
}
