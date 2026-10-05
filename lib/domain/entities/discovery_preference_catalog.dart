import 'package:hivmeet/domain/entities/profile.dart';

/// The only values accepted by the discovery/profile preference contract.
///
/// The API stores an empty list for the inclusive "everyone" choice.  Keeping
/// that conversion in one place prevents Profile, onboarding and Discovery
/// from gradually accepting different values.
abstract final class DiscoveryPreferenceCatalog {
  static const String everyone = 'all';

  static const List<String> genderValues = <String>[
    Gender.male,
    Gender.female,
  ];

  static const List<String> relationshipValues = <String>[
    RelationshipType.friendship,
    RelationshipType.longTerm,
    RelationshipType.shortTerm,
    RelationshipType.casualDating,
  ];

  static List<String> genderPayload(String selection) =>
      genderValues.contains(selection) ? <String>[selection] : <String>[];

  static List<String> relationshipPayload(String selection) =>
      relationshipValues.contains(selection) ? <String>[selection] : <String>[];

  static String genderSelection(Iterable<String>? values) {
    final selected =
        values?.where(genderValues.contains).toList() ?? const <String>[];
    return selected.length == 1 ? selected.single : everyone;
  }

  static String relationshipSelection(Iterable<String>? values) {
    final selected =
        values?.where(relationshipValues.contains).toList() ?? const <String>[];
    return selected.length == 1 ? selected.single : everyone;
  }

  static String genderLabelKey(String value) => switch (value) {
        Gender.male => 'gender.male',
        Gender.female => 'gender.female',
        _ => 'gender.all',
      };

  static String relationshipLabelKey(String value) => switch (value) {
        RelationshipType.friendship => 'profile.relationship_friendship',
        RelationshipType.longTerm => 'profile.relationship_long_term',
        RelationshipType.shortTerm => 'profile.relationship_short_term',
        RelationshipType.casualDating => 'profile.relationship_casual',
        _ => 'common.all',
      };
}
