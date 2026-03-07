import 'package:flutter/material.dart';
import 'package:gowayanad/driver/driverridestartedscreen.dart';
import 'package:gowayanad/services/ride_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gowayanad/services/map_service.dart';
import 'package:gowayanad/services/location_service.dart';

class RiderPickupScreen extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> rideData;

  const RiderPickupScreen({
    super.key,
    required this.rideId,
    required this.rideData,
  });

  @override
  State<RiderPickupScreen> createState() => _RiderPickupScreenState();
}

class _RiderPickupScreenState extends State<RiderPickupScreen> {
  String? _riderName;

  final RideService _rideService = RideService();
  final MapService _mapService = MapService();
  final LocationService _locationService = LocationService();

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _driverLatLng;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _fetchRiderName();
    _loadNavigation();
  }

  void _fetchRiderName() async {
    final String? riderId = widget.rideData['riderId'];
    if (riderId != null) {
      final user = await _rideService.getUserDetails(riderId);
      if (mounted && user != null) {
        setState(() {
          _riderName = user['fullName'] ?? user['name'] ?? "Rider";
        });
      }
    }
  }

  Future<void> _loadNavigation() async {
    try {
      final pos = await _locationService.getCurrentLocation();
      _driverLatLng = LatLng(pos.latitude, pos.longitude);
      final pickupLatLng = LatLng(
        (widget.rideData['pickupLat'] as num).toDouble(),
        (widget.rideData['pickupLng'] as num).toDouble(),
      );

      final polylinePoints = await _mapService.getRoutePolylines(
        _driverLatLng!,
        pickupLatLng,
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
              markerId: const MarkerId('pickup'),
              position: pickupLatLng,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              infoWindow: const InfoWindow(title: 'Rider Pickup'),
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
            _driverLatLng!.latitude < pickupLatLng.latitude
                ? _driverLatLng!.latitude
                : pickupLatLng.latitude,
            _driverLatLng!.longitude < pickupLatLng.longitude
                ? _driverLatLng!.longitude
                : pickupLatLng.longitude,
          ),
          northeast: LatLng(
            _driverLatLng!.latitude > pickupLatLng.latitude
                ? _driverLatLng!.latitude
                : pickupLatLng.latitude,
            _driverLatLng!.longitude > pickupLatLng.longitude
                ? _driverLatLng!.longitude
                : pickupLatLng.longitude,
          ),
        );
        _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
      }
    } catch (e) {
      debugPrint("Error loading navigation: $e");
    }
  }

  Future<bool?> _showPinDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String? errorText;
        bool isVerified = false;
        final pinController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                isVerified
                    ? "PIN Verified"
                    : (errorText != null
                          ? "Incorrect PIN"
                          : "Ride Verification Required"),
                style: TextStyle(
                  color: isVerified
                      ? Colors.green
                      : (errorText != null ? Colors.red : Colors.black),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isVerified) ...[
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Rider verification successful.\nThe ride will now begin.",
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    Text(
                      errorText ??
                          "Ask the rider for the 4-digit ride PIN shown in their app.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        hintText: "0000",
                        counterText: "",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (!isVerified)
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                if (!isVerified)
                  ElevatedButton(
                    onPressed: () async {
                      final correctPin =
                          widget.rideData['otp']?.toString() ?? "4821";

                      if (pinController.text.trim() == correctPin) {
                        setDialogState(() {
                          isVerified = true;
                          errorText = null;
                        });

                        await Future.delayed(const Duration(seconds: 2));

                        if (context.mounted) {
                          Navigator.pop(context, true);
                        }
                      } else {
                        setDialogState(() {
                          errorText = "Incorrect PIN. Ask rider again.";
                          pinController.clear();
                        });
                      }
                    },
                    child: const Text("Verify PIN"),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// MAP
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  (widget.rideData['pickupLat'] as num? ?? 11.6094).toDouble(),
                  (widget.rideData['pickupLng'] as num? ?? 76.0828).toDouble(),
                ),
                zoom: 15,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              padding: const EdgeInsets.only(bottom: 250),
            ),
          ),

          /// TOP NAV CARD
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D62ED),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.navigation, color: Colors.white, size: 40),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Navigating to Pickup",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Follow the route on the map",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// BOTTOM PANEL
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
                              _riderName ?? "Loading rider...",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              "Pickup: ${widget.rideData['pickupLocation'] ?? 'Selected Location'}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.call, color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  /// START RIDE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!mounted) return;

                        bool? pinValid = await _showPinDialog();
                        if (pinValid != true) return;

                        bool success = await _rideService.updateRideStatus(
                          widget.rideId,
                          'started',
                        );

                        if (!context.mounted) return;

                        if (success) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DriverRideStartedScreen(
                                rideId: widget.rideId,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to start the ride'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "START THE RIDE",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
