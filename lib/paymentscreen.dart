import 'package:flutter/material.dart';
import 'package:gowayanad/ridecompleted.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gowayanad/services/ride_service.dart';

class PaymentScreen extends StatelessWidget {
  final String rideId;
  const PaymentScreen({super.key, required this.rideId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Payment Method"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Amount to Pay", style: TextStyle(color: Colors.grey)),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rides')
                  .doc(rideId)
                  .snapshots(),
              builder: (context, snapshot) {
                String price = "₹---";
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  price = "₹${data['price'] ?? '0'}";
                }
                return Text(
                  price,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            _paymentTile(
              Icons.account_balance_wallet_rounded,
              "Google Pay / UPI",
              true,
            ),
            _paymentTile(
              Icons.credit_card_rounded,
              "Credit / Debit Card",
              false,
            ),
            _paymentTile(Icons.money_rounded, "Cash on Arrival", false),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  // Simulate showing a dialog or loading...
                  bool success = await RideService().updatePaymentStatus(
                    rideId,
                    'completed',
                  );
                  if (success && context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) =>
                            RideCompletedScreen(rideId: rideId),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D62ED),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "PAY NOW",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentTile(IconData icon, String title, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF2D62ED) : Colors.grey.shade200,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF2D62ED) : Colors.black54,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFF2D62ED))
            : const Icon(Icons.circle_outlined),
      ),
    );
  }
}
