import 'package:flutter/material.dart';
import 'package:gowayanad/driver/driverwaitingforpaymentscreen.dart';


class DriverRideStartedScreen extends StatelessWidget {
  const DriverRideStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Full Screen Navigation Map
          Container(
            color: const Color(0xFFE8F0FF),
            child: const Center(
              child: Icon(Icons.navigation_outlined,
                  size: 100, color: Color(0xFF2D62ED)),
            ),
          ),

          // 2. Navigation Top Bar
          SafeArea(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1), blurRadius: 10)
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.turn_left,
                      color: Color(0xFF2D62ED), size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("800m - Turn Left",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("Towards Sulthan Bathery Hospital",
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Trip Status & Complete Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Trip Progress Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoColumn("Distance Left", "5.2 km"),
                      _buildInfoColumn("ETA", "12 mins"),
                      _buildInfoColumn("Fare", "₹599"),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sliding/Large Complete Button
                  // Use a bold color to signify the end of the trip
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                DriverWaitingPaymentScreen()));
                        // Navigate to Driver Ride Completed Screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.redAccent, // Red to signal 'Stop/Complete'
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text(
                        "COMPLETE RIDE",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
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

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
