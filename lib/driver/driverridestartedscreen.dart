import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'driverwaitingforpaymentscreen.dart';
import 'package:gowayanad/services/ride_service.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverRideStartedScreen extends StatefulWidget {
  final String rideId;
  const DriverRideStartedScreen({super.key, required this.rideId});

  @override
  State<DriverRideStartedScreen> createState() =>
      _DriverRideStartedScreenState();
}

class _DriverRideStartedScreenState extends State<DriverRideStartedScreen> {
  String rideStatus = "accepted";
  Map<String, dynamic>? _rideData;
  String? _riderName;
  String? _riderPhone;

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
              _rideData = data;
              rideStatus = data['status'] ?? "accepted";
            });

            if (_riderName == null && data['riderId'] != null) {
              RideService().getUserDetails(data['riderId']).then((user) {
                if (mounted && user != null) {
                  setState(() {
                    _riderName = user['fullName'];
                    _riderPhone = user['phoneNumber'];
                  });
                }
              });
            }
          }
        });
  }

  Future<void> _makeCall() async {
    if (_riderPhone == null || _riderPhone!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Rider phone number not available")),
        );
      }
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: _riderPhone);

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch phone dialer")),
        );
      }
    }
  }

  Future<void> _startRide() async {
    await FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .update({"status": "started"});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Ride Started")));
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
          builder: (_) => DriverWaitingPaymentScreen(rideId: widget.rideId),
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            if (_riderName != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 25, child: Icon(Icons.person)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _riderName!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "Passenger",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _riderPhone != null ? _makeCall : null,
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text(
                        "Call Rider",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
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
