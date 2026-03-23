import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gowayanad/services/location_service.dart';
import 'package:gowayanad/services/ride_service.dart';
import 'package:gowayanad/waitingfordriverscreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:gowayanad/utils/fare_calculator.dart';
import 'package:gowayanad/utils/design_system.dart';
import 'package:flutter/foundation.dart';

class RiderBookingScreen extends StatefulWidget {
  const RiderBookingScreen({super.key});

  @override
  State<RiderBookingScreen> createState() => _RiderBookingScreenState();
}

class _RiderBookingScreenState extends State<RiderBookingScreen> {
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  final TextEditingController _destinationController = TextEditingController();
  String? _selectedVehicleType;
  String? _statusMessage;
  String _pickupAddress = "Fetching location...";
  Timer? _debounceTimer;

  bool _isCalculatingFare = false;
  bool _fareCalculated = false;
  double? _calculatedDistance;
  double? _destinationLat;
  double? _destinationLng;

  final Map<String, String> _vehiclePrices = {
    "Bike": "--",
    "Auto": "--",
    "Car": "--",
    "Ambulance": "--",
  };

  String? _selectedVehiclePrice;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      Position position = await LocationService().getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];
        setState(() {
          _pickupAddress =
              "${place.locality ?? place.subAdministrativeArea ?? 'Unknown'}, ${place.administrativeArea ?? ''}";
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _pickupAddress = "Location unavailable";
          _statusMessage = "Could not get your location. Please check GPS.";
        });
      }
    }
  }

  Future<void> _calculateFares(String destination) async {
    if (destination.isEmpty || _currentPosition == null) return;

    setState(() {
      _isCalculatingFare = true;
      _statusMessage = null;
    });

    try {
      List<Location> locations = await locationFromAddress(destination);
      if (locations.isNotEmpty) {
        Location destLocation = locations.first;

        double distanceInMeters = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          destLocation.latitude,
          destLocation.longitude,
        );

        double distanceInKm = (distanceInMeters / 1000) * 1.4;

        if (!mounted) return;

        setState(() {
          _calculatedDistance = distanceInKm;
          _destinationLat = destLocation.latitude;
          _destinationLng = destLocation.longitude;

          _vehiclePrices["Bike"] =
              FareCalculator.calculateFare("Bike", distanceInKm)
                  .toStringAsFixed(0);
          _vehiclePrices["Auto"] =
              FareCalculator.calculateFare("Auto", distanceInKm)
                  .toStringAsFixed(0);
          _vehiclePrices["Car"] =
              FareCalculator.calculateFare("Cab", distanceInKm)
                  .toStringAsFixed(0);
          _vehiclePrices["Ambulance"] =
              FareCalculator.calculateFare("Ambulance", distanceInKm)
                  .toStringAsFixed(0);

          _isCalculatingFare = false;
          _fareCalculated = true;

          if (_selectedVehicleType != null) {
            _selectedVehiclePrice =
                _vehiclePrices[_selectedVehicleType];
          }
        });
      } else {
        throw Exception("No location found");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCalculatingFare = false;
          _statusMessage =
              "Could not find destination. Try a better location.";
        });
        debugPrint("Error: $e");
      }
    }
  }

  void _onDestinationChanged(String value) {
    if (_fareCalculated) {
      setState(() {
        _fareCalculated = false;
        _vehiclePrices.updateAll((key, _) => "--");
        _selectedVehiclePrice = null;
        _calculatedDistance = null;
      });
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      if (value.trim().isNotEmpty) {
        _calculateFares(value.trim());
      }
    });
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text("Book a Ride")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _destinationController,
              onChanged: _onDestinationChanged,
              decoration: const InputDecoration(
                hintText: "Enter destination",
              ),
            ),

            const SizedBox(height: 20),

            if (_calculatedDistance != null)
              Text("Distance: ${_calculatedDistance!.toStringAsFixed(1)} km"),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                final dest = _destinationController.text.trim();

                if (dest.isEmpty || _selectedVehicleType == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Fill all fields")),
                  );
                  return;
                }

                if (!_fareCalculated) {
                  await _calculateFares(dest);
                  if (!_fareCalculated) return;
                }

                try {
                  final rideId = await RideService().requestRide(
                    pickupLocation: _pickupAddress,
                    pickupLat: _currentPosition!.latitude,
                    pickupLng: _currentPosition!.longitude,
                    destination: dest,
                    destinationLat: _destinationLat ?? 0.0,
                    destinationLng: _destinationLng ?? 0.0,
                    vehicleType: _selectedVehicleType!,
                    distance: _calculatedDistance!,
                    price: double.tryParse(
                            _selectedVehiclePrice ?? "0") ??
                        0.0,
                  );

                  if (rideId != null && mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            WaitingForDriverScreen(rideId: rideId),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                } finally {
                  if (mounted) {
                    setState(() => _isCalculatingFare = false);
                  }
                }
              },
              child: const Text("Confirm Booking"),
            )
          ],
        ),
      ),
    );
  }
}