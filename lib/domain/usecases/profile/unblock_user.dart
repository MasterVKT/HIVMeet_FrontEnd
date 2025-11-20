// lib/domain/usecases/profile/unblock_user.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';

/// Use Case pour débloquer un utilisateur
///
/// Débloque un utilisateur précédemment bloqué.
/// Après déblocage:
/// - L'utilisateur peut à nouveau apparaître dans la découverte
/// - Les deux utilisateurs peuvent se voir mutuellement
/// - Un nouveau match peut se former
@injectable
class UnblockUser {
  final ProfileRepository repository;

  UnblockUser(this.repository);

  Future<Either<Failure, void>> call(UnblockUserParams params) async {
    // Validation: userId non vide
    if (params.userId.trim().isEmpty) {
      return Left(ServerFailure(
        message: 'L\'ID utilisateur est invalide',
      ));
    }

    return await repository.unblockUser(params.userId);
  }
}

class UnblockUserParams extends Equatable {
  final String userId;

  const UnblockUserParams({required this.userId});

  @override
  List<Object> get props => [userId];
}
