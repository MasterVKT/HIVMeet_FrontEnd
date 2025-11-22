// lib/presentation/blocs/resources/resources_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/entities/resource.dart';
import 'package:hivmeet/domain/usecases/resources/get_resources.dart';
import 'package:hivmeet/domain/usecases/resources/add_to_favorites.dart';
import 'package:hivmeet/core/error/failures.dart';

part 'resources_event.dart';
part 'resources_state.dart';

@injectable
class ResourcesBloc extends Bloc<ResourcesEvent, ResourcesState> {
  final GetResources _getResources;
  final AddToFavorites _addToFavorites;

  ResourcesBloc({
    required GetResources getResources,
    required AddToFavorites addToFavorites,
  })  : _getResources = getResources,
        _addToFavorites = addToFavorites,
        super(ResourcesInitial()) {
    on<LoadResources>(_onLoadResources);
    on<SearchResources>(_onSearchResources);
    on<AddFavorite>(_onAddFavorite);
  }

  void _onLoadResources(
      LoadResources event, Emitter<ResourcesState> emit) async {
    emit(ResourcesLoading());

    final params = event.category != null
        ? GetResourcesParams.byCategory(categoryId: event.category!)
        : GetResourcesParams.initial();

    final result = await _getResources(params);

    result.fold(
      (failure) => emit(ResourcesError(message: _mapFailureToMessage(failure))),
      (resources) => emit(ResourcesLoaded(resources: resources)),
    );
  }

  void _onSearchResources(
      SearchResources event, Emitter<ResourcesState> emit) async {
    emit(ResourcesLoading());

    final params = GetResourcesParams.search(query: event.query);
    final result = await _getResources(params);

    result.fold(
      (failure) => emit(ResourcesError(message: _mapFailureToMessage(failure))),
      (resources) => emit(ResourcesLoaded(resources: resources)),
    );
  }

  void _onAddFavorite(AddFavorite event, Emitter<ResourcesState> emit) async {
    final params = AddToFavoritesParams(resourceId: event.resourceId);
    final result = await _addToFavorites(params);

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
