import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:gowayanad/driver/driverequestscreen.dart';
import 'package:gowayanad/services/ride_service.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  bool _isOnline = false;
  final RideService _rideService = RideService();
  StreamSubscription<QuerySnapshot>? _pendingRidesSubscription;
  StreamSubscription<QuerySnapshot>? _completedRidesSubscription;

  double _totalEarnings = 0.0;
  int _totalRides = 0;

  @override
  void initState() {
    super.initState();
    _startListeningToEarnings();
  }

  void _startListeningToEarnings() {
    final driverId =
        FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_driver';

    _completedRidesSubscription = _rideService
        .getDriverCompletedRides(driverId)
        .listen((snapshot) {
          double earnings = 0.0;

          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            // Try parsing the price (might be stored as String or number depending on request)
            final priceRaw = data['price'];
            if (priceRaw != null) {
              if (priceRaw is num) {
                earnings += priceRaw.toDouble();
              } else if (priceRaw is String) {
                // Handle prices like "$500" or "500"
                String cleanPrice = priceRaw.replaceAll(RegExp(r'[^0-9.]'), '');
                earnings += double.tryParse(cleanPrice) ?? 0.0;
              }
            }
          }

          if (mounted) {
            setState(() {
              _totalRides = snapshot.docs.length;
              _totalEarnings = earnings;
            });
          }
        });
  }

  void _toggleOnlineStatus() {
    setState(() {
      _isOnline = !_isOnline;
    });

    if (_isOnline) {
      _startListeningForRides();
    } else {
      _stopListeningForRides();
    }
  }

  void _startListeningForRides() {
    _pendingRidesSubscription = _rideService.getPendingRides().listen((
      snapshot,
    ) {
      if (snapshot.docs.isNotEmpty) {
        // For simplicity, grab the first pending ride
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;

        // Prevent showing multiple dialogues for the same or older rides
        _stopListeningForRides();

        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) =>
                    DriverRequestScreen(rideId: doc.id, rideData: data),
              ),
            )
            .then((_) {
              // Restart listening when returned, if still online
              if (_isOnline) _startListeningForRides();
            });
      }
    });
  }

  void _stopListeningForRides() {
    _pendingRidesSubscription?.cancel();
    _pendingRidesSubscription = null;
  }

  @override
  void dispose() {
    _stopListeningForRides();
    _completedRidesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The background would typically be a Google Map
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          // 1. Map Placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFE3EDFF),
            child: const Center(
              child: Icon(
                Icons.map_rounded,
                size: 100,
                color: Colors.blueAccent,
              ),
            ),
          ),

          // 2. Top Header - Profile & Earnings
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.grey),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 5),
                      ],
                    ),
                    child: Text(
                      "Earnings: ₹${_totalEarnings.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Manual check for requests can still exist or be removed
                    },
                    icon: const Icon(
                      Icons.notifications_active,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Status Toggle (Online/Offline)
          Positioned(
            top: 110,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _toggleOnlineStatus,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _isOnline ? Colors.green : Colors.redAccent,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 8),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isOnline ? Icons.power_settings_new : Icons.power_off,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isOnline ? "YOU ARE ONLINE" : "YOU ARE OFFLINE",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Bottom Statistics Card
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDriverStat("4.9", "Rating", Icons.star),
                      _buildDriverStat(
                        _totalRides.toString(),
                        "Rides",
                        Icons.directions_car,
                      ),
                      _buildDriverStat("2h 20m", "Online", Icons.access_time),
                    ],
                  ),
                  const Divider(height: 30),
                  const Text(
                    "Waiting for emergency requests...",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2D62ED), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
