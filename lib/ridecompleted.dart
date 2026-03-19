import 'package:flutter/material.dart';
import 'package:gowayanad/homepage.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:gowayanad/services/ride_service.dart';

class RideCompletedScreen extends StatefulWidget {
  final String rideId;
  const RideCompletedScreen({super.key, required this.rideId});

  @override
  State<RideCompletedScreen> createState() => _RideCompletedScreenState();
}

class _RideCompletedScreenState extends State<RideCompletedScreen> {
  final RideService _rideService = RideService();
  String? _driverName;
  bool _isLoadingName = true;

  int _rating = 5;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchDriverName();
  }

  void _fetchDriverName() async {
    final rideDoc = await FirebaseFirestore.instance
        .collection('rideRequests')
        .doc(widget.rideId)
        .get();

    if (rideDoc.exists) {
      final driverId = rideDoc.data()?['driverId'];
      if (driverId != null) {
        final userDoc = await _rideService.getUserDetails(driverId);
        if (mounted) {
          setState(() {
            _driverName = userDoc?['fullName'];
            _isLoadingName = false;
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingName = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Success Header
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 80,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Arrived Safely!",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Hope you had a great ride with GoWayanad",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 32),

              // Detailed Ride Card
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('rideRequests')
                    .doc(widget.rideId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const CircularProgressIndicator();
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final String price = "₹${data['fareAmount'] ?? '0'}";
                  final String vehicle = data['vehicleType'] ?? "Ride";
                  final String pickup = data['pickupLocation'] ?? "Unknown";
                  final String destination =
                      data['destinationLocation'] ?? "Destination";

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2D62ED,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                vehicle.toLowerCase() == 'bike'
                                    ? Icons.pedal_bike_rounded
                                    : vehicle.toLowerCase() == 'auto'
                                    ? Icons.electric_rickshaw_rounded
                                    : Icons.directions_car_filled_rounded,
                                color: const Color(0xFF2D62ED),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vehicle.toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Text(
                                    "Total Fare: $price",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 40),
                        _buildLocationRow(
                          Icons.radio_button_checked,
                          Colors.blue,
                          pickup,
                          "Pickup Location",
                        ),
                        const SizedBox(height: 20),
                        _buildLocationRow(
                          Icons.location_on_rounded,
                          Colors.red,
                          destination,
                          "Destination",
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Rating Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Text(
                      _isLoadingName
                          ? "Loading driver info..."
                          : "How was your driver, ${_driverName ?? 'the driver'}?",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        bool isSelected = index < _rating;
                        return GestureDetector(
                          onTap: () => setState(() => _rating = index + 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.star_rounded,
                              size: 48,
                              color: isSelected
                                  ? Colors.orange
                                  : Colors.grey.shade300,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _feedbackController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Anything else you'd like to share?",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(20),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Submit Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "SUBMIT FEEDBACK",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitFeedback() async {
    setState(() => _isSubmitting = true);

    await _rideService.submitReview(
      widget.rideId,
      _rating.toDouble(),
      _feedbackController.text.trim(),
    );

    if (mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!')),
      );
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const EmergencyRideHome()),
        (route) => false,
      );
    }
  }

  Widget _buildLocationRow(
    IconData icon,
    Color color,
    String address,
    String label,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              Text(
                address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
