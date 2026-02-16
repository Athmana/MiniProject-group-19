import 'package:flutter/material.dart';
import 'package:gowayanad/ridestartedscreen.dart';


class DriverReachedScreen extends StatelessWidget {
  const DriverReachedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top Map Area (Placeholder)
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            color: const Color(0xFFE3EDFF),
            child: const Center(
                child: Icon(Icons.map_rounded, size: 100, color: Colors.blue)),
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                children: [
                  const Text("Driver has Reached!",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                  const SizedBox(height: 8),
                  const Text("Your White Maruti Swift is at the pickup point",
                      style: TextStyle(color: Colors.grey)),

                  const SizedBox(height: 30),

                  // Security PIN Section
                  const Text("SHARE THIS PIN WITH DRIVER",
                      style: TextStyle(
                          letterSpacing: 1.2,
                          fontSize: 12,
                          color: Colors.grey)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text("4 8 2 1",
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8)),
                  ),

                  const Spacer(),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.redAccent),
                          ),
                          child: const Text("Cancel Ride",
                              style: TextStyle(color: Colors.redAccent)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => RideStartedScreen()));
                            // Navigate to Ride Started Screen
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF2D62ED),
                          ),
                          child: const Text("I'm in the Car",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
