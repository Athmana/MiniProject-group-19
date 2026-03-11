import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gowayanad/services/location_service.dart';
import 'package:gowayanad/services/ride_service.dart';
import 'package:gowayanad/waitingfordriverscreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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
    "Ambulance": "Free",
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Note: Location fetching failed ($e). Manual entry required.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _calculateFares(String destination) async {
    if (destination.isEmpty || _currentPosition == null) return;

    setState(() {
      _isCalculatingFare = true;
    });

    try {
      // Get destination coordinates for distance calculation
      List<Location> locations = await locationFromAddress(destination);
      if (locations.isEmpty || !mounted) {
        if (mounted) setState(() => _isCalculatingFare = false);
        return;
      }

      final destLat = locations[0].latitude;
      final destLng = locations[0].longitude;

      // Simple straight-line distance calculation since we removed Map API routes
      final double distanceInKm =
          Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            destLat,
            destLng,
          ) /
          1000;

      if (!mounted) return;

      if (distanceInKm > 0) {
        setState(() {
          _calculatedDistance = distanceInKm;
          _vehiclePrices["Bike"] = (30 + (8 * distanceInKm)).toStringAsFixed(0);
          _vehiclePrices["Auto"] = (50 + (12 * distanceInKm)).toStringAsFixed(
            0,
          );
          _vehiclePrices["Car"] = (100 + (18 * distanceInKm)).toStringAsFixed(
            0,
          );
          _vehiclePrices["Ambulance"] = "Free";
          _isCalculatingFare = false;
          if (_selectedVehicleType != null) {
            _selectedVehiclePrice = _vehiclePrices[_selectedVehicleType];
          }
        });
      } else {
        if (mounted) setState(() => _isCalculatingFare = false);
      }
    } catch (e) {
      debugPrint("Error calculating fares: $e");
      if (mounted) setState(() => _isCalculatingFare = false);
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
            // Simplified Location Status Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(
                    _currentPosition != null
                        ? Icons.location_on
                        : Icons.location_off,
                    color: _currentPosition != null ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentPosition != null
                              ? "Location Detected"
                              : "Detecting Location...",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (_currentPosition == null && !_isLoadingLocation)
                          const Text(
                            "Please ensure GPS is on or enter destination below",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  if (_isLoadingLocation)
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // Destination Input
            TextField(
              controller: _destinationController,
              onChanged: (value) {
                _debounce?.cancel();
                if (value.length > 3) {
                  _debounce = Timer(const Duration(milliseconds: 800), () {
                    _calculateFares(value);
                  });
                }
              },
              decoration: InputDecoration(
                hintText: "Enter destination address",
                labelText: "Destination",
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
                  color: Colors.blueAccent,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
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
                  price: _vehiclePrices["Bike"] ?? "...",
                  icon: Icons.directions_bike,
                ),
                _buildVehicleCard(
                  title: "Auto",
                  desc: "Quick emergency response",
                  price: _vehiclePrices["Auto"] ?? "...",
                  icon: Icons.electric_rickshaw,
                ),
                _buildVehicleCard(
                  title: "Car",
                  desc: "Comfortable transport",
                  price: _vehiclePrices["Car"] ?? "...",
                  icon: Icons.directions_car,
                ),
                _buildVehicleCard(
                  title: "Ambulance",
                  desc: "Medical emergency",
                  price: _vehiclePrices["Ambulance"] ?? "Free",
                  icon: Icons.medical_services,
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    (_currentPosition != null &&
                        _destinationController.text.isNotEmpty &&
                        _selectedVehicleType != null &&
                        _selectedVehiclePrice != null &&
                        _selectedVehiclePrice != "..." &&
                        !_isCalculatingFare &&
                        !_isLoadingLocation)
                    ? () async {
                        double destLat = 0.0;
                        double destLng = 0.0;
                        try {
                          List<Location> locations = await locationFromAddress(
                            _destinationController.text.trim(),
                          );
                          if (locations.isNotEmpty) {
                            destLat = locations.first.latitude;
                            destLng = locations.first.longitude;
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Destination not found: $e'),
                              ),
                            );
                          }
                          return;
                        }

                        final String? rideId = await RideService().requestRide(
                          pickupLocation:
                              "Lat: ${_currentPosition!.latitude}, Lng: ${_currentPosition!.longitude}",
                          pickupLat: _currentPosition!.latitude,
                          pickupLng: _currentPosition!.longitude,
                          destination: _destinationController.text.trim(),
                          destinationLat: destLat,
                          destinationLng: destLng,
                          vehicleType: _selectedVehicleType!,
                          price: _selectedVehiclePrice!,
                          distance: _calculatedDistance ?? 0.0,
                        );

                        if (rideId != null && mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  WaitingForDriverScreen(rideId: rideId),
                            ),
                          );
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to request ride'),
                              ),
                            );
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      (_selectedVehicleType != null &&
                          _destinationController.text.trim().isNotEmpty)
                      ? const Color(0xFF0D47A1) // Dark Blue
                      : const Color(0xFF94B5F9),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF94B5F9),
                  disabledForegroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
    required IconData icon,
  }) {
    final bool isSelected = _selectedVehicleType == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVehicleType = title;
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.blueGrey),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              desc,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
