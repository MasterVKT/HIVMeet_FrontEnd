import 'package:geolocator/geolocator.dart';

sealed class ForegroundLocationResult {
  const ForegroundLocationResult();
}

class ForegroundLocationReady extends ForegroundLocationResult {
  final double latitude;
  final double longitude;
  final int accuracyMeters;

  const ForegroundLocationReady({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
  });
}

class ForegroundLocationUnavailable extends ForegroundLocationResult {
  final ForegroundLocationFailure reason;
  const ForegroundLocationUnavailable(this.reason);
}

enum ForegroundLocationFailure { serviceDisabled, denied, deniedForever }

/// Obtains one foreground reading only. Permission is requested by this method,
/// which callers invoke from an explicit user action (never on page startup).
class ForegroundLocationService {
  const ForegroundLocationService();

  Future<ForegroundLocationResult> requestCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const ForegroundLocationUnavailable(
        ForegroundLocationFailure.serviceDisabled,
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return const ForegroundLocationUnavailable(
        ForegroundLocationFailure.deniedForever,
      );
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return const ForegroundLocationUnavailable(
          ForegroundLocationFailure.denied);
    }
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return ForegroundLocationReady(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy.round(),
    );
  }
}
