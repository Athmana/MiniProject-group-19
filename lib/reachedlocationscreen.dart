import 'package:flutter/material.dart';
import 'package:gowayanad/paymentscreen.dart';


class ReachedLocationScreen extends StatelessWidget {
  const ReachedLocationScreen({super.key});

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
                const Icon(Icons.map_rounded,
                    size: 120, color: Colors.blueAccent),
                // "Arrived" Marker Overlay
                Positioned(
                  bottom: 50,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10)
                      ],
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text("Arrived at Destination",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                )
              ],
            ),
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
                  const Text(
                    "Sulthan Bathery Hospital, Wayanad",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),

                  const SizedBox(height: 30),

                  // 3. Trip Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat("8.5 km", "Distance"),
                      Container(
                          width: 1, height: 30, color: Colors.grey.shade300),
                      _buildStat("18 mins", "Duration"),
                      Container(
                          width: 1, height: 30, color: Colors.grey.shade300),
                      _buildStat("₹599", "Total Fare"),
                    ],
                  ),

                  const Spacer(),

                  // 4. Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => PaymentScreen()));
                        // Navigate to Payment Screen
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D62ED),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        "PROCEED TO PAYMENT",
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

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
