// lib/domain/usecases/resources/comment_post.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/resource.dart';
import 'package:hivmeet/domain/repositories/resource_repository.dart';

/// Use Case pour commenter un post du feed
///
/// Permet à l'utilisateur d'ajouter un commentaire textuel sur un post.
/// Le commentaire est visible par tous les utilisateurs qui consultent le post.
///
/// Validations côté client:
/// - Le contenu ne peut pas être vide
/// - Maximum 500 caractères (si défini dans les specs)
@injectable
class CommentPost {
  final ResourceRepository repository;

  CommentPost(this.repository);

  Future<Either<Failure, PostComment>> call(CommentPostParams params) async {
    // Validation côté client
    if (params.content.trim().isEmpty) {
      return Left(ServerFailure(
        message: 'Le commentaire ne peut pas être vide',
      ));
    }

    // Limite de caractères (ajustable selon specs)
    if (params.content.length > 500) {
      return Left(ServerFailure(
        message: 'Le commentaire ne peut pas dépasser 500 caractères',
      ));
    }

    return await repository.addComment(
      postId: params.postId,
      content: params.content,
    );
  }
}

class CommentPostParams extends Equatable {
  final String postId;
  final String content;

  const CommentPostParams({
    required this.postId,
    required this.content,
  });

  @override
  List<Object> get props => [postId, content];
}
