// lib/presentation/blocs/resources/resources_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/domain/entities/resource.dart';
import 'package:hivmeet/domain/repositories/resource_repository.dart';
import 'resources_event.dart';
import 'resources_state.dart';

@injectable
class ResourcesBloc extends Bloc<ResourcesEvent, ResourcesState> {
  final ResourceRepository _resourceRepository;
  
  List<ResourceCategory> _categories = [];
  List<Resource> _resources = [];
  int _currentPage = 1;
  String? _selectedCategoryId;
  String? _searchQuery;

  ResourcesBloc({
    required ResourceRepository resourceRepository,
  })  : _resourceRepository = resourceRepository,
        super(ResourcesInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<LoadResources>(_onLoadResources);
    on<LoadMoreResources>(_onLoadMoreResources);
    on<SelectCategory>(_onSelectCategory);
    on<SearchResources>(_onSearchResources);
    on<ToggleFavorite>(_onToggleFavorite);
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<ResourcesState> emit,
  ) async {
    emit(ResourcesLoading());
    
    final categoriesResult = await _resourceRepository.getCategories();
    
    categoriesResult.fold(
      (failure) => emit(ResourcesError(message: failure.message)),
      (categories) async {
        _categories = categories;
        
        // Load initial resources
        final resourcesResult = await _resourceRepository.getResources();
        
        resourcesResult.fold(
          (failure) => emit(ResourcesError(message: failure.message)),
          (resources) {
            _resources = resources;
            _currentPage = 1;
            
            emit(ResourcesLoaded(
              categories: _categories,
              resources: _resources,
              hasMore: resources.length >= 20,
            ));
          },
        );
      },
    );
  }

  Future<void> _onLoadResources(
    LoadResources event,
    Emitter<ResourcesState> emit,
  ) async {
    if (event.refresh) {
      emit(ResourcesLoading());
    }
    
    _currentPage = 1;
    _selectedCategoryId = event.categoryId;
    _searchQuery = event.searchQuery;
    
    final result = await _resourceRepository.getResources(
      page: _currentPage,
      categoryId: event.categoryId,
      searchQuery: event.searchQuery,
      tags: event.tags,
      type: event.type,
    );
    
    result.fold(
      (failure) => emit(ResourcesError(message: failure.message)),
      (resources) {
        _resources = resources;
        
        emit(ResourcesLoaded(
          categories: _categories,
          resources: _resources,
          selectedCategoryId: _selectedCategoryId,
          hasMore: resources.length >= 20,
          searchQuery: _searchQuery,
        ));
      },
    );
  }

  Future<void> _onLoadMoreResources(
    LoadMoreResources event,
    Emitter<ResourcesState> emit,
  ) async {
    final currentState = state;
    if (currentState is ResourcesLoaded && !currentState.isLoadingMore && currentState.hasMore) {
      emit(currentState.copyWith(isLoadingMore: true));
      
      final result = await _resourceRepository.getResources(
        page: ++_currentPage,
        categoryId: _selectedCategoryId,
        searchQuery: _searchQuery,
      );
      
      result.fold(
        (failure) => emit(ResourcesError(message: failure.message)),
        (newResources) {
          _resources.addAll(newResources);
          
          emit(currentState.copyWith(
            resources: List.from(_resources),
            hasMore: newResources.length >= 20,
            isLoadingMore: false,
          ));
        },
      );
    }
  }

  Future<void> _onSelectCategory(
    SelectCategory event,
    Emitter<ResourcesState> emit,
  ) async {
    add(LoadResources(categoryId: event.categoryId));
  }

  Future<void> _onSearchResources(
    SearchResources event,
    Emitter<ResourcesState> emit,
  ) async {
    add(LoadResources(searchQuery: event.query));
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<ResourcesState> emit,
  ) async {
    final currentState = state;
    if (currentState is ResourcesLoaded) {
      final resourceIndex = _resources.indexWhere((r) => r.id == event.resourceId);
      if (resourceIndex != -1) {
        final resource = _resources[resourceIndex];
        
        if (resource.isFavorite) {
          await _resourceRepository.removeFromFavorites(event.resourceId);
        } else {
          await _resourceRepository.addToFavorites(event.resourceId);
        }
        
        _resources[resourceIndex] = resource.copyWith(
          isFavorite: !resource.isFavorite,
        );
        
        emit(currentState.copyWith(resources: List.from(_resources)));
      }
    }
  }
}