import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:gowayanad/driver/driverequestscreen.dart';
import 'package:gowayanad/services/ride_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gowayanad/utils/design_system.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  bool _isOnline = false;
  final RideService _rideService = RideService();
  StreamSubscription<QuerySnapshot>? _rideSubscription;
  StreamSubscription<QuerySnapshot>? _completedRidesSubscription;
  StreamSubscription<Position>? _positionSubscription;

  double _totalEarnings = 0.0;
  int _totalRides = 0;

  @override
  void initState() {
    super.initState();
    _startListeningToEarnings();
  }

  void _startListeningToEarnings() {
    final driverId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_driver';

    _completedRidesSubscription = _rideService.getDriverCompletedRides(driverId).listen((snapshot) {
      double earnings = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final priceRaw = data['fareAmount'];
        if (priceRaw != null) {
          if (priceRaw is num) {
            earnings += priceRaw.toDouble();
          } else if (priceRaw is String) {
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
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        _stopListeningForRides();
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DriverRequestScreen(rideId: doc.id, rideData: data),
            ),
          ).then((_) {
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
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Map Placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
            color: AppColors.secondary.withOpacity(0.3),
            child: const Center(
              child: Icon(Icons.map_rounded, size: 80, color: AppColors.primary),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildEarningsHero(),
                const SizedBox(height: 24),
                _buildOnlineStatusBanner(),
                const Spacer(),
                _buildBottomPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: const CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.surface,
              child: Icon(Icons.person_rounded, color: AppColors.primary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: const Text(
              "Go Wayanad Driver",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
            ),
          ),
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsHero() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              "TODAY'S EARNINGS",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "₹${_totalEarnings.toStringAsFixed(0)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("4.9", "Rating", Icons.star_rounded),
                _buildStatItem(_totalRides.toString(), "Rides", Icons.directions_car_rounded),
                _buildStatItem("8.5h", "Online", Icons.access_time_filled_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _buildOnlineStatusBanner() {
    return GestureDetector(
      onTap: _toggleOnlineStatus,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: _isOnline ? Colors.green : AppColors.error,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (_isOnline ? Colors.green : AppColors.error).withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(_isOnline ? Icons.bolt_rounded : Icons.power_off_rounded, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isOnline ? "YOU ARE ONLINE" : "YOU ARE OFFLINE",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  Text(
                    _isOnline ? "Tap to go offline" : "Tap to start receiving rides",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Recent Activity",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(
                "History",
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildRecentRidesSection(),
        ],
      ),
    );
  }

  Widget _buildRecentRidesSection() {
    final driverId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_driver';

    return StreamBuilder<QuerySnapshot>(
      stream: _rideService.getDriverCompletedRides(driverId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No recent rides yet", style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
            ),
          );
        }

        return SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final ride = docs[index].data() as Map<String, dynamic>;
              return _buildRideHistoryCard(ride);
            },
          ),
        );
      },
    );
  }

  Widget _buildRideHistoryCard(Map<String, dynamic> ride) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "₹${ride['fareAmount'] ?? '0'}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
              ),
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.my_location_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ride['pickupLocation'] ?? "Unknown",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 14, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ride['destinationLocation'] ?? "Unknown",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
