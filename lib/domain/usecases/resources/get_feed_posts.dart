// lib/domain/usecases/resources/get_feed_posts.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:hivmeet/core/error/failures.dart';
import 'package:hivmeet/domain/entities/resource.dart';
import 'package:hivmeet/domain/repositories/resource_repository.dart';

/// Use Case pour récupérer les posts du feed communautaire
///
/// Permet de charger les publications de la communauté HIVMeet:
/// - Posts d'utilisateurs
/// - Témoignages
/// - Conseils
/// - Questions/réponses
///
/// Supporte la pagination classique (page, pageSize) et le filtrage par catégorie.
@injectable
class GetFeedPosts {
  final ResourceRepository repository;

  GetFeedPosts(this.repository);

  Future<Either<Failure, List<FeedPost>>> call(
    GetFeedPostsParams params,
  ) async {
    return await repository.getFeedPosts(
      page: params.page,
      pageSize: params.pageSize,
      categoryFilter: params.categoryFilter,
    );
  }
}

class GetFeedPostsParams extends Equatable {
  final int page;
  final int pageSize;
  final String? categoryFilter;

  const GetFeedPostsParams({
    this.page = 1,
    this.pageSize = 20,
    this.categoryFilter,
  });

  /// Factory pour chargement initial (première page)
  factory GetFeedPostsParams.initial({int pageSize = 20}) {
    return GetFeedPostsParams(page: 1, pageSize: pageSize);
  }

  /// Factory pour page suivante
  factory GetFeedPostsParams.nextPage({
    required int page,
    int pageSize = 20,
    String? categoryFilter,
  }) {
    return GetFeedPostsParams(
      page: page,
      pageSize: pageSize,
      categoryFilter: categoryFilter,
    );
  }

  /// Factory pour filtrage par catégorie
  factory GetFeedPostsParams.byCategory({
    required String categoryFilter,
    int page = 1,
    int pageSize = 20,
  }) {
    return GetFeedPostsParams(
      page: page,
      pageSize: pageSize,
      categoryFilter: categoryFilter,
    );
  }

  @override
  List<Object?> get props => [page, pageSize, categoryFilter];
}
