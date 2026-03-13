import 'package:flutter/material.dart';
import 'package:gowayanad/driver/driverotpscreen.dart';
import 'package:gowayanad/services/ride_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverToPickupScreen extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> rideData;

  const DriverToPickupScreen({
    super.key,
    required this.rideId,
    required this.rideData,
  });

  @override
  State<DriverToPickupScreen> createState() => _DriverToPickupScreenState();
}

class _DriverToPickupScreenState extends State<DriverToPickupScreen> {
  String? _riderName;

  @override
  void initState() {
    super.initState();
    _fetchRiderName();
  }

  void _fetchRiderName() async {
    final String? riderId = widget.rideData['riderId'];
    if (riderId != null) {
      final user = await RideService().getUserDetails(riderId);
      if (mounted && user != null) {
        setState(() {
          _riderName = user['name'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Map View
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  widget.rideData['pickupLat'] as double? ?? 11.6094,
                  widget.rideData['pickupLng'] as double? ?? 76.0828,
                ),
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('pickup'),
                  position: LatLng(
                    widget.rideData['pickupLat'] as double? ?? 11.6094,
                    widget.rideData['pickupLng'] as double? ?? 76.0828,
                  ),
                  infoWindow: const InfoWindow(title: 'Pickup Location'),
                ),
              },
              myLocationEnabled: true,
            ),
          ),

          // 2. Navigation Info
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D62ED),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.turn_right, color: Colors.white, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Heading to Pickup",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Follow the map to reach the passenger",
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Passenger Info & Start Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(radius: 25, child: Icon(Icons.person)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _riderName ?? "Loading rider...",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              "Pickup: ${widget.rideData['pickupLocation'] ?? 'Remote Location'}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.call, color: Colors.green, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        final bool? pinValid = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            final pinController = TextEditingController();
                            return AlertDialog(
                              title: const Text("Enter Rider PIN"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text("Ask the rider for their 4-digit PIN to start the ride."),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: pinController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    maxLength: 4,
                                    decoration: const InputDecoration(
                                      hintText: "0000",
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    final String correctPin = widget.rideData['ridePin']?.toString() ?? "0000";
                                    if (pinController.text.trim() == correctPin) {
                                      Navigator.pop(context, true);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Incorrect PIN"), backgroundColor: Colors.red),
                                      );
                                    }
                                  },
                                  child: const Text("Verify"),
                                ),
                              ],
                            );
                          },
                        );

                        if (pinValid == true) {
                          bool success = await RideService().updateRideStatus(widget.rideId, 'started');
                          if (success && mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => DriverOtpScreen(
                                  rideId: widget.rideId,
                                  correctOtp: widget.rideData['ridePin'] ?? "0000",
                                ),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        "START THE RIDE",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
