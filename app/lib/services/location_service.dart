import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Wraps Geolocator with a clean interface for district spawning + nearby discovery
class LocationService {
  StreamSubscription<Position>? _positionSubscription;

  final _positionController = StreamController<Position>.broadcast();
  Stream<Position> get positionStream => _positionController.stream;

  Position? _lastPosition;
  Position? get lastPosition => _lastPosition;

  /// Check and request location permission
  Future<bool> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    return true;
  }

  /// Check if location permission is already granted
  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Get current position once
  Future<Position?> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _lastPosition = position;
      return position;
    } catch (e) {
      return null;
    }
  }

  /// Start watching position for live map updates
  void startWatching() {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen(
      (position) {
        _lastPosition = position;
        _positionController.add(position);
      },
      onError: (e) {
        // Location error — could be permissions revoked
      },
    );
  }

  /// Stop watching position
  void stopWatching() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Calculate distance between two points in meters
  double distanceBetween(
    double startLat, double startLng,
    double endLat, double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  void dispose() {
    stopWatching();
    _positionController.close();
  }
}
