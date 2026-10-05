import 'package:equatable/equatable.dart';

class LocationCountry extends Equatable {
  final String code;
  final String label;
  final String catalogVersion;

  const LocationCountry({
    required this.code,
    required this.label,
    required this.catalogVersion,
  });

  @override
  List<Object> get props => [code, label, catalogVersion];
}

class LocationCity extends Equatable {
  final int id;
  final String name;
  final String countryCode;
  final String countryName;

  const LocationCity({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.countryName,
  });

  @override
  List<Object> get props => [id, name, countryCode, countryName];
}

/// A location update is deliberately distinct from profile text fields.  This
/// prevents free-form city values from accidentally replacing catalog data.
class ProfileLocationUpdate extends Equatable {
  final bool locationEnabled;
  final int? cityId;
  final double? latitude;
  final double? longitude;
  final int? accuracyMeters;

  const ProfileLocationUpdate.manual({required this.cityId})
      : locationEnabled = false,
        latitude = null,
        longitude = null,
        accuracyMeters = null;

  const ProfileLocationUpdate.disabled()
      : locationEnabled = false,
        cityId = null,
        latitude = null,
        longitude = null,
        accuracyMeters = null;

  const ProfileLocationUpdate.automatic({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
  })  : locationEnabled = true,
        cityId = null;

  Map<String, dynamic> toJson() => {
        'location_enabled': locationEnabled,
        if (cityId != null) 'city_id': cityId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (accuracyMeters != null) 'accuracy_m': accuracyMeters,
      };

  @override
  List<Object?> get props =>
      [locationEnabled, cityId, latitude, longitude, accuracyMeters];
}
