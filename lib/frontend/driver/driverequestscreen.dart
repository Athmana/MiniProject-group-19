import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gowayanad/frontend/driver/riderpickupscreen.dart';
import 'package:gowayanad/backend/services/ride_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gowayanad/backend/utils/design_system.dart';
import 'package:gowayanad/frontend/driver/homepage.dart';

class DriverRequestScreen extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> rideData;
  final RideService? rideService;
  final FirebaseAuth? auth;

  const DriverRequestScreen({
    super.key,
    required this.rideId,
    required this.rideData,
    this.rideService,
    this.auth,
  });

  @override
  State<DriverRequestScreen> createState() => _DriverRequestScreenState();
}

class _DriverRequestScreenState extends State<DriverRequestScreen> {
  late final RideService _rideService;
  late final FirebaseAuth _auth;
  String? _riderName;
  StreamSubscription<DocumentSnapshot>? _rideSubscription;

  @override
  void initState() {
    super.initState();
    _rideService = widget.rideService ?? RideService();
    _auth = widget.auth ?? FirebaseAuth.instance;
    _fetchRiderName();
    _listenToRideStatus();
  }

  void _listenToRideStatus() {
    _rideSubscription = _rideService.listenToRideRequest(widget.rideId).listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        
        // In broadcast model, if status is no longer 'waiting', check why
        if (data['status'] != 'waiting') {
          final myId = _auth.currentUser?.uid;
          
          if (data['status'] == 'accepted') {
            if (data['acceptedDriverId'] == myId) {
              // This is GOOD - we are the ones who accepted it. 
              // The button callback will handle navigation.
              return;
            } else {
              // Someone else took it
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ride already taken by another driver'),
                    backgroundColor: Colors.orange,
                  ),
                );
                Navigator.of(context).pop();
              }
            }
          } else if (data['status'] == 'cancelled') {
             // Handled separately below
          } else {
            // Some other status (ongoing, etc.) but not by us
            if (mounted) Navigator.of(context).pop();
          }
        }

        if (data['status'] == 'cancelled') {
          if (mounted) {
            _rideSubscription?.cancel();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Rider cancelled the request'),
                backgroundColor: AppColors.error,
              ),
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const DriverHomePage()),
              (route) => false,
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

  void _fetchRiderName() async {
    final String? riderId = widget.rideData['riderId'];
    if (riderId != null) {
      final user = await _rideService.getUserDetails(riderId);
      if (mounted && user != null) {
        setState(() {
          _riderName = user['fullName'] ?? user['name'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickup = widget.rideData['pickupLocation'] ?? "Pickup location";
    final destination = widget.rideData['destinationLocation'] ??
        widget.rideData['destination'] ?? "Destination";
    final fare = widget.rideData['fareAmount'] ?? widget.rideData['price'] ?? '0';
    final vehicleType = widget.rideData['vehicleType'] ?? "Standard";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "New Ride Request",
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Animated notification indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: Colors.green, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    "New ride request incoming!",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Rider Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 34),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _riderName ?? "Loading...",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
Icons.star_rounded, color: Colors.orange, size: 16),
                            const Text(" 4.8  •  ", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                vehicleType,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "₹$fare",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Trip Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "TRIP DETAILS",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLocationRow(
                    Icons.my_location_rounded,
                    "Pickup",
                    pickup,
                    AppColors.primary,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 19),
                    child: Container(
                      height: 24,
                      width: 2,
                      color: AppColors.secondary,
                    ),
                  ),
                  _buildLocationRow(
                    Icons.location_on_rounded,
                    "Destination",
                    destination,
                    AppColors.error,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      await _rideService.declineRideRequest(widget.rideId);
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const DriverHomePage()),
                          (route) => false,
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.error, width: 1.5),
                      ),
                    ),
                    child: const Text(
                      "DECLINE",
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    label: "ACCEPT",
                    onPressed: () async {
                      bool success = await _rideService.acceptRideRequest(widget.rideId);
                      if (context.mounted) {
                        if (success) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => DriverToPickupScreen(
                                rideId: widget.rideId,
                                rideData: widget.rideData,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not accept. Ride might be taken or cancelled.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          Navigator.of(context).pop();
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String address, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
