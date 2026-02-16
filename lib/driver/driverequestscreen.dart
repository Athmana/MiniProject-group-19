import 'package:flutter/material.dart';
import 'package:gowayanad/driver/riderpickupscreen.dart';

class DriverRequestScreen extends StatefulWidget {
  const DriverRequestScreen({super.key});

  @override
  State<DriverRequestScreen> createState() => _DriverRequestScreenState();
}

class _DriverRequestScreenState extends State<DriverRequestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background Map Placeholder
      body: Stack(
        children: [
          Container(
              color: const Color(0xFFE3EDFF),
              child: const Center(
                  child: Icon(Icons.map, size: 100, color: Colors.blueGrey))),

          // The Request Popup
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black26, blurRadius: 20, spreadRadius: 2)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header: Service Type & Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text("🚨 EMERGENCY RIDE",
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                      const Text("₹599.00",
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D62ED))),
                    ],
                  ),
                  const Divider(height: 30),

                  // Pickup & Dropoff Timeline
                  _buildRouteInfo(Icons.my_location, Colors.blue,
                      "Pickup: Kalpetta Main Road", "2.5 km away (4 min)"),
                  const SizedBox(height: 16),
                  _buildRouteInfo(Icons.location_on, Colors.red,
                      "Dropoff: Sulthan Bathery Hospital", "8.5 km trip"),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text("IGNORE",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => DriverToPickupScreen()));
                            // Handle Accept Logic
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D62ED),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text("ACCEPT REQUEST",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(
      IconData icon, Color color, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              Text(subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
