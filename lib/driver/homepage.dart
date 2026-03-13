import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:gowayanad/driver/driverequestscreen.dart';
import 'package:gowayanad/services/ride_service.dart';
import 'package:geolocator/geolocator.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  bool _isOnline = false;
  final RideService _rideService = RideService();
  StreamSubscription<QuerySnapshot>?
  _rideSubscription; // Changed from _pendingRidesSubscription
  StreamSubscription<QuerySnapshot>? _completedRidesSubscription;
  StreamSubscription<Position>? _positionSubscription; // Added

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
            final priceRaw = data['fareAmount'];
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
    final newStatus = !_isOnline;

    // Update local state first
    setState(() {
      _isOnline = newStatus;
    });

    if (newStatus) {
      _startListeningForRides();
    } else {
      _stopListeningForRides();
    }
  }

  void _startListeningForRides() {
    _rideSubscription = _rideService.getPendingRides().listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        // For simplicity, grab the first pending ride
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;

        // Prevent showing multiple dialogues for the same or older rides
        _stopListeningForRides();

        if (mounted) {
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
      }
    });
  }

  void _stopListeningForRides() {
    _rideSubscription?.cancel();
    _rideSubscription = null;
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    _positionSubscription?.cancel();
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
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.black87),
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

          // 4. Bottom Statistics & Recent Rides
          Positioned.fill(
            top: 180,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 30,
                top: 10,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 15),
                      ],
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
                            _buildDriverStat(
                              "---",
                              "Online",
                              Icons.access_time,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "RECENT RIDES",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.2,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildRecentRidesSection(),
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

  Widget _buildRecentRidesSection() {
    final driverId =
        FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_driver';

    return StreamBuilder<QuerySnapshot>(
      stream: _rideService.getDriverCompletedRides(driverId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(40.0),
            child: Text(
              "No recent rides yet",
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final ride = docs[index].data() as Map<String, dynamic>;
            return _buildRideHistoryCard(ride);
          },
        );
      },
    );
  }

  Widget _buildRideHistoryCard(Map<String, dynamic> ride) {
    final rating = (ride['rating'] ?? 0.0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "COMPLETED",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                "₹${ride['fareAmount'] ?? '0'}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D62ED),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.my_location, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ride['pickupLocation'] ?? "Unknown",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 7.5),
            child: Icon(Icons.more_vert, size: 14, color: Colors.grey),
          ),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ride['destinationLocation'] ?? "Unknown",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (rating > 0) ...[
            const Divider(height: 24),
            Row(
              children: [
                const Text(
                  "Rider Rating: ",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                ...List.generate(
                  5,
                  (i) => Icon(
                    Icons.star,
                    size: 14,
                    color: i < rating ? Colors.orange : Colors.grey.shade300,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
