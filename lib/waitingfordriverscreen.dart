import 'package:flutter/material.dart';
import 'dart:async';

import 'package:gowayanad/driverfoundscreen.dart';



class WaitingForDriverScreen extends StatefulWidget {
  const WaitingForDriverScreen({super.key});

  @override
  State<WaitingForDriverScreen> createState() => _WaitingForDriverScreenState();
}

class _WaitingForDriverScreenState extends State<WaitingForDriverScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate a 3-second wait before automatically navigating to 'Driver Found'
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DriverFoundScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      strokeWidth: 8,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          // ignore: deprecated_member_use
                          const Color(0xFF2D62ED).withOpacity(0.2)),
                    ),
                  ),
                  const SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF2D62ED)),
                    ),
                  ),
                  const Icon(Icons.location_searching,
                      size: 40, color: Color(0xFF2D62ED)),
                ],
              ),
              const SizedBox(height: 40),

              // 2. Status Text
              const Text(
                "Booking Confirmed!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "Searching for the nearest available driver to accept your emergency request...",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15, color: Colors.grey.shade600, height: 1.5),
              ),

              const SizedBox(height: 50),

              // 3. User Tips / Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFF2D62ED), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Please keep your phone nearby. You will be notified once a driver accepts.",
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade800),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 4. Cancel Option
              TextButton(
                onPressed: () {
                  // Show a confirmation dialog or go back
                  Navigator.pop(context);
                },
                child: const Text(
                  "Cancel Request",
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
