import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class MapService {
  final String _googleApiKey = "AIzaSyDVkYPkZmZ59cV--yFQ1ysmAYOALBfMXaY";

  Future<List<LatLng>> getPolylinePoints(
    LatLng pickup,
    LatLng destination,
  ) async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: _googleApiKey,
      request: PolylineRequest(
        origin: PointLatLng(pickup.latitude, pickup.longitude),
        destination: PointLatLng(destination.latitude, destination.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    } else {
      debugPrint("Polyline Error: ${result.errorMessage}");
    }
    return polylineCoordinates;
  }

  Future<double> calculateDistance(
    String destination,
    Position currentPosition,
  ) async {
    try {
      List<Location> locations = await locationFromAddress(destination);
      if (locations.isNotEmpty) {
        double distanceInMeters = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          locations[0].latitude,
          locations[0].longitude,
        );
        return distanceInMeters / 1000; // Return distance in km
      }
      return -1;
    } catch (e) {
      debugPrint("Error calculating distance: $e");
      return -1;
    }
  }
}
