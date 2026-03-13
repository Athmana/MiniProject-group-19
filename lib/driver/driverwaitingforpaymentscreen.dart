import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gowayanad/driver/driverridefinishedscreen.dart';
import 'package:gowayanad/services/ride_service.dart';

class DriverWaitingPaymentScreen extends StatefulWidget {
  final String rideId;
  const DriverWaitingPaymentScreen({super.key, required this.rideId});

  @override
  State<DriverWaitingPaymentScreen> createState() =>
      _DriverWaitingPaymentScreenState();
}

class _DriverWaitingPaymentScreenState
    extends State<DriverWaitingPaymentScreen> {
  final RideService _rideService = RideService();
  StreamSubscription<DocumentSnapshot>? _rideSubscription;
  String _price = "₹---";
  String _riderName = "Rider";

  @override
  void initState() {
    super.initState();
    _listenToPaymentStatus();
  }

  void _listenToPaymentStatus() {
    _rideSubscription = _rideService.listenToRide(widget.rideId).listen((
      snapshot,
    ) async {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _price = "₹${data['price'] ?? '0'}";
          });
        }

        if (data['paymentStatus'] == 'completed') {
          if (mounted) {
            _rideSubscription?.cancel();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) =>
                    DriverRideFinishedScreen(rideId: widget.rideId),
              ),
            );
          }
        }
      }
    });

    _fetchRiderName();
  }

  void _fetchRiderName() async {
    final doc = await FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .get();
    if (doc.exists) {
      final riderId = doc.data()?['riderId'];
      if (riderId != null) {
        final userDoc = await _rideService.getUserDetails(riderId);
        if (mounted && userDoc != null) {
          setState(() {
            _riderName = userDoc['fullName'] ?? "Rider";
          });
        }
      }
    }
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Animated Payment Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 60,
                  color: Color(0xFF2D62ED),
                ),
              ),
              const SizedBox(height: 32),

              // 2. Status Message
              const Text(
                "Waiting for Payment",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "Please wait for $_riderName to complete the payment of $_price",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              // 3. Payment Amount Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D62ED),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      "TOTAL FARE",
                      style: TextStyle(
                        color: Colors.white70,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _price,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 4. Loading Indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D62ED)),
              ),
              const SizedBox(height: 20),
              const Text(
                "Processing Transaction...",
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const Spacer(),

              // 5. Emergency/Help Button
              TextButton(
                onPressed: () async {
                  await _rideService.updatePaymentStatus(
                    widget.rideId,
                    'completed',
                  );
                },
                child: const Text(
                  "Collect via Cash instead",
                  style: TextStyle(
                    color: Color(0xFF2D62ED),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
