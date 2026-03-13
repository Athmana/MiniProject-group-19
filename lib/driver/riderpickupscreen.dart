import 'package:flutter/material.dart';
import 'package:gowayanad/services/ride_service.dart';
import 'package:gowayanad/driver/driverridestartedscreen.dart';

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
<<<<<<< HEAD
  final TextEditingController _pinController = TextEditingController();
  bool _isPinVerified = false;
  String? _pinError;
  bool _isStartingRide = false;
=======

>>>>>>> admin-panel
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
<<<<<<< HEAD
          // 1. Background Status Area (Replacing Map)
          Positioned.fill(
            child: Container(
              color: const Color(0xFFE3F2FD),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.navigation,
                      size: 100,
                      color: Color(0xFF2D62ED),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "On the way to Pickup",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Pickup: ${widget.rideData['pickupLocation'] ?? 'Address'}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
=======
          // 1. Map View
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  widget.rideData['pickupLat'] as double? ?? 11.6094,
                  widget.rideData['pickupLng'] as double? ?? 76.0828,
>>>>>>> admin-panel
                ),
              ),
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
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
<<<<<<< HEAD
                        children: [
                          const Text(
                            "Arriving to Pickup",
=======
                        children: const [
                          Text(
                            "Heading to Pickup",
>>>>>>> admin-panel
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
<<<<<<< HEAD
                            widget.rideData['pickupLocation'] ?? "Kalpetta",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
=======
                            "Follow the map to reach the passenger",
                            style: TextStyle(color: Colors.white70, fontSize: 14),
>>>>>>> admin-panel
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
                              "Pickup: ${widget.rideData['pickupLocation'] ?? 'Destination'}",
                              style: const TextStyle(color: Colors.grey, fontSize: 14),
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
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  if (!_isPinVerified) ...[
                    const Text(
                      "ENTER RIDER PIN",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: "000000",
                        counterText: "",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        errorText: _pinError,
                      ),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            "PIN Verified Successfully",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

<<<<<<< HEAD
                  // Main Action Button
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            bool? confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Cancel Ride"),
                                content: const Text(
                                  "Are you sure you want to cancel this ride?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("No"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      "Yes, Cancel",
                                      style: TextStyle(color: Colors.red),
=======
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
>>>>>>> admin-panel
                                    ),
                                  ),
                                ],
                              ),
<<<<<<< HEAD
=======
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
>>>>>>> admin-panel
                            );

                            if (confirm == true) {
                              bool success = await RideService().cancelRide(
                                widget.rideId,
                              );
                              if (success && mounted) {
                                Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst);
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to cancel ride'),
                                  ),
                                );
                              }
                            }
                          },
<<<<<<< HEAD
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "CANCEL RIDE",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isStartingRide
                              ? null
                              : () async {
                                  if (!_isPinVerified) {
                                    // Verify PIN
                                    setState(() {
                                      _pinError = null;
                                    });
                                    final result = await RideService()
                                        .verifyRidePin(
                                          widget.rideId,
                                          _pinController.text.trim(),
                                        );
                                    if (result['success'] == true) {
                                      setState(() {
                                        _isPinVerified = true;
                                      });
                                    } else {
                                      setState(() {
                                        _pinError = result['message'];
                                      });
                                    }
                                  } else {
                                    // Start Ride
                                    setState(() {
                                      _isStartingRide = true;
                                    });
                                    bool success = await RideService()
                                        .updateRideStatus(
                                          widget.rideId,
                                          'started',
                                        );
                                    if (success) {
                                      if (mounted) {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DriverRideStartedScreen(
                                                  rideId: widget.rideId,
                                                ),
                                          ),
                                        );
                                      }
                                    } else {
                                      if (mounted) {
                                        setState(() {
                                          _isStartingRide = false;
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Failed to start the ride',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isPinVerified
                                ? Colors.green
                                : Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isStartingRide
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  _isPinVerified
                                      ? "START THE RIDE"
                                      : "VERIFY PIN",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
=======
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
>>>>>>> admin-panel
                      ),
                    ],
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
