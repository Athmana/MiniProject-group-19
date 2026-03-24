import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gowayanad/frontend/screens/ridecompleted.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gowayanad/backend/services/ride_service.dart';

class PaymentScreen extends StatefulWidget {
  final String rideId;
  final RideService? rideService;
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;

  const PaymentScreen({
    super.key,
    required this.rideId,
    this.rideService,
    this.firestore,
    this.auth,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final RideService _rideService;
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  bool _isProcessing = false;
  String? _errorMessage;
  String _selectedMethod = "GPay"; // Default selection
  StreamSubscription<DocumentSnapshot>? _rideSubscription;

  @override
  void initState() {
    super.initState();
    _rideService = widget.rideService ?? RideService();
    _firestore = widget.firestore ?? FirebaseFirestore.instance;
    _auth = widget.auth ?? FirebaseAuth.instance;
    _listenToPaymentStatus();
  }

  void _listenToPaymentStatus() {
    _rideSubscription = _firestore
        .collection('ride_requests')
        .doc(widget.rideId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (data['paymentStatus'] == 'completed' && mounted) {
          _rideSubscription?.cancel();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => RideCompletedScreen(
              rideId: widget.rideId,
              rideService: _rideService,
              firestore: _firestore,
              auth: _auth,
            ),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    super.dispose();
  }

  void _processPayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Simulate a small chance of failure for the "Retry" requirement
      // In a real app, this would be the actual payment gateway response
      // if (DateTime.now().second % 5 == 0) throw Exception("Network Timeout");

      bool success = await _rideService.updatePaymentStatus(
        widget.rideId,
        'completed',
      );

      if (success) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => RideCompletedScreen(
              rideId: widget.rideId,
              rideService: _rideService,
              firestore: _firestore,
              auth: _auth,
            ),
          ),
        );
      } else {
        throw Exception("Server connection failed");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = "Payment failed (Simulated Error). Please try again.";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: "RETRY",
            textColor: Colors.white,
            onPressed: _processPayment,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Payment Method"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (!_isProcessing) Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Amount to Pay",
                  style: TextStyle(color: Colors.grey),
                ),
                StreamBuilder<DocumentSnapshot>(
                  stream: _firestore
                      .collection('ride_requests')
                      .doc(widget.rideId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    String price = "₹---";
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;
                      price = "₹${data['fareAmount'] ?? '0'}";
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
                  "GPay",
                  Icons.account_balance_wallet_rounded,
                  "Google Pay / UPI",
                ),
                _paymentTile(
                  "Card",
                  Icons.credit_card_rounded,
                  "Credit / Debit Card",
                ),
                _paymentTile(
                  "Wallet",
                  Icons.account_balance_wallet_outlined,
                  "Digital Wallet",
                ),
                _paymentTile("Cash", Icons.money_rounded, "Cash on Arrival"),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
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
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.white.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF2D62ED)),
                    const SizedBox(height: 20),
                    Text(
                      "Processing Payment via $_selectedMethod...",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _paymentTile(String id, IconData icon, String title) {
    bool isSelected = _selectedMethod == id;
    return GestureDetector(
      onTap: () {
        if (!_isProcessing) {
          setState(() {
            _selectedMethod = id;
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2D62ED).withValues(alpha: 0.05)
              : null,
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
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: Color(0xFF2D62ED))
              : const Icon(Icons.circle_outlined, color: Colors.grey),
        ),
      ),
    );
  }
}
