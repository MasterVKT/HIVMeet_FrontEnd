// lib/domain/usecases/profile/toggle_profile_visibility.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/repositories/profile_repository.dart';

/// Use Case pour masquer/afficher le profil dans la découverte
///
/// Permet à l'utilisateur de se rendre temporairement invisible:
/// - Masqué (isHidden=true): Le profil n'apparaît plus dans la découverte
/// - Visible (isHidden=false): Le profil redevient visible normalement
///
/// Utile pour prendre une pause sans supprimer le compte.
@injectable
class ToggleProfileVisibility {
  final ProfileRepository repository;

  ToggleProfileVisibility(this.repository);

  Future<Either<Failure, void>> call(
    ToggleProfileVisibilityParams params,
  ) async {
    return await repository.toggleProfileVisibility(params.isHidden);
  }
}

class ToggleProfileVisibilityParams extends Equatable {
  final bool isHidden;

  const ToggleProfileVisibilityParams({required this.isHidden});

  @override
  List<Object> get props => [isHidden];
}
