import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gowayanad/ridestartedscreen.dart';
import 'package:gowayanad/services/ride_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class DriverFoundScreen extends StatefulWidget {
  final String rideId;

  const DriverFoundScreen({super.key, required this.rideId});

  @override
  State<DriverFoundScreen> createState() => _DriverFoundScreenState();
}

class _DriverFoundScreenState extends State<DriverFoundScreen> {
  final RideService _rideService = RideService();
  StreamSubscription<DocumentSnapshot>? _rideSubscription;
  Map<String, dynamic>? _rideData;

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
        if (_rideData?['status'] == 'started') {
          if (mounted) {
            _rideSubscription?.cancel();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RideStartedScreen(rideId: widget.rideId),
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
      backgroundColor: const Color(0xFFF8FAFF), // Light blueish background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Tracking Ride",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Map / Header Section
            SizedBox(
              height: 200,
              width: double.infinity,
              child: _rideData == null
                  ? const Center(child: CircularProgressIndicator())
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _rideData!['pickupLat'] as double? ?? 11.6094,
                          _rideData!['pickupLng'] as double? ?? 76.0828,
                        ),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('pickup'),
                          position: LatLng(
                            _rideData!['pickupLat'] as double? ?? 11.6094,
                            _rideData!['pickupLng'] as double? ?? 76.0828,
                          ),
                          infoWindow: const InfoWindow(
                            title: 'Pickup Location',
                          ),
                        ),
                      },
                      myLocationEnabled: true,
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 2. Driver Found Banner
                  _buildSuccessBanner(),
                  const SizedBox(height: 16),

                  // 3. Driver Profile Card
                  _buildDriverCard(context),
                  const SizedBox(height: 16),

                  // 4. Pickup & Destination Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildLocationCard(
                          "Pickup Location",
                          _rideData?['pickupLocation'] ?? "Kalpetta Main Road",
                          "Wayanad, Kerala",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLocationCard(
                          "Destination",
                          _rideData?['destination'] ??
                              "Sulthan Bathery Hospital",
                          "8.5 km away",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 5. Trip Timeline
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Trip Timeline",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTimelineItem("Driver Found", "Completed", isDone: true),
                  _buildTimelineItem(
                    _rideData?['status'] == 'arrived'
                        ? "Driver has arrived outside"
                        : "Driver is on the way",
                    _rideData?['status'] == 'arrived'
                        ? "Waiting for you"
                        : "4 min remaining",
                    isDone: _rideData?['status'] == 'arrived',
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessBanner() {
    bool isArrived = _rideData?['status'] == 'arrived';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isArrived ? const Color(0xFFFFF7E6) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isArrived ? Colors.orange : Colors.green,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isArrived ? Icons.info : Icons.check_circle,
            color: isArrived ? Colors.orange : Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArrived ? "Driver Arrived" : "Driver Found",
                  style: TextStyle(
                    color: isArrived ? Colors.orange : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isArrived
                      ? "Arjun Kumar is waiting outside for you."
                      : "Arjun Kumar is on the way with a White Maruti Swift",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ignore: strict_top_level_inference
  Widget _buildDriverCard(context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // ignore: deprecated_member_use
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, color: Colors.white, size: 35),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Arjun Kumar",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange, size: 16),
                    Text(
                      " 4.9",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Text(
                  "White Maruti Swift • KL-07-XY-5678",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Manual Navigation for testing if needed, though replaced by stream listener
              // Navigator.of(context).push(MaterialPageRoute(
              //     builder: (context) => DriverReachedScreen(rideId: widget.rideId)));
            },
            icon: const Icon(Icons.call, size: 18),
            label: const Text("Call"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(String label, String title, String sub) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                label == "Pickup Location" ? Icons.my_location : Icons.near_me,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle, {
    required bool isDone,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone ? Colors.blue : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone ? Colors.blue : Colors.grey.shade300,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}
