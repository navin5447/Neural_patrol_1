import 'package:geolocator/geolocator.dart';

/// Wraps GPS capture for evidence metadata. Field conditions (indoors,
/// permission denied, GPS off) are common, so every failure path returns
/// null rather than throwing — the calling screen decides whether to block
/// on a location fix or let the officer proceed without one.
class LocationService {
  Future<Position?> capture() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 8)),
      );
    } catch (_) {
      return null;
    }
  }
}
