import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reachedlocationscreen.dart';
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
        if (mounted) {
          setState(() {
            _rideData = snapshot.data() as Map<String, dynamic>;
          });
        }
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _rideData = data;
        });
        if (data['status'] == 'completed') {
          if (mounted) {
            _rideSubscription?.cancel();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ReachedLocationScreen(rideId: widget.rideId),
              ),
            );
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
          // Top Status Area (Replacing Map)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            child: Container(
              color: const Color(0xFFE8F5E9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 100,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _rideData != null ? "Driver Arrived" : "Finalizing...",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
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
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                children: [
                  const Text(
                    "Driver has Reached!",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Your vehicle is at the pickup point",
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 30),

                  // Security PIN Section
                  const Text(
                    "SHARE THIS PIN WITH DRIVER",
                    style: TextStyle(
                      letterSpacing: 1.2,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (_rideData?['ridePin']?.toString() ??
                              _rideData?['otp']?.toString() ??
                              "4821")
                          .split('')
                          .join(' '),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.redAccent),
                          ),
                          child: const Text(
                            "Cancel Ride",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              null, // Rider waits for Driver to enter OTP
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF2D62ED),
                          ),
                          child: const Text(
                            "Waiting for Driver...",
                            style: TextStyle(color: Colors.white),
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
