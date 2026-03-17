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

  // Fare Calculation
  bool _isCalculatingFare = false;
  bool _fareCalculated = false;
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
          _fareCalculated = true;

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
          _statusMessage = "Could not find destination. Try a specific landmark or nearby city name.";
        });
        debugPrint("Geocoding error: $e");
      }
    }
  }

  void _onDestinationChanged(String value) {
    // Reset fares when destination changes
    if (_fareCalculated) {
      setState(() {
        _fareCalculated = false;
        _vehiclePrices.updateAll((key, _) => "--");
        _selectedVehiclePrice = null;
        _calculatedDistance = null;
      });
    }
    // Debounce auto-calculate after 1.5s of inactivity
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Book a Ride",
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: -0.5,
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
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.05),
                  borderRadius: AppStyles.commonBorderRadius,
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                      onPressed: () => setState(() => _statusMessage = null),
                    ),
                  ],
                ),
              ),

            // Journey Header
            Text("Your Trip", style: AppStyles.caption.copyWith(fontWeight: FontWeight.bold)),
            const Text("Booking Details", style: AppStyles.heading1),
            const SizedBox(height: 24),

            // Pickup & Destination Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppStyles.commonBorderRadius,
                border: Border.all(color: AppColors.secondary),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.my_location, color: AppColors.primary, size: 16),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "PICKUP",
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _pickupAddress,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Container(
                      height: 20,
                      width: 2,
                      color: AppColors.secondary,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, color: AppColors.error, size: 16),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "DESTINATION",
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            TextField(
                              controller: _destinationController,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              onSubmitted: (value) => _calculateFares(value),
                              onChanged: _onDestinationChanged,
                              decoration: InputDecoration(
                                hintText: "Where are you going?",
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                suffixIcon: _isCalculatingFare
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: Padding(
                                          padding: EdgeInsets.all(10),
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                        ),
                                      )
                                    : (_destinationController.text.isNotEmpty && !_fareCalculated
                                        ? IconButton(
                                            icon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                                            onPressed: () => _calculateFares(_destinationController.text.trim()),
                                          )
                                        : null),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Vehicle Selection
            const Text("Service Type", style: AppStyles.heading2),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildVehicleCard("Bike", "Quick Response", Icons.directions_bike),
                _buildVehicleCard("Auto", "Best for City", Icons.electric_rickshaw),
                _buildVehicleCard("Car", "Comfortable", Icons.directions_car),
                _buildVehicleCard("Ambulance", "Emergency", Icons.medical_services_rounded),
              ],
            ),

            // Distance Info Banner
            if (_fareCalculated && _calculatedDistance != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: AppStyles.commonBorderRadius,
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.route_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      "Estimated distance: ${_calculatedDistance!.toStringAsFixed(1)} km",
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Confirm Button
            CustomButton(
              label: "Confirm Booking",
              isLoading: _isLoadingLocation || _isCalculatingFare,
              onPressed: (_isLoadingLocation || _isCalculatingFare)
                  ? null
                  : () async {
                      final String dest = _destinationController.text.trim();
                      if (dest.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter a destination")),
                        );
                        return;
                      }
                      if (_selectedVehicleType == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please select a vehicle type")),
                        );
                        return;
                      }
                      // Auto-calculate fare if user skipped it
                      if (!_fareCalculated) {
                        await _calculateFares(dest);
                        if (!_fareCalculated) return; // Geocoding failed
                        setState(() {
                          _selectedVehiclePrice = _vehiclePrices[_selectedVehicleType];
                        });
                      }
                      final String price = _selectedVehiclePrice ?? "0";

                      setState(() => _isCalculatingFare = true);
                      try {
                        final String? rideId = await RideService().requestRide(
                          pickupLocation: _pickupAddress,
                          pickupLat: _currentPosition!.latitude,
                          pickupLng: _currentPosition!.longitude,
                          destination: dest,
                          destinationLat: 0.0,
                          destinationLng: 0.0,
                          vehicleType: _selectedVehicleType!,
                          distance: _calculatedDistance ?? 0.0,
                          price: double.tryParse(price) ?? 0.0,
                        );
                        if (rideId != null && mounted) {
                          Navigator.pushReplacement(
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
                      } finally {
                        if (mounted) setState(() => _isCalculatingFare = false);
                      }
                    },
            ),
            const SizedBox(height: 20),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: AppStyles.commonBorderRadius,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.secondary,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              type,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price != "--" ? "₹$price" : "--",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? Colors.white.withOpacity(0.9) : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
