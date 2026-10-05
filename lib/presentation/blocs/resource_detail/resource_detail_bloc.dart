// lib/presentation/blocs/resource_detail/resource_detail_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/repositories/resource_repository.dart';
import 'package:hivmeet/core/realtime/realtime_event.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/core/services/authentication_service.dart';
import 'dart:async';
import 'resource_detail_event.dart';
import 'resource_detail_state.dart';

@injectable
class ResourceDetailBloc
    extends Bloc<ResourceDetailEvent, ResourceDetailState> {
  final ResourceRepository _resourceRepository;
  final AuthenticationService _authenticationService;
  StreamSubscription<RealtimeEvent>? _subscriptionChanges;
  String? _resourceId;

  ResourceDetailBloc({
    required ResourceRepository resourceRepository,
    required AuthenticationService authenticationService,
    required RealtimeEventBus realtimeBus,
  })  : _resourceRepository = resourceRepository,
        _authenticationService = authenticationService,
        super(ResourceDetailInitial()) {
    on<LoadResourceDetail>(_onLoadResourceDetail);
    on<ToggleResourceFavorite>(_onToggleResourceFavorite);
    _subscriptionChanges = realtimeBus.events.listen((event) {
      final resourceId = _resourceId;
      if (event.type == RealtimeEventType.subscriptionChanged &&
          resourceId != null &&
          !isClosed) {
        add(LoadResourceDetail(resourceId: resourceId));
      }
    });
  }

  Future<void> _onLoadResourceDetail(
    LoadResourceDetail event,
    Emitter<ResourceDetailState> emit,
  ) async {
    _resourceId = event.resourceId;
    emit(ResourceDetailLoading());

    final result =
        await _resourceRepository.getResourceDetail(event.resourceId);

    result.fold(
      (failure) => emit(ResourceDetailError(message: failure.message)),
      (resource) {
        emit(ResourceDetailLoaded(
          resource: resource,
          userHasPremium:
              _authenticationService.currentUser?.isPremiumActive ?? false,
        ));
      },
    );
  }

  @override
  Future<void> close() async {
    await _subscriptionChanges?.cancel();
    return super.close();
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
