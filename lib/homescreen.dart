import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gowayanad/services/location_service.dart';
import 'package:gowayanad/services/ride_service.dart';
import 'package:gowayanad/waitingfordriverscreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:gowayanad/utils/fare_calculator.dart';

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

  // Added for Fare Calculation
  bool _isCalculatingFare = false;
  double? _calculatedDistance;
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
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
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
      // 1. Get coordinates for destination
      List<Location> locations = await locationFromAddress(destination);
      if (locations.isNotEmpty) {
        Location destLocation = locations.first;

        // 2. Calculate distance in kilometers
        double distanceInMeters = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          destLocation.latitude,
          destLocation.longitude,
        );

        // Estimating actual route distance using a circuity factor (1.4x straight-line)
        double distanceInKm = (distanceInMeters / 1000) * 1.4;

        if (!mounted) return;

        setState(() {
          _calculatedDistance = distanceInKm;

          // 3. Use FareCalculator for all types
          _vehiclePrices["Bike"] = FareCalculator.calculateFare(
            "Bike",
            distanceInKm,
          ).toStringAsFixed(0);
          _vehiclePrices["Auto"] = FareCalculator.calculateFare(
            "Auto",
            distanceInKm,
          ).toStringAsFixed(0);
          _vehiclePrices["Car"] = FareCalculator.calculateFare(
            "Cab",
            distanceInKm,
          ).toStringAsFixed(0);
          _vehiclePrices["Ambulance"] = FareCalculator.calculateFare(
            "Ambulance",
            distanceInKm,
          ).toStringAsFixed(0);

          _isCalculatingFare = false;

          if (_selectedVehicleType != null) {
            _selectedVehiclePrice = _vehiclePrices[_selectedVehicleType];
          }
        });
      } else {
        throw Exception("No location found for this address");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCalculatingFare = false;
          _statusMessage =
              "Could not find destination. Try a specific landmark.";
        });
        debugPrint("Geocoding error: $e");
      }
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "GoWayanad",
          style: TextStyle(
            color: Color(0xFF2D62ED),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_statusMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _statusMessage = null),
                    ),
                  ],
                ),
              ),

            // Hero Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2D62ED), Color(0xFF5386FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Need a ride?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Select destination and vehicle to start your emergency ride.",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Destination Input
            const Text(
              "Where to?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _destinationController,
              onSubmitted: (value) => _calculateFares(value),
              decoration: InputDecoration(
                hintText: "Enter destination address",
                prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _calculateFares(_destinationController.text),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Vehicle Selection
            const Text(
              "Select Vehicle",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildVehicleCard(
                  "Bike",
                  "Quick response",
                  Icons.directions_bike,
                ),
                _buildVehicleCard(
                  "Auto",
                  "Best for city",
                  Icons.electric_rickshaw,
                ),
                _buildVehicleCard("Car", "Comfortable", Icons.directions_car),
                _buildVehicleCard(
                  "Ambulance",
                  "Emergency",
                  Icons.medical_services,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Request Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    (_isLoadingLocation ||
                        _isCalculatingFare ||
                        _selectedVehicleType == null ||
                        _selectedVehiclePrice == null)
                    ? null
                    : () async {
                        final String dest = _destinationController.text.trim();
                        if (dest.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please enter destination"),
                            ),
                          );
                          return;
                        }

                        setState(() => _isCalculatingFare = true);

                        try {
                          final String? rideId = await RideService()
                              .requestRide(
                                pickupLocation: "Current Location",
                                pickupLat: _currentPosition!.latitude,
                                pickupLng: _currentPosition!.longitude,
                                destination: dest,
                                destinationLat:
                                    0.0, // Should ideally be from Geocoding
                                destinationLng: 0.0,
                                vehicleType: _selectedVehicleType!,
                                distance: _calculatedDistance ?? 0.0,
                                price:
                                    double.tryParse(_selectedVehiclePrice!) ??
                                    0.0,
                              );

                          if (rideId != null && mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WaitingForDriverScreen(rideId: rideId),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: ${e.toString()}")),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isCalculatingFare = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D62ED),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: (_isLoadingLocation || _isCalculatingFare)
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Confirm Emergency Ride",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(String type, String desc, IconData icon) {
    bool isSelected = _selectedVehicleType == type;
    String price = _vehiclePrices[type] ?? "--";

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVehicleType = type;
          _selectedVehiclePrice = price != "--" ? price : null;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F0FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2D62ED) : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 30,
              color: isSelected ? const Color(0xFF2D62ED) : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              type,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF2D62ED) : Colors.black,
              ),
            ),
            if (price != "--")
              Text(
                "₹$price",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D62ED),
                ),
              ),
            Text(
              desc,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
