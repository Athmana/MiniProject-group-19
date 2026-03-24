import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gowayanad/frontend/driver/driverwaitingforpaymentscreen.dart';
import 'package:gowayanad/backend/services/ride_service.dart';
import 'package:gowayanad/frontend/driver/homepage.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverRideStartedScreen extends StatefulWidget {
  final String rideId;
  final RideService? rideService;
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;

  const DriverRideStartedScreen({
    super.key, 
    required this.rideId,
    this.rideService,
    this.firestore,
    this.auth,
  });

  @override
  State<DriverRideStartedScreen> createState() =>
      _DriverRideStartedScreenState();
}

class _DriverRideStartedScreenState extends State<DriverRideStartedScreen> {
  late final RideService _rideService;
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  @override
  void initState() {
    super.initState();
    _rideService = widget.rideService ?? RideService();
    _firestore = widget.firestore ?? FirebaseFirestore.instance;
    _auth = widget.auth ?? FirebaseAuth.instance;
  }

  String? _riderName;

  Future<void> _startRide() async {
    bool success = await _rideService.updateRideStatus(
      widget.rideId,
      "ongoing",
    );
    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ride Started")));
    }
  }

  Future<void> _endRide() async {
    bool success = await _rideService.updateRideStatus(
      widget.rideId,
      "completed",
    );
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              DriverWaitingPaymentScreen(rideId: widget.rideId),
        ),
      );
    }
  }

  Future<void> _openNavigation(double lat, double lng) async {
    final String url =
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }



  Future<void> _cancelRide() async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Cancel Trip"),
            content: const Text("Are you sure you want to cancel this trip?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text("Yes, Cancel"),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm || !mounted) return;

    bool success = await _rideService.cancelRide(widget.rideId);

    if (mounted) {
      if (!success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to cancel trip.')));
      }
      // On success, the StreamBuilder inside the build method
      // will pick up the 'cancelled' status and pop the screen properly.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Trip Progress",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            tooltip: 'Cancel Ride',
            onPressed: _cancelRide,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('ride_requests')
            .doc(widget.rideId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final status = data['status'] ?? 'accepted';

          if (status == 'cancelled') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ride was cancelled')),
                );
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => DriverHomePage(
                    rideService: _rideService,
                    firestore: _firestore,
                    auth: _auth,
                  )),
                  (route) => false,
                );
              }
            });
            return const SizedBox.shrink();
          }

          // Logic for target location
          final bool isHeadingToPickup =
              status == 'accepted' || status == 'arrived';
          final String targetLabel = isHeadingToPickup
              ? "PICKUP LOCATION"
              : "DROP-OFF LOCATION";
          final String targetAddress = isHeadingToPickup
              ? (data['pickupLocation'] ?? 'Loading...')
              : (data['destinationLocation'] ?? 'Loading...');

          final double targetLat = isHeadingToPickup
              ? (data['pickupLat'] ?? 0.0)
              : (data['destinationLat'] ?? 0.0);
          final double targetLng = isHeadingToPickup
              ? (data['pickupLng'] ?? 0.0)
              : (data['destinationLng'] ?? 0.0);

          // Get rider details
          if (_riderName == null && data['riderId'] != null) {
            _rideService.getUserDetails(data['riderId']).then((riderData) {
              if (mounted) {
                setState(() {
                  _riderName =
                      riderData?['fullName'] ?? riderData?['name'] ?? "Rider";
                });
              }
            });
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rider Info Chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF2D62ED),
                        radius: 20,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "RIDER",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _riderName ?? "Loading...",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Navigation Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D62ED),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D62ED).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            targetLabel,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _openNavigation(targetLat, targetLng),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.directions,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "NAVIGATE",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        targetAddress,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Status Indicator
                Center(
                  child: Column(
                    children: [
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: status == 'ongoing'
                              ? Colors.green
                              : Colors.blue,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: status == 'ongoing'
                              ? Colors.green
                              : Colors.blue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Action Buttons
                if (status == "accepted" || status == "arrived")
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _startRide,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D62ED),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "START TRIP",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                if (status == "ongoing")
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _endRide,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "COMPLETE RIDE",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
