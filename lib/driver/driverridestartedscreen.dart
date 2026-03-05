import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../paymentscreen.dart';

class DriverRideStartedScreen extends StatefulWidget {
  final String rideId;
  const DriverRideStartedScreen({super.key, required this.rideId});

  @override
  State<DriverRideStartedScreen> createState() =>
      _DriverRideStartedScreenState();
}

class _DriverRideStartedScreenState extends State<DriverRideStartedScreen> {
  String rideStatus = "accepted";

  @override
  void initState() {
    super.initState();
    _listenToRide();
  }

  void _listenToRide() {
    FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          rideStatus = data['status'] ?? "accepted";
        });
      }
    });
  }

  Future<void> _startRide() async {
    await FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .update({"status": "started"});

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Ride Started")));
  }

  Future<void> _endRide() async {
    await FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .update({"status": "completed"});

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(rideId: widget.rideId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Ride")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              "Current Status: $rideStatus",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),

            if (rideStatus == "accepted")
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startRide,
                  child: const Text("START RIDE"),
                ),
              ),

            if (rideStatus == "started")
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _endRide,
                  child: const Text("END RIDE"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}