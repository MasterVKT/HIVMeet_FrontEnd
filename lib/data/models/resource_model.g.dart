// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResourceModel _$ResourceModelFromJson(Map<String, dynamic> json) =>
    ResourceModel(
      id: json['id'] as String,
      title: json['title'] as String,
      type: ResourceModel._resourceTypeFromString(
          json['resource_type'] as String),
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      thumbnailUrl: json['thumbnail_url'] as String?,
      publicationDate:
          ResourceModel._fromDateTimeString(json['publication_date'] as String),
      lastUpdatedAt: ResourceModel._fromDateTimeStringNullable(
          json['last_updated_at'] as String?),
      authorName: json['author_name'] as String?,
      isPremium: json['is_premium'] as bool,
      isVerifiedExpert: json['is_verified_expert'] as bool,
      language: json['language'] as String,
      content: json['content'] as String,
      externalLink: json['external_link'] as String?,
      viewCount: (json['view_count'] as num).toInt(),
      isFavorite: json['is_favorite'] as bool,
      estimatedReadTimeMinutes:
          (json['estimated_read_time_minutes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ResourceModelToJson(ResourceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'resource_type': ResourceModel._resourceTypeToString(instance.type),
      'category_id': instance.categoryId,
      'category_name': instance.categoryName,
      'tags': instance.tags,
      'thumbnail_url': instance.thumbnailUrl,
      'publication_date':
          ResourceModel._toDateTimeString(instance.publicationDate),
      'last_updated_at':
          ResourceModel._toDateTimeStringNullable(instance.lastUpdatedAt),
      'author_name': instance.authorName,
      'is_premium': instance.isPremium,
      'is_verified_expert': instance.isVerifiedExpert,
      'language': instance.language,
      'content': instance.content,
      'external_link': instance.externalLink,
      'view_count': instance.viewCount,
      'is_favorite': instance.isFavorite,
      'estimated_read_time_minutes': instance.estimatedReadTimeMinutes,
    };

ResourceCategoryModel _$ResourceCategoryModelFromJson(
        Map<String, dynamic> json) =>
    ResourceCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      resourceCount: (json['resource_count'] as num).toInt(),
      isPremiumOnly: json['is_premium_only'] as bool,
    );

Map<String, dynamic> _$ResourceCategoryModelToJson(
        ResourceCategoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'icon_url': instance.iconUrl,
      'resource_count': instance.resourceCount,
      'is_premium_only': instance.isPremiumOnly,
    };
