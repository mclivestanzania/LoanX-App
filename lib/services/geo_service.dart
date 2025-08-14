import 'package:geolocator/geolocator.dart';

/// Provides helper methods for retrieving the device's current location.
///
/// The app stores a textual address on the user profile, but it also stores
/// latitude/longitude coordinates to facilitate matching nearby borrowers and
/// lenders.  Use [getCurrentPosition] to request the current GPS position.
class GeoService {
  /// Requests permission and obtains the current GPS coordinates.
  ///
  /// Throws a [PermissionDeniedException] if the user declines location
  /// permissions.
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
