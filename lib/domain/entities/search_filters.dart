import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/profile.dart';

/// Entity representing search filter criteria for matching
class SearchFilters extends Equatable {
  final int? minAge;
  final int? maxAge;
  final int? maxDistance;
  final List<String>? genders;
  final List<String>? interests;
  final List<String>? relationshipTypes;
  final bool? verifiedOnly;
  final bool? onlineOnly;

  const SearchFilters({
    this.minAge,
    this.maxAge,
    this.maxDistance,
    this.genders,
    this.interests,
    this.relationshipTypes,
    this.verifiedOnly,
    this.onlineOnly,
  });

  static const int minAllowedAge = 18;
  static const int maxAllowedAge = 99;
  static const int minAllowedDistanceKm = 5;
  static const int maxAllowedDistanceKm = 100;

  /// Retourne un message d'erreur si les bornes sont invalides.
  String? validate() {
    final effectiveMinAge = minAge ?? minAllowedAge;
    final effectiveMaxAge = maxAge ?? maxAllowedAge;
    final effectiveDistance = maxDistance ?? 50;

    if (effectiveMinAge < minAllowedAge || effectiveMinAge > maxAllowedAge) {
      return 'age_min must be between $minAllowedAge and $maxAllowedAge';
    }
    if (effectiveMaxAge < minAllowedAge || effectiveMaxAge > maxAllowedAge) {
      return 'age_max must be between $minAllowedAge and $maxAllowedAge';
    }
    if (effectiveMinAge > effectiveMaxAge) {
      return 'age_min must be less than or equal to age_max';
    }
    if (effectiveDistance < minAllowedDistanceKm ||
        effectiveDistance > maxAllowedDistanceKm) {
      return 'distance_max_km must be between $minAllowedDistanceKm and $maxAllowedDistanceKm';
    }
    return null;
  }

  SearchFilters normalized() {
    final normalizedGenders = (genders ?? const <String>[])
        .where((g) => g != 'all')
        .toList(growable: false);
    final normalizedRelationshipTypes = (relationshipTypes ?? const <String>[])
        .where((r) => r != 'all')
        .toList(growable: false);

    return SearchFilters(
      minAge: minAge,
      maxAge: maxAge,
      maxDistance: maxDistance,
      genders: normalizedGenders,
      interests: interests,
      relationshipTypes: normalizedRelationshipTypes,
      verifiedOnly: verifiedOnly,
      onlineOnly: onlineOnly,
    );
  }

  /// Convertit SearchFilters en SearchPreferences pour les opérations du repository
  SearchPreferences toSearchPreferences() {
    final normalizedFilters = normalized();
    return SearchPreferences(
      minAge: normalizedFilters.minAge ?? minAllowedAge,
      maxAge: normalizedFilters.maxAge ?? maxAllowedAge,
      maxDistance: (normalizedFilters.maxDistance ?? 50).toDouble(),
      interestedIn: normalizedFilters.genders ?? const <String>[],
      relationshipTypes:
          normalizedFilters.relationshipTypes ?? const <String>[],
      showVerifiedOnly: normalizedFilters.verifiedOnly ?? false,
      showOnlineOnly: normalizedFilters.onlineOnly ?? false,
    );
  }

  factory SearchFilters.fromSearchPreferences(SearchPreferences preferences) {
    return SearchFilters(
      minAge: preferences.minAge,
      maxAge: preferences.maxAge,
      maxDistance: preferences.maxDistance.round(),
      genders: List<String>.from(preferences.interestedIn),
      relationshipTypes: List<String>.from(preferences.relationshipTypes),
      verifiedOnly: preferences.showVerifiedOnly,
      onlineOnly: preferences.showOnlineOnly,
    );
  }

  @override
  List<Object?> get props => [
        minAge,
        maxAge,
        maxDistance,
        genders,
        interests,
        relationshipTypes,
        verifiedOnly,
        onlineOnly,
      ];
}
