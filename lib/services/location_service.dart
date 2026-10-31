import 'package:geolocator/geolocator.dart';

class LocationService {
  // ================================================================
  // GET CURRENT LOCATION
  // ================================================================

  Future<Position?> getCurrentLocation() async {
    final permissionGranted = await _ensureLocationPermission();

    if (!permissionGranted) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // ================================================================
  // CONTINUOUS LOCATION STREAM
  // ================================================================

  Stream<Position> getLocationStream() async* {
    final permissionGranted = await _ensureLocationPermission();

    if (!permissionGranted) {
      return;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    yield* Geolocator.getPositionStream(
      locationSettings: locationSettings,
    );
  }

  // ================================================================
  // CHECK / REQUEST PERMISSION
  // ================================================================

  Future<bool> _ensureLocationPermission() async {
    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return false;
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  // ================================================================
  // OPEN LOCATION SETTINGS
  // ================================================================

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // ================================================================
  // OPEN APP SETTINGS
  // ================================================================

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  // ================================================================
  // DISTANCE
  // ================================================================

  double distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(
          lat1,
          lon1,
          lat2,
          lon2,
        ) /
        1000;
  }
}