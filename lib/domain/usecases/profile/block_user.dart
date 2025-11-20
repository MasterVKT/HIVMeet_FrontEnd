// lib/domain/usecases/profile/block_user.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';

/// Use Case pour bloquer un utilisateur
///
/// Bloque un utilisateur, ce qui entraîne:
/// - L'utilisateur bloqué ne peut plus voir votre profil
/// - Vous ne verrez plus son profil dans la découverte
/// - Les messages existants sont conservés mais plus de nouveaux messages
/// - Le match est dissous (si existant)
///
/// Action irréversible (nécessite déblocage explicite).
@injectable
class BlockUser {
  final ProfileRepository repository;

  BlockUser(this.repository);

  Future<Either<Failure, void>> call(BlockUserParams params) async {
    // Validation: userId non vide
    if (params.userId.trim().isEmpty) {
      return Left(ServerFailure(
        message: 'L\'ID utilisateur est invalide',
      ));
    }

    return await repository.blockUser(params.userId);
  }
}

class BlockUserParams extends Equatable {
  final String userId;

  const BlockUserParams({required this.userId});

  @override
  List<Object> get props => [userId];
}
