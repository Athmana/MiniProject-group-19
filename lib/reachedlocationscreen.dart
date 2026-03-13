import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gowayanad/paymentscreen.dart';

class ReachedLocationScreen extends StatefulWidget {
  final String rideId;
  const ReachedLocationScreen({super.key, required this.rideId});

  @override
  State<ReachedLocationScreen> createState() => _ReachedLocationScreenState();
}

class _ReachedLocationScreenState extends State<ReachedLocationScreen> {
  double _progress = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoNavigation();
  }

  void _startAutoNavigation() {
    const duration = Duration(seconds: 4);
    const interval = Duration(milliseconds: 50);
    int elapsed = 0;

    _timer = Timer.periodic(interval, (timer) {
      elapsed += interval.inMilliseconds;
      if (mounted) {
        setState(() {
          _progress = elapsed / duration.inMilliseconds;
        });
      }

      if (elapsed >= duration.inMilliseconds) {
        timer.cancel();
        _navigateToPayment();
      }
    });
  }

  void _navigateToPayment() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PaymentScreen(rideId: widget.rideId),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Map Header (Arrived State)
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            width: double.infinity,
            color: const Color(0xFFF0F4FF),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Placeholder for Google Map
                const Icon(
                  Icons.map_rounded,
                  size: 120,
                  color: Colors.blueAccent,
                ),
                // "Arrived" Marker Overlay
                Positioned(
                  bottom: 50,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Arrived at Destination",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Progress bar for auto-navigation
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey.shade100,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D62ED)),
            minHeight: 4,
          ),

          // 2. Details Bottom Sheet
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const Text(
                    "You have reached!",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('rides')
                        .doc(widget.rideId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      String destination = "Loading destination...";
                      String price = "₹---";
                      String distanceText = "--- km";
                      String durationText = "--- mins";

                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        destination = data['destinationLocation'] ?? "Unknown";
                        // If price lacks symbol, add it.
                        price = "₹${data['fareAmount'] ?? '0'}";

                        final double distance = (data['distanceKm'] ?? 0.0)
                            .toDouble();
                        distanceText = "${distance.toStringAsFixed(1)} km";

                        // Rough estimate: 1.5 min per km + 3 min fixed
                        final int duration = (distance * 1.5).round() + 3;
                        durationText = "$duration mins";
                      }

                      return Column(
                        children: [
                          Text(
                            destination,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStat(distanceText, "Distance"),
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.grey.shade300,
                              ),
                              _buildStat(durationText, "Duration"),
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.grey.shade300,
                              ),
                              _buildStat(price, "Total Fare"),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  const Spacer(),
                  const Text(
                    "Navigating to payment automatically...",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // 4. Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        _timer?.cancel();
                        _navigateToPayment();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D62ED),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "PROCEED TO PAYMENT NOW",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
