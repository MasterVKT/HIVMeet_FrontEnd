// lib/domain/usecases/resources/get_resources.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/resource.dart';
import 'package:hivmeet/domain/repositories/resource_repository.dart';

/// Use Case pour récupérer les ressources (articles, guides, etc.)
///
/// Permet de charger une liste de ressources avec filtres:
/// - Catégorie
/// - Tags
/// - Recherche par mots-clés
/// - Langue
/// - Type de ressource (article, video, audio, etc.)
///
/// Supporte la pagination classique (page, pageSize).
@injectable
class GetResources {
  final ResourceRepository repository;

  GetResources(this.repository);

  Future<Either<Failure, List<Resource>>> call(
    GetResourcesParams params,
  ) async {
    return await repository.getResources(
      page: params.page,
      pageSize: params.pageSize,
      categoryId: params.categoryId,
      tags: params.tags,
      searchQuery: params.searchQuery,
      language: params.language,
      type: params.type,
    );
  }
}

class GetResourcesParams extends Equatable {
  final int page;
  final int pageSize;
  final String? categoryId;
  final List<String>? tags;
  final String? searchQuery;
  final String? language;
  final ResourceType? type;

  const GetResourcesParams({
    this.page = 1,
    this.pageSize = 20,
    this.categoryId,
    this.tags,
    this.searchQuery,
    this.language,
    this.type,
  });

  /// Factory pour chargement initial (première page)
  factory GetResourcesParams.initial({
    int pageSize = 20,
    String? categoryId,
  }) {
    return GetResourcesParams(
      page: 1,
      pageSize: pageSize,
      categoryId: categoryId,
    );
  }

  /// Factory pour recherche
  factory GetResourcesParams.search({
    required String query,
    int page = 1,
    int pageSize = 20,
  }) {
    return GetResourcesParams(
      page: page,
      pageSize: pageSize,
      searchQuery: query,
    );
  }

  /// Factory pour filtrage par catégorie
  factory GetResourcesParams.byCategory({
    required String categoryId,
    int page = 1,
    int pageSize = 20,
  }) {
    return GetResourcesParams(
      page: page,
      pageSize: pageSize,
      categoryId: categoryId,
    );
  }

  /// Copier avec modification des paramètres
  GetResourcesParams copyWith({
    int? page,
    int? pageSize,
    String? categoryId,
    List<String>? tags,
    String? searchQuery,
    String? language,
    ResourceType? type,
  }) {
    return GetResourcesParams(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      searchQuery: searchQuery ?? this.searchQuery,
      language: language ?? this.language,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [
        page,
        pageSize,
        categoryId,
        tags,
        searchQuery,
        language,
        type,
      ];
}
