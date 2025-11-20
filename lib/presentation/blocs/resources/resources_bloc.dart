// lib/presentation/blocs/resources/resources_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/entities/resource.dart';
import 'package:hivmeet/domain/repositories/resource_repository.dart';
import 'package:hivmeet/core/error/failures.dart';

part 'resources_event.dart';
part 'resources_state.dart';

@injectable
class ResourcesBloc extends Bloc<ResourcesEvent, ResourcesState> {
  final ResourceRepository _repository;

  ResourcesBloc(this._repository) : super(ResourcesInitial()) {
    on<LoadResources>(_onLoadResources);
    on<SearchResources>(_onSearchResources);
    on<AddFavorite>(_onAddFavorite);
  }

  void _onLoadResources(
      LoadResources event, Emitter<ResourcesState> emit) async {
    emit(ResourcesLoading());

    final result = await _repository.getResources(
      categoryId: event.category,
    );

    result.fold(
      (failure) => emit(ResourcesError(message: _mapFailureToMessage(failure))),
      (resources) => emit(ResourcesLoaded(resources: resources)),
    );
  }

  void _onSearchResources(
      SearchResources event, Emitter<ResourcesState> emit) async {
    emit(ResourcesLoading());

    final result = await _repository.getResources(
      searchQuery: event.query,
    );

    result.fold(
      (failure) => emit(ResourcesError(message: _mapFailureToMessage(failure))),
      (resources) => emit(ResourcesLoaded(resources: resources)),
    );
  }

  void _onAddFavorite(AddFavorite event, Emitter<ResourcesState> emit) async {
    final result = await _repository.addToFavorites(event.resourceId);

    result.fold(
      (failure) => emit(ResourcesError(message: _mapFailureToMessage(failure))),
      (_) {
        // Refresh list if needed
        add(LoadResources(null));
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Erreur de serveur. Veuillez réessayer.';
      case NetworkFailure:
        return 'Erreur de connexion. Vérifiez votre réseau.';
      case CacheFailure:
        return 'Erreur de cache local.';
      default:
        return 'Une erreur inattendue s\'est produite.';
    }
  }
}
