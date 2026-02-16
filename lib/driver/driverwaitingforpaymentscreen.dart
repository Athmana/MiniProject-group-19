import 'package:flutter/material.dart';
import 'package:gowayanad/driver/driverridefinishedscreen.dart';


class DriverWaitingPaymentScreen extends StatelessWidget {
  const DriverWaitingPaymentScreen({super.key});

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
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FE),
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
                "Please wait for Sona to complete the payment of ₹599.00",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15, color: Colors.grey.shade600, height: 1.5),
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
                  children: const [
                    Text(
                      "TOTAL FARE",
                      style:
                          TextStyle(color: Colors.white70, letterSpacing: 1.2),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "₹599.00",
                      style: TextStyle(
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
                style:
                    TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),

              const Spacer(),

              // 5. Emergency/Help Button
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => DriverRideFinishedScreen()));
                  // Logic if user refuses to pay or for cash collection
                },
                child: const Text(
                  "Collect via Cash instead",
                  style: TextStyle(
                      color: Color(0xFF2D62ED), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
