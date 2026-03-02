import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gowayanad/paymentscreen.dart';

class ReachedLocationScreen extends StatelessWidget {
  final String rideId;
  const ReachedLocationScreen({super.key, required this.rideId});

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
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),
                    child: Row(
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
                        .doc(rideId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      String destination = "Loading destination...";
                      String price = "₹---";
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        destination = data['destination'] ?? "Unknown";
                        // If price lacks symbol, add it.
                        price = "₹${data['price'] ?? '0'}";
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
                              _buildStat("8.5 km", "Distance"),
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.grey.shade300,
                              ),
                              _buildStat("18 mins", "Duration"),
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

                  // 4. Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => PaymentScreen(rideId: rideId),
                          ),
                        );
                        // Navigate to Payment Screen
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D62ED),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "PROCEED TO PAYMENT",
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
