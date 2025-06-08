// lib/presentation/blocs/resource_detail/resource_detail_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/repositories/resource_repository.dart';
import 'resource_detail_event.dart';
import 'resource_detail_state.dart';

@injectable
class ResourceDetailBloc extends Bloc<ResourceDetailEvent, ResourceDetailState> {
  final ResourceRepository _resourceRepository;

  ResourceDetailBloc({
    required ResourceRepository resourceRepository,
  })  : _resourceRepository = resourceRepository,
        super(ResourceDetailInitial()) {
    on<LoadResourceDetail>(_onLoadResourceDetail);
    on<ToggleResourceFavorite>(_onToggleResourceFavorite);
  }

  Future<void> _onLoadResourceDetail(
    LoadResourceDetail event,
    Emitter<ResourceDetailState> emit,
  ) async {
    emit(ResourceDetailLoading());
    
    final result = await _resourceRepository.getResourceDetail(event.resourceId);
    
    result.fold(
      (failure) => emit(ResourceDetailError(message: failure.message)),
      (resource) {
        // TODO: Check user premium status
        emit(ResourceDetailLoaded(
          resource: resource,
          userHasPremium: true, // TODO: Get from user profile
        ));
      },
    );
  }

  Future<void> _onToggleResourceFavorite(
    ToggleResourceFavorite event,
    Emitter<ResourceDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is ResourceDetailLoaded) {
      final resource = currentState.resource;
      
      if (resource.isFavorite) {
        await _resourceRepository.removeFromFavorites(event.resourceId);
      } else {
        await _resourceRepository.addToFavorites(event.resourceId);
      }
      
      emit(currentState.copyWith(
        resource: resource.copyWith(isFavorite: !resource.isFavorite),
      ));
    }
  }
}