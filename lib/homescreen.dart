import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gowayanad/services/location_service.dart';
import 'package:gowayanad/services/ride_service.dart';
import 'package:gowayanad/waitingfordriverscreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class EmergencyRideHome extends StatefulWidget {
  const EmergencyRideHome({super.key});

  @override
  State<EmergencyRideHome> createState() => _EmergencyRideHomeState();
}

class _EmergencyRideHomeState extends State<EmergencyRideHome> {
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  final TextEditingController _destinationController = TextEditingController();
  String? _selectedVehicleType;
  String? _statusMessage;

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
        title: const Text(
          "GoWayanad",
          style: TextStyle(
            color: Color(0xFF2D62ED),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              decoration: InputDecoration(
                hintText: "Enter destination address",
                prefixIcon: const Icon(Icons.location_on, color: Colors.red),
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
                _buildVehicleCard("Bike", "Quick response", Icons.directions_bike),
                _buildVehicleCard("Auto", "Best for city", Icons.electric_rickshaw),
                _buildVehicleCard("Car", "Comfortable", Icons.directions_car),
                _buildVehicleCard("Ambulance", "Emergency", Icons.medical_services),
              ],
            ),

            const SizedBox(height: 32),

            // Request Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isLoadingLocation || _selectedVehicleType == null)
                    ? null
                    : () async {
                        final String dest = _destinationController.text.trim();
                        if (dest.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please enter destination")),
                          );
                          return;
                        }

                        // Geocode destination
                        try {
                          List<Location> locations = await locationFromAddress(dest);
                          if (locations.isEmpty) throw Exception("No location found");
                          
                          final double dLat = locations.first.latitude;
                          final double dLng = locations.first.longitude;
                          final double pLat = _currentPosition!.latitude;
                          final double pLng = _currentPosition!.longitude;

                          final String? rideId = await RideService().requestRide(
                            pickupLocation: "Current Location",
                            pickupLat: pLat,
                            pickupLng: pLng,
                            destination: dest,
                            destLat: dLat,
                            destLng: dLng,
                            vehicleType: _selectedVehicleType!,
                          );

                          if (rideId != null && mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WaitingForDriverScreen(rideId: rideId),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: ${e.toString()}")),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D62ED),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoadingLocation
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Confirm Emergency Ride",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    return GestureDetector(
      onTap: () => setState(() => _selectedVehicleType = type),
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
            Icon(icon, size: 30, color: isSelected ? const Color(0xFF2D62ED) : Colors.grey),
            const SizedBox(height: 8),
            Text(
              type,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF2D62ED) : Colors.black,
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
