import 'package:flutter/material.dart';
import 'package:gowayanad/reachedlocationscreen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gowayanad/services/ride_service.dart';
import 'dart:async';

class RideStartedScreen extends StatefulWidget {
  final String rideId;
  const RideStartedScreen({super.key, required this.rideId});

  @override
  State<RideStartedScreen> createState() => _RideStartedScreenState();
}

class _RideStartedScreenState extends State<RideStartedScreen> {
  final RideService _rideService = RideService();
  StreamSubscription<DocumentSnapshot>? _rideSubscription;
  Map<String, dynamic>? _rideData;
  String? _driverName;

  @override
  void initState() {
    super.initState();
    _listenToRideStatus();
  }

  void _listenToRideStatus() {
    _rideSubscription = _rideService.listenToRide(widget.rideId).listen((
      snapshot,
    ) {
      if (snapshot.exists) {
        setState(() {
          _rideData = snapshot.data() as Map<String, dynamic>;
        });

        if (_driverName == null && _rideData?['driverId'] != null) {
          _rideService.getUserDetails(_rideData!['driverId']).then((user) {
            if (mounted && user != null) {
              setState(() {
                _driverName = user['fullName'] ?? "Driver";
              });
            }
          });
        }
        if (_rideData?['status'] == 'completed') {
          if (mounted) {
            _rideSubscription?.cancel();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ReachedLocationScreen(rideId: widget.rideId),
              ),
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip in Progress"),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          // SOS Safety Button
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.red.shade50,
              child: IconButton(
                icon: const Icon(Icons.sos, color: Colors.red),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Live Progress Indicator
          LinearProgressIndicator(
            value: 0.4, // Simulate 40% trip completion
            backgroundColor: Colors.blue.shade50,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D62ED)),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("ETA", style: TextStyle(color: Colors.grey)),
                          Text(
                            "12 Mins",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.navigation_outlined,
                        size: 40,
                        color: Colors.blue,
                      ),
                    ],
                  ),

                  const Divider(height: 40),

                  const Text(
                    "Heading To",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    _rideData?['destination'] ?? "Loading destination...",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Driver Info during trip
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(_driverName ?? "Loading driver..."),
                    subtitle: const Text("Driving you safely"),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.share_location,
                        color: Color(0xFF2D62ED),
                      ),
                      onPressed: () {
                        // Normally shares location, disabled navigation here
                        // as Stream handles it.
                      }, // Share trip status
                    ),
                  ),

                  const Spacer(),

                  // Security Notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.shield_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Your ride is protected by GoWayanad Safety",
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
