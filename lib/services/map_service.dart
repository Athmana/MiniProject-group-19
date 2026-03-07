import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapService {
  static const String _apiKey = "YOUR_GOOGLE_MAPS_API_KEY_HERE";

  Future<List<LatLng>> getRoutePolylines(LatLng start, LatLng end) async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints(apiKey: _apiKey);

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(start.latitude, start.longitude),
        destination: PointLatLng(end.latitude, end.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    return polylineCoordinates;
  }

  Future<Map<String, dynamic>?> getDistanceAndETA(
    LatLng start,
    LatLng end,
  ) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/distancematrix/json?origins=${start.latitude},${start.longitude}&destinations=${end.latitude},${end.longitude}&key=$_apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final element = data['rows'][0]['elements'][0];
          if (element['status'] == 'OK') {
            return {
              'distance': element['distance']['text'],
              'duration': element['duration']['text'],
            };
          }
        }
      }
    } catch (e) {
      print('Error fetching distance and ETA: $e');
    }
    return null;
  }
}
