import 'package:equatable/equatable.dart';
import 'package:hivmeet/domain/entities/profile.dart';

/// Entity representing search filter criteria for matching
class SearchFilters extends Equatable {
  final int? minAge;
  final int? maxAge;
  final int? maxDistance;
  final String? gender;
  final List<String>? interests;
  final List<String>? relationshipTypes;
  final bool? verifiedOnly;

  const SearchFilters({
    this.minAge,
    this.maxAge,
    this.maxDistance,
    this.gender,
    this.interests,
    this.relationshipTypes,
    this.verifiedOnly,
  });

  /// Convertit SearchFilters en SearchPreferences pour les opérations du repository
  SearchPreferences toSearchPreferences() {
    return SearchPreferences(
      minAge: minAge ?? 18,
      maxAge: maxAge ?? 65,
      maxDistance: (maxDistance ?? 50).toDouble(),
      interestedIn: gender != null ? [gender!] : [],
      relationshipTypes: relationshipTypes ?? [],
      showVerifiedOnly: verifiedOnly ?? false,
      showOnlineOnly: false,
    );
  }

  @override
  List<Object?> get props => [
        minAge,
        maxAge,
        maxDistance,
        gender,
        interests,
        relationshipTypes,
        verifiedOnly
      ];
}
