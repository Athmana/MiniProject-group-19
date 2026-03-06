import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:gowayanad/driverreachedscreen.dart';
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

        if (_rideData?['status'] == 'arrived') {
          if (mounted) {
            _rideSubscription?.cancel();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DriverReachedScreen(rideId: widget.rideId),
              ),
            );
          }
        } else if (_rideData?['status'] == 'started') {
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
      backgroundColor: const Color(0xFFF8FAFF),
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
            /// MAP
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSuccessBanner(),
                  const SizedBox(height: 16),

                  /// DRIVER CARD
                  _buildDriverCard(),
                  const SizedBox(height: 16),

                  /// OTP CARD
                  _buildOtpCard(),
                  const SizedBox(height: 16),

                  /// LOCATIONS
                  Row(
                    children: [
                      Expanded(
                        child: _buildLocationCard(
                          "Pickup Location",
                          _rideData?['pickupLocation'] ?? "Pickup",
                          "Wayanad",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLocationCard(
                          "Destination",
                          _rideData?['destination'] ?? "Destination",
                          "8 km away",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// OTP DISPLAY
  Widget _buildOtpCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Ride OTP",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "${_rideData?['otp'] ?? '----'}",
            style: const TextStyle(
              fontSize: 36,
              letterSpacing: 8,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Share this OTP with the driver to start the ride",
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: Colors.green, width: 4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "${_driverName ?? 'Driver'} is on the way",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, color: Colors.white, size: 35),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _driverName ?? "Loading driver...",
              style: const TextStyle(fontWeight: FontWeight.bold),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
