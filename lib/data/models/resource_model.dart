import 'package:json_annotation/json_annotation.dart';
import 'package:hivmeet/domain/entities/resource.dart';

part 'resource_model.g.dart';

@JsonSerializable()
class ResourceModel {
  final String id;
  final String title;
  @JsonKey(
      name: 'resource_type',
      fromJson: _resourceTypeFromString,
      toJson: _resourceTypeToString)
  final ResourceType type;
  @JsonKey(name: 'category_id')
  final String categoryId;
  @JsonKey(name: 'category_name')
  final String categoryName;
  final List<String> tags;
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;
  @JsonKey(
      name: 'publication_date',
      fromJson: _fromDateTimeString,
      toJson: _toDateTimeString)
  final DateTime publicationDate;
  @JsonKey(
      name: 'last_updated_at',
      fromJson: _fromDateTimeStringNullable,
      toJson: _toDateTimeStringNullable)
  final DateTime? lastUpdatedAt;
  @JsonKey(name: 'author_name')
  final String? authorName;
  @JsonKey(name: 'is_premium')
  final bool isPremium;
  @JsonKey(name: 'is_verified_expert')
  final bool isVerifiedExpert;
  final String language;
  final String content;
  @JsonKey(name: 'external_link')
  final String? externalLink;
  @JsonKey(name: 'view_count')
  final int viewCount;
  @JsonKey(name: 'is_favorite')
  final bool isFavorite;
  @JsonKey(name: 'estimated_read_time_minutes')
  final int? estimatedReadTimeMinutes;

  const ResourceModel({
    required this.id,
    required this.title,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.tags,
    this.thumbnailUrl,
    required this.publicationDate,
    this.lastUpdatedAt,
    this.authorName,
    required this.isPremium,
    required this.isVerifiedExpert,
    required this.language,
    required this.content,
    this.externalLink,
    required this.viewCount,
    required this.isFavorite,
    this.estimatedReadTimeMinutes,
  });

  factory ResourceModel.fromJson(Map<String, dynamic> json) =>
      _$ResourceModelFromJson(json);

  Map<String, dynamic> toJson() => _$ResourceModelToJson(this);

  factory ResourceModel.fromEntity(Resource resource) {
    return ResourceModel(
      id: resource.id,
      title: resource.title,
      type: resource.type,
      categoryId: resource.categoryId,
      categoryName: resource.categoryName,
      tags: resource.tags,
      thumbnailUrl: resource.thumbnailUrl,
      publicationDate: resource.publicationDate,
      lastUpdatedAt: resource.lastUpdatedAt,
      authorName: resource.authorName,
      isPremium: resource.isPremium,
      isVerifiedExpert: resource.isVerifiedExpert,
      language: resource.language,
      content: resource.content,
      externalLink: resource.externalLink,
      viewCount: resource.viewCount,
      isFavorite: resource.isFavorite,
      estimatedReadTimeMinutes: resource.estimatedReadTimeMinutes,
    );
  }

  Resource toEntity() {
    return Resource(
      id: id,
      title: title,
      type: type,
      categoryId: categoryId,
      categoryName: categoryName,
      tags: tags,
      thumbnailUrl: thumbnailUrl,
      publicationDate: publicationDate,
      lastUpdatedAt: lastUpdatedAt,
      authorName: authorName,
      isPremium: isPremium,
      isVerifiedExpert: isVerifiedExpert,
      language: language,
      content: content,
      externalLink: externalLink,
      viewCount: viewCount,
      isFavorite: isFavorite,
      estimatedReadTimeMinutes: estimatedReadTimeMinutes,
      relatedResources: null, // TODO: Implémenter si nécessaire
    );
  }

  static DateTime _fromDateTimeString(String dateTimeString) {
    return DateTime.parse(dateTimeString);
  }

  static String _toDateTimeString(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  static DateTime? _fromDateTimeStringNullable(String? dateTimeString) {
    return dateTimeString != null ? DateTime.parse(dateTimeString) : null;
  }

  static String? _toDateTimeStringNullable(DateTime? dateTime) {
    return dateTime?.toIso8601String();
  }

  static ResourceType _resourceTypeFromString(String type) {
    switch (type) {
      case 'article':
        return ResourceType.article;
      case 'video':
        return ResourceType.video;
      case 'link':
        return ResourceType.link;
      case 'contact':
        return ResourceType.contact;
      default:
        return ResourceType.article;
    }
  }

  static String _resourceTypeToString(ResourceType type) {
    switch (type) {
      case ResourceType.article:
        return 'article';
      case ResourceType.video:
        return 'video';
      case ResourceType.link:
        return 'link';
      case ResourceType.contact:
        return 'contact';
    }
  }
}

@JsonSerializable()
class ResourceCategoryModel {
  final String id;
  final String name;
  final String? description;
  @JsonKey(name: 'icon_url')
  final String? iconUrl;
  @JsonKey(name: 'resource_count')
  final int resourceCount;
  @JsonKey(name: 'is_premium_only')
  final bool isPremiumOnly;

  const ResourceCategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    required this.resourceCount,
    required this.isPremiumOnly,
  });

  factory ResourceCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$ResourceCategoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$ResourceCategoryModelToJson(this);

  factory ResourceCategoryModel.fromEntity(ResourceCategory category) {
    return ResourceCategoryModel(
      id: category.id,
      name: category.name,
      description: category.description,
      iconUrl: category.iconUrl,
      resourceCount: category.resourceCount,
      isPremiumOnly: category.isPremiumOnly,
    );
  }

  ResourceCategory toEntity() {
    return ResourceCategory(
      id: id,
      name: name,
      description: description,
      iconUrl: iconUrl,
      resourceCount: resourceCount,
      isPremiumOnly: isPremiumOnly,
    );
  }
}
