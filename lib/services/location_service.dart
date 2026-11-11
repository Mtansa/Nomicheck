import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  static Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkPermission();
    if (!hasPermission) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  static bool isWithinRadius(
    double currentLat,
    double currentLon,
    double workLat,
    double workLon,
    double radius,
  ) {
    final distance = calculateDistance(currentLat, currentLon, workLat, workLon);
    return distance <= radius;
  }

  static Future<Map<String, dynamic>> validateLocation({
    required double? workLat,
    required double? workLon,
    required double radius,
  }) async {
    if (workLat == null || workLon == null) {
      return {
        'valid': false,
        'message': 'Ubicación de trabajo no configurada',
        'distance': null,
      };
    }

    final position = await getCurrentPosition();
    if (position == null) {
      return {
        'valid': false,
        'message': 'No se pudo obtener ubicación actual',
        'distance': null,
      };
    }

    final distance = calculateDistance(
      position.latitude,
      position.longitude,
      workLat,
      workLon,
    );

    return {
      'valid': distance <= radius,
      'message': distance <= radius
          ? 'Ubicación válida'
          : 'Estás a ${distance.toStringAsFixed(0)}m del lugar de trabajo',
      'distance': distance,
      'position': position,
    };
  }
}
