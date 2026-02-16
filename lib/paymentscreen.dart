import 'package:flutter/material.dart';
import 'package:gowayanad/ridecompleted.dart';


class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

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
            const Text("₹599.00",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            _paymentTile(
                Icons.account_balance_wallet_rounded, "Google Pay / UPI", true),
            _paymentTile(
                Icons.credit_card_rounded, "Credit / Debit Card", false),
            _paymentTile(Icons.money_rounded, "Cash on Arrival", false),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => RideCompletedScreen()));
                  // Navigate to Ride Completed after successful payment simulation
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D62ED),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("PAY NOW",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
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
            width: 2),
      ),
      child: ListTile(
        leading: Icon(icon,
            color: isSelected ? const Color(0xFF2D62ED) : Colors.black54),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFF2D62ED))
            : const Icon(Icons.circle_outlined),
      ),
    );
  }
}
