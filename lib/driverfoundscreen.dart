import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gowayanad/ridestartedscreen.dart';
import 'package:gowayanad/driverreachedscreen.dart';
import 'package:gowayanad/services/ride_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gowayanad/services/map_service.dart';
import 'dart:async';

class DriverFoundScreen extends StatefulWidget {
  final String rideId;

  const DriverFoundScreen({super.key, required this.rideId});

  @override
  State<DriverFoundScreen> createState() => _DriverFoundScreenState();
}

class _DriverFoundScreenState extends State<DriverFoundScreen> {
  final RideService _rideService = RideService();
  final MapService _mapService = MapService();
  StreamSubscription<DocumentSnapshot>? _rideSubscription;
  Map<String, dynamic>? _rideData;
  String? _driverName;

  GoogleMapController? _mapController;
  List<LatLng> _routePoints = [];
  LatLng? _driverLocation;

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
        final prevDriverLat = _rideData?['driverLat'];
        final prevDriverLng = _rideData?['driverLng'];

        setState(() {
          _rideData = data;
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

        // Handle Driver Location and Polylines
        final currentDriverLat = data['driverLat'];
        final currentDriverLng = data['driverLng'];

        if (currentDriverLat != null && currentDriverLng != null) {
          final newLoc = LatLng(currentDriverLat, currentDriverLng);

          if (_driverLocation == null ||
              currentDriverLat != prevDriverLat ||
              currentDriverLng != prevDriverLng) {
            setState(() {
              _driverLocation = newLoc;
            });

            // Fetch Route from Driver to Pickup
            final pickupLoc = LatLng(
              data['pickupLat'] as double? ?? 11.6094,
              data['pickupLng'] as double? ?? 76.0828,
            );

            final points = await _mapService.getPolylinePoints(
              newLoc,
              pickupLoc,
            );
            if (mounted) {
              setState(() {
                _routePoints = points;
              });

              // Adjust camera to show both
              if (_mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngBounds(
                    _getBounds(newLoc, pickupLoc),
                    50,
                  ),
                );
              }
            }
          }
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

  LatLngBounds _getBounds(LatLng p1, LatLng p2) {
    double south = p1.latitude < p2.latitude ? p1.latitude : p2.latitude;
    double west = p1.longitude < p2.longitude ? p1.longitude : p2.longitude;
    double north = p1.latitude > p2.latitude ? p1.latitude : p2.latitude;
    double east = p1.longitude > p2.longitude ? p1.longitude : p2.longitude;
    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
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
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                        ),
                        if (_driverLocation != null)
                          Marker(
                            markerId: const MarkerId('driver'),
                            position: _driverLocation!,
                            infoWindow: const InfoWindow(
                              title: 'Driver Location',
                            ),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueAzure,
                            ),
                          ),
                      },
                      polylines: {
                        if (_routePoints.isNotEmpty)
                          Polyline(
                            polylineId: const PolylineId('route'),
                            points: _routePoints,
                            color: const Color(0xFF2D62ED),
                            width: 5,
                          ),
                      },
                      myLocationEnabled: true,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      onMapCreated: (controller) => _mapController = controller,
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
                      ? "${_driverName ?? 'Driver'} is waiting outside for you."
                      : "${_driverName ?? 'Driver'} is on the way",
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
  Widget _buildDriverCard(BuildContext context) {
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
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 16),
                    const Text(
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
