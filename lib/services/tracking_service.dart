import 'dart:async';
import 'package:gowayanad/services/ride_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TrackingService {
  Timer? _timer;
  final RideService _rideService = RideService();

  void startSimulatedTracking(String rideId, LatLng start, LatLng end) {
    _timer?.cancel();
    int steps = 20;
    int currentStep = 0;

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (currentStep >= steps) {
        timer.cancel();
        return;
      }

      double lat =
          start.latitude +
          (end.latitude - start.latitude) * (currentStep / steps);
      double lng =
          start.longitude +
          (end.longitude - start.longitude) * (currentStep / steps);

      _rideService.updateDriverLocation(rideId, lat, lng);
      currentStep++;
    });
  }

  void stopTracking() {
    _timer?.cancel();
  }
}
