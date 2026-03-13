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
    ) async {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;

        setState(() {
          _rideData = data;
        });

        if (_driverName == null && _rideData?['driverId'] != null) {
          _rideService.getUserDetails(_rideData!['driverId']).then((user) {
            if (mounted && user != null) {
              setState(() {
                _driverName = user['name'] ?? user['fullName'] ?? "Driver";
              });
            }
          });
        }

        if (_rideData?['status'] == 'completed') {
          if (mounted) {
            _rideSubscription?.cancel();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) =>
                    ReachedLocationScreen(rideId: widget.rideId),
              ),
            );
          }
        } else if (_rideData?['status'] == 'cancelled') {
          if (mounted) {
            _rideSubscription?.cancel();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ride was cancelled.')),
            );
            Navigator.of(context).popUntil((route) => route.isFirst);
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
      body: Stack(
        children: [
          // 1. Background Status Area (Replacing Map)
          Positioned.fill(
            child: Container(
              color: const Color(0xFFF1F5FE),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.local_taxi,
                      size: 80,
                      color: Color(0xFF2D62ED),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _rideData != null ? "Trip in Progress" : "Connecting...",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Please stay safe during the ride",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Top Info Bar (Floating)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Arriving to your Destination",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _rideData?['destinationLocation'] ?? "Loading...",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Driver Card (Floating)
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        radius: 25,
                        child: Icon(Icons.person),
                      ),
                      title: Text(
                        _driverName ?? "Driver Loading...",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        _rideData?['vehicleType'] ?? "Vehicle Info",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.call, color: Colors.green),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.message,
                              color: Color(0xFF2D62ED),
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Fare Estimate",
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          "₹${_rideData?['fareAmount'] ?? '0'}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
