import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gowayanad/driver/riderpickupscreen.dart';
import 'package:gowayanad/services/ride_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class DriverRequestScreen extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> rideData;

  const DriverRequestScreen({
    super.key,
    required this.rideId,
    required this.rideData,
  });

  @override
  State<DriverRequestScreen> createState() => _DriverRequestScreenState();
}

class _DriverRequestScreenState extends State<DriverRequestScreen> {
  String? _riderName;
  StreamSubscription<DocumentSnapshot>? _rideSubscription;

  @override
  void initState() {
    super.initState();
    _fetchRiderName();
    _listenToRideStatus();
  }



  void _listenToRideStatus() {
    _rideSubscription = RideService().listenToRide(widget.rideId).listen((
      snapshot,
    ) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (data['status'] == 'cancelled') {
          if (mounted) {
            _rideSubscription?.cancel();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rider cancelled the request')),
            );
            Navigator.of(context).pop();
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

  void _fetchRiderName() async {
    final String? riderId = widget.rideData['riderId'];
    if (riderId != null) {
      final user = await RideService().getUserDetails(riderId);
      if (mounted && user != null) {
        setState(() {
          _riderName = user['fullName'] ?? user['name'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "Map View (Disabled)",
                      style: TextStyle(color: Colors.grey, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Request Details Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(radius: 25, child: Icon(Icons.person)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _riderName ?? "New Customer",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Row(
                              children: const [
                                Icon(
                                  Icons.star,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                Text(" 4.8  •  Cash Payment"),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "₹${widget.rideData['fareAmount'] ?? widget.rideData['price'] ?? '0'}",
                        style: const TextStyle(
                          color: Color(0xFF2D62ED),
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildLocationInfo(
                    Icons.my_location,
                    "Pickup",
                    widget.rideData['pickupLocation'] ?? "Kalpetta",
                  ),
                  const Divider(height: 32),
                  _buildLocationInfo(
                    Icons.location_on,
                    "Destination",
                    widget.rideData['destinationLocation'] ??
                        widget.rideData['destination'] ??
                        "S. Bathery",
                  ),
                  const SizedBox(height: 32),

                  // Accept/Decline Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.redAccent),
                          ),
                          child: const Text(
                            "Decline",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            bool success = await RideService().acceptRide(
                              widget.rideId,
                            );
                            if (context.mounted) {
                              if (success) {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => DriverToPickupScreen(
                                      rideId: widget.rideId,
                                      rideData: widget.rideData,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to accept ride'),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF2D62ED),
                          ),
                          child: const Text(
                            "Accept Ride",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(IconData icon, String label, String address) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                address,
                style: const TextStyle(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
