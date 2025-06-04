// lib/core/usecases/usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:hivmeet/core/error/failures.dart';

/// Interface de base pour tous les use cases
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Classe utilisée quand un use case n'a pas de paramètres
class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}