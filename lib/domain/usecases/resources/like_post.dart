// lib/domain/usecases/resources/like_post.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/resource_repository.dart';

/// Use Case pour liker un post du feed
///
/// Permet à l'utilisateur de manifester son soutien ou son accord avec un post.
/// Le like est enregistré côté serveur et incrémente le compteur de likes du post.
///
/// Note: Pour retirer un like, utiliser UnlikePost.
@injectable
class LikePost {
  final ResourceRepository repository;

  LikePost(this.repository);

  Future<Either<Failure, void>> call(LikePostParams params) async {
    return await repository.likePost(params.postId);
  }
}

class LikePostParams extends Equatable {
  final String postId;

  const LikePostParams({required this.postId});

  @override
  List<Object> get props => [postId];
}
