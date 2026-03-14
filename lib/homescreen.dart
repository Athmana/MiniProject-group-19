import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gowayanad/services/location_service.dart';
import 'package:gowayanad/services/ride_service.dart';
import 'package:gowayanad/waitingfordriverscreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:gowayanad/utils/fare_calculator.dart';

class CabBookingHome extends StatefulWidget {
  const CabBookingHome({super.key});

  @override
  State<CabBookingHome> createState() => _CabBookingHomeState();
}

class _CabBookingHomeState extends State<CabBookingHome> {
  Position? _currentPosition;
  bool _isLoadingLocation = true;

  final TextEditingController _destinationController = TextEditingController();
  String? _selectedVehicleType;
  String? _selectedVehiclePrice;

  Timer? _debounce;

  double? _calculatedDistance;
  final Map<String, String> _vehiclePrices = {
    "Bike": "...",
    "Auto": "...",
    "Car": "...",
    "Ambulance": "...",
  };
  bool _isCalculatingFare = false;

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
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      }
    }
  }

  Future<void> _calculateFares(String destination) async {
    if (destination.isEmpty || _currentPosition == null) return;

    setState(() {
      _isCalculatingFare = true;
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
        double distanceInKm = distanceInMeters / 1000;

        if (!mounted) return;

        setState(() {
          _calculatedDistance = distanceInKm;

          // 3. Use FareCalculator for all types
          // Note: UI uses "Car" but calculator expects "Cab" or "Car"
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
          ).toStringAsFixed(0); // Using "Cab" rate for "Car"
          _vehiclePrices["Ambulance"] = FareCalculator.calculateFare(
            "Ambulance",
            distanceInKm,
          ).toStringAsFixed(0);

          _isCalculatingFare = false;

          if (_selectedVehicleType != null) {
            _selectedVehiclePrice = _vehiclePrices[_selectedVehicleType];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCalculatingFare = false;
        });
        print("Geocoding error: $e");
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Book Your Ride",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              "Emergency Service",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Map Preview
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_rounded,
                    size: 64,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Ready to Ride",
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    "Your location is verified",
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // Destination Input
            TextField(
              controller: _destinationController,
              onChanged: (value) {
                // Debounce: wait 800ms after user stops typing before calling API
                _debounce?.cancel();
                if (value.length > 3) {
                  _debounce = Timer(const Duration(milliseconds: 800), () {
                    _calculateFares(value);
                  });
                }
              },
              decoration: InputDecoration(
                hintText: "Enter destination address",
                suffixIcon: _isCalculatingFare
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : (_calculatedDistance != null
                          ? Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                "${_calculatedDistance!.toStringAsFixed(1)} km",
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null),
                prefixIcon: const Icon(
                  Icons.near_me_outlined,
                  color: Colors.cyan,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Vehicle Selection Grid
            const Text(
              "Select Vehicle Type",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
              children: [
                _buildVehicleCard(
                  title: "Bike",
                  desc: "Quick emergency response",
                  price: _vehiclePrices["Bike"]!,
                  seats: "1 seat",
                  time: "1-2 min",
                  icon: Icons.directions_bike,
                ),
                _buildVehicleCard(
                  title: "Auto",
                  desc: "Quick emergency response",
                  price: _vehiclePrices["Auto"]!,
                  seats: "3 seats",
                  time: "2-4 min",
                  icon: Icons.electric_rickshaw,
                ),
                _buildVehicleCard(
                  title: "Car",
                  desc: "Comfortable transport",
                  price: _vehiclePrices["Car"]!,
                  seats: "4 seats",
                  time: "3-5 min",
                  icon: Icons.directions_car,
                ),
                _buildVehicleCard(
                  title: "Ambulance",
                  desc: "Medical emergency",
                  price: _vehiclePrices["Ambulance"]!,
                  seats: "2 seats",
                  time: "1-2 min",
                  icon: Icons.medical_services,
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Confirm Ride Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  if (_currentPosition == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fetching location... please wait'),
                      ),
                    );
                    return;
                  }
                  if (_destinationController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a destination'),
                      ),
                    );
                    return;
                  }
                  if (_isCalculatingFare) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Calculating fares... please wait'),
                      ),
                    );
                    return;
                  }
                  if (_selectedVehiclePrice == "..." ||
                      _selectedVehiclePrice == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter a valid destination to calculate fares',
                        ),
                      ),
                    );
                    return;
                  }
                  if (_selectedVehicleType == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a vehicle type'),
                      ),
                    );
                    return;
                  }

                  final String? rideId = await RideService().requestRide(
                    pickupLocation:
                        "Lat: ${_currentPosition!.latitude}, Lng: ${_currentPosition!.longitude}",
                    pickupLat: _currentPosition!.latitude,
                    pickupLng: _currentPosition!.longitude,
                    destination: _destinationController.text.trim(),
                    destinationLat: 0.0,
                    destinationLng: 0.0,
                    vehicleType: _selectedVehicleType!,
                    price: _selectedVehiclePrice!,
                    distance: _calculatedDistance ?? 0.0,
                  );

                  if (rideId != null && context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            WaitingForDriverScreen(rideId: rideId),
                      ),
                    );
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to request ride')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF94B5F9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Confirm Emergency Ride",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard({
    required String title,
    required String desc,
    required String price,
    required String seats,
    required String time,
    required IconData icon,
  }) {
    final bool isSelected = _selectedVehicleType == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVehicleType = title;
          // Always grab the latest calculated price from _vehiclePrices
          // to avoid the card capturing the stale "..." before fares load
          _selectedVehiclePrice = _vehiclePrices[title] ?? price;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F0FF) : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: Colors.blueGrey),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              desc,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              maxLines: 2,
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.currency_rupee, size: 14, color: Colors.blue),
                Text(
                  price,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            _buildInfoRow(Icons.people_outline, seats),
            _buildInfoRow(Icons.access_time, time),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
