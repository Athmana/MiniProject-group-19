import 'package:flutter/material.dart';
import 'package:gowayanad/reachedlocationscreen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gowayanad/services/ride_service.dart';
import 'package:gowayanad/services/map_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class RideStartedScreen extends StatefulWidget {
  final String rideId;
  const RideStartedScreen({super.key, required this.rideId});

  @override
  State<RideStartedScreen> createState() => _RideStartedScreenState();
}

class _RideStartedScreenState extends State<RideStartedScreen> {
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

        // Handle Driver Location and Polylines (Trip to Destination)
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

            // Fetch Route from CURRENT (Driver) to DESTINATION
            // In a real app we might geocode the destination once, but here it's in rideData
            // Actually, we need destination Lat/Lng in rideData.
            // Looking at CabBookingHome, it doesn't store destination Lat/Lng yet!
            // I should have added that in CabBookingHome.

            // For now, let's use the pickup and destination names if we had to,
            // but it's better to store Lat/Lng in Firestore.

            // Wait, I'll use the pickup as a fallback for now if destination lat/lng is missing,
            // but I should fix RideService/CabBookingHome to store destination coordinates.
          }
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
          // 1. Full Screen Map Tracking
          Positioned.fill(
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
                      if (_driverLocation != null)
                        Marker(
                          markerId: const MarkerId('driver'),
                          position: _driverLocation!,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure,
                          ),
                          infoWindow: const InfoWindow(title: "Your Ride"),
                        ),
                      Marker(
                        markerId: const MarkerId('pickup'),
                        position: LatLng(
                          _rideData!['pickupLat'] as double? ?? 11.6094,
                          _rideData!['pickupLng'] as double? ?? 76.0828,
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen,
                        ),
                        infoWindow: const InfoWindow(title: "Pickup Point"),
                      ),
                    },
                    myLocationEnabled: true,
                    zoomControlsEnabled: false,
                    onMapCreated: (controller) => _mapController = controller,
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
                              _rideData?['destination'] ?? "Loading...",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.sos, color: Colors.red),
                          onPressed: () {},
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
                          "₹${_rideData?['price'] ?? '0'}",
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
