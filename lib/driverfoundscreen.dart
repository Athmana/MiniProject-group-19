import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:gowayanad/driverreachedscreen.dart';
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

        // Fetch driver name
        if (_driverName == null && _rideData?['driverId'] != null) {
          _rideService.getUserDetails(_rideData!['driverId']).then((user) {
            if (mounted && user != null) {
              setState(() {
                _driverName = user['fullName'] ?? "Driver";
              });
            }
          });
        }

        // Navigate when driver arrives
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
        }
        // Navigate when ride starts
        else if (_rideData?['status'] == 'started') {
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
      body: _rideData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  /// MAP
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: GoogleMap(
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
                            title: "Pickup Location",
                          ),
                        ),
                      },
                      myLocationEnabled: true,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// STATUS BANNER
                  _buildStatusBanner(),

                  const SizedBox(height: 16),

                  /// OTP CARD
                  _buildOtpCard(),

                  const SizedBox(height: 16),

                  /// DRIVER CARD
                  _buildDriverCard(),

                  const SizedBox(height: 24),

                  /// LOCATIONS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
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
                            "Trip Destination",
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusBanner() {
    bool isArrived = _rideData?['status'] == 'arrived';
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isArrived ? const Color(0xFFFFF7E6) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isArrived ? Icons.info : Icons.check_circle,
            color: isArrived ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isArrived
                  ? "${_driverName ?? 'Driver'} has arrived outside"
                  : "${_driverName ?? 'Driver'} is on the way",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Ride OTP",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "${_rideData?['otp'] ?? '----'}",
            style: const TextStyle(
              fontSize: 32,
              letterSpacing: 8,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Share this OTP with the driver to start the ride",
            style: TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _driverName ?? "Loading driver...",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange, size: 16),
                    Text(
                      " 4.9",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Text(
                  _rideData?['vehicleType'] ?? "Vehicle",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.call, size: 18),
            label: const Text("Call"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            sub,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
