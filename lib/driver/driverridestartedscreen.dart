import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gowayanad/driver/homepage.dart';
import 'package:gowayanad/services/ride_service.dart';
import 'package:gowayanad/services/map_service.dart';
import 'package:gowayanad/services/location_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverRideStartedScreen extends StatefulWidget {
  final String rideId;
  const DriverRideStartedScreen({super.key, required this.rideId});

  @override
  State<DriverRideStartedScreen> createState() =>
      _DriverRideStartedScreenState();
}

class _DriverRideStartedScreenState extends State<DriverRideStartedScreen> {
  final RideService _rideService = RideService();
  final MapService _mapService = MapService();
  final LocationService _locationService = LocationService();

  String? _riderName;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  GoogleMapController? _mapController;
  LatLng? _driverLatLng;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadNavigation(Map<String, dynamic> data) async {
    if (_markers.isNotEmpty) return; // Already loaded

    try {
      final pos = await _locationService.getCurrentLocation();
      _driverLatLng = LatLng(pos.latitude, pos.longitude);
      final destLatLng = LatLng(
        (data['destLat'] as num).toDouble(),
        (data['destLng'] as num).toDouble(),
      );

      final polylinePoints = await _mapService.getRoutePolylines(
        _driverLatLng!,
        destLatLng,
      );

      if (mounted) {
        setState(() {
          _markers.addAll([
            Marker(
              markerId: const MarkerId('driver'),
              position: _driverLatLng!,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
              infoWindow: const InfoWindow(title: 'Your Location'),
            ),
            Marker(
              markerId: const MarkerId('destination'),
              position: destLatLng,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              infoWindow: const InfoWindow(title: 'Destination'),
            ),
          ]);
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('nav'),
              points: polylinePoints,
              color: Colors.blue,
              width: 5,
            ),
          );
        });

        // Fit map to markers
        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(
            _driverLatLng!.latitude < destLatLng.latitude
                ? _driverLatLng!.latitude
                : destLatLng.latitude,
            _driverLatLng!.longitude < destLatLng.longitude
                ? _driverLatLng!.longitude
                : destLatLng.longitude,
          ),
          northeast: LatLng(
            _driverLatLng!.latitude > destLatLng.latitude
                ? _driverLatLng!.latitude
                : destLatLng.latitude,
            _driverLatLng!.longitude > destLatLng.longitude
                ? _driverLatLng!.longitude
                : destLatLng.longitude,
          ),
        );
        _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
      }
    } catch (e) {
      debugPrint("Error loading navigation: $e");
    }
  }

  Future<void> _endRide() async {
    await FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .update({
          "status": "completed",
          "completedAt": FieldValue.serverTimestamp(),
        });

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const DriverHomePage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Trip in Progress",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .doc(widget.rideId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          // Trigger navigation load
          _loadNavigation(data);

          // Get rider details
          if (_riderName == null && data['riderId'] != null) {
            _rideService.getUserDetails(data['riderId']).then((riderData) {
              if (mounted) {
                setState(
                  () => _riderName =
                      riderData?['fullName'] ?? riderData?['name'] ?? "Rider",
                );
              }
            });
          }

          return Stack(
            children: [
              // Map view
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    (data['destLat'] as num? ?? 11.6094).toDouble(),
                    (data['destLng'] as num? ?? 76.0828).toDouble(),
                  ),
                  zoom: 15,
                ),
                onMapCreated: (controller) => _mapController = controller,
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                padding: const EdgeInsets.only(bottom: 250),
              ),

              // UI Overlay
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Target Address Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D62ED),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 10),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "DESTINATION",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data['destination'] ?? 'Loading...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Action Panel
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 15),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Color(0xFF2D62ED),
                                radius: 20,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "RIDER",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _riderName ?? "Loading...",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.call,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _endRide,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "COMPLETE RIDE",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
