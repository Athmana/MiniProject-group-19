import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ridestartedscreen.dart';
import 'services/ride_service.dart';
import 'dart:async';


class DriverReachedScreen extends StatefulWidget {
  final String rideId;

  const DriverReachedScreen({super.key, required this.rideId});

  @override
  State<DriverReachedScreen> createState() => _DriverReachedScreenState();
}

class _DriverReachedScreenState extends State<DriverReachedScreen> {
  final RideService _rideService = RideService();
  StreamSubscription<DocumentSnapshot>? _rideSubscription;
  Map<String, dynamic>? _rideData;
  String? _driverName;
  String? _driverPhone;

  @override
  void initState() {
    super.initState();
    _listenToRideStatus();
  }

  void _listenToRideStatus() {
    _rideSubscription = _rideService.listenToRide(widget.rideId).listen((
      snapshot,
    ) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _rideData = data;
          });
        }

        if (_driverName == null && data['driverId'] != null) {
          _rideService.getUserDetails(data['driverId']).then((user) {
            if (mounted && user != null) {
              setState(() {
                _driverName = user['fullName'] ?? user['name'] ?? "Driver";
                _driverPhone = user['phoneNumber'];
              });
            }
          });
        }

        if (data['status'] == 'started') {
          if (mounted) {
            _rideSubscription?.cancel();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RideStartedScreen(rideId: widget.rideId),
              ),
            );
          }
        } else if (data['status'] == 'cancelled') {
          if (mounted) {
            _rideSubscription?.cancel();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ride was cancelled.')),
            );
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      }
    });
  }



  @override
  void dispose() {
    _rideSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top Map Area
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            child: _rideData == null
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map, size: 60, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            "Map View (Disabled)",
                            style: TextStyle(color: Colors.grey, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Driver is Here!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Your vehicle has arrived",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    // Driver Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 25,
                            backgroundColor: Color(0xFFEBF2FF),
                            child: Icon(Icons.person, color: Color(0xFF2D62ED)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _driverName ?? "Loading...",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Text(
                                  "Your Driver",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_driverPhone != null)
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: _driverPhone!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Number copied"),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEBF2FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF2D62ED).withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.copy,
                                      size: 16,
                                      color: Color(0xFF2D62ED),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _driverPhone!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2D62ED),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Security PIN Section
                    const Text(
                      "VERIFICATION OTP",
                      style: TextStyle(
                        letterSpacing: 1.2,
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Share this with your driver to start the trip",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5FE),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF2D62ED).withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        (_rideData?['otp']?.toString() ?? "----")
                            .split('')
                            .join('  '),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: Color(0xFF2D62ED),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final bool? confirm = await showDialog<bool>(
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
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _rideService.cancelRide(widget.rideId);
                                if (mounted) {
                                  Navigator.of(
                                    context,
                                  ).popUntil((route) => route.isFirst);
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Cancel Ride",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              disabledBackgroundColor: Colors.grey.shade200,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Waiting to Start...",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
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
