import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gowayanad/driver/homepage.dart';

class DriverRideFinishedScreen extends StatelessWidget {
  final String rideId;
  const DriverRideFinishedScreen({super.key, required this.rideId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Ride Summary"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .doc(rideId)
            .snapshots(),
        builder: (context, snapshot) {
          String price = "₹---";
          String distanceText = "--- km";
          String earnings = "₹---";

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            price = "₹${data['fareAmount'] ?? '0'}";

            final double distance = (data['distanceKm'] ?? 0.0).toDouble();
            distanceText = "${distance.toStringAsFixed(1)} km";

            // Assuming driver gets 85% of the fare, or just show full for now
            // Clean price string for calculation
            String cleanPrice = price.replaceAll(RegExp(r'[^0-9.]'), '');
            double total = double.tryParse(cleanPrice) ?? 0.0;
            earnings = "₹${(total * 0.85).toStringAsFixed(0)}";
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // 1. Earnings Circle
                Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2D62ED),
                      width: 8,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "You Earned",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        earnings,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D62ED),
                        ),
                      ),
                      const Text(
                        "(85% share)",
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 2. Trip Stats Breakdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTripDetail(distanceText, "Distance"),
                    _buildTripDetail("Completed", "Status"),
                    _buildTripDetail(price, "Total Fare"),
                  ],
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 20),

                // -- Rider Rating & Feedback Section --
                Builder(
                  builder: (context) {
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final double rating = (data['rating'] ?? 0.0).toDouble();
                      final String feedback = data['feedback'] ?? '';

                      if (rating > 0) {
                        return Column(
                          children: [
                            const Text(
                              "Rider's Rating for You",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (i) {
                                return Icon(
                                  Icons.star_rounded,
                                  size: 36,
                                  color: i < rating.round()
                                      ? Colors.orange
                                      : Colors.grey.shade300,
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            if (feedback.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  "\"$feedback\"",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        );
                      }
                    }
                    return const Text(
                      "Rider has not submitted feedback yet.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),

                // 5. Back to Online Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const DriverHomePage(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D62ED),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "GO ONLINE",
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
          );
        },
      ),
    );
  }

  Widget _buildTripDetail(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
