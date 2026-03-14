import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'paymentscreen.dart';
import 'services/ride_service.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

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
        setState(() {
          _rideData = data;
        });

        if (_driverName == null && data['driverId'] != null) {
          _rideService.getUserDetails(data['driverId']).then((user) {
            if (mounted && user != null) {
              setState(() {
                _driverName = user['fullName'] ?? "Driver";
                _driverPhone = user['phoneNumber'];
              });
            }
          });
        }
        if (data['status'] == 'completed') {
          if (mounted) {
            _rideSubscription?.cancel();
            Navigator.pushReplacement(
              context,
              // The next screen in Rider flow was RideStarted, but skipping straight to Payment
              // since our 'COMPLETE RIDE' triggers the 'completed' status.
              MaterialPageRoute(
                builder: (context) => PaymentScreen(rideId: widget.rideId),
              ),
            );
          }
        }
      }
    });
  }

  Future<void> _makeCall() async {
    if (_driverPhone == null || _driverPhone!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Driver phone number not available")),
        );
      }
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: _driverPhone);

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch phone dialer")),
        );
      }
    }
  }

  Widget _buildDriverCallSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFF1F5FE),
            child: Icon(Icons.person, color: Color(0xFF2D62ED)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _driverName ?? "Driver",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Arrived outside",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _driverPhone != null ? _makeCall : null,
            icon: const Icon(Icons.call, size: 18),
            label: const Text(
              "Call Driver",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
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
          // Top Map Area (Placeholder)
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade700],
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
                Text(
                  _rideData?['status'] == 'arrived'
                      ? "Driver is Here!"
                      : "Arrived",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
                  Text(
                    "Your vehicle is at the pickup point",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  if (_rideData?['driverId'] != null) _buildDriverCallSection(),
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
                      _rideData?['otp']?.split('').join(' ') ?? "0 0 0 0",
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
