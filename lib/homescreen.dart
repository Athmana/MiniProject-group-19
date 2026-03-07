import 'package:flutter/material.dart';
import 'package:gowayanad/services/ride_service.dart';
import 'package:gowayanad/waitingfordriverscreen.dart';
import 'package:gowayanad/services/location_service.dart';
import 'package:gowayanad/services/map_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CabBookingHome extends StatefulWidget {
  const CabBookingHome({super.key});

  @override
  State<CabBookingHome> createState() => _CabBookingHomeState();
}

class _CabBookingHomeState extends State<CabBookingHome> {
  bool _isLoadingLocation = true;

  final TextEditingController _destinationController = TextEditingController();
  String? _selectedVehicleType;

  GoogleMapController? _mapController;
  LatLng? _pickupLatLng;
  LatLng? _destinationLatLng;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  String? _distance;
  String? _duration;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      Position position = await LocationService().getCurrentLocation();
      if (mounted) {
        setState(() {
          _pickupLatLng = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
          _addPickupMarker(_pickupLatLng!);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      }
    }
  }

  void _addPickupMarker(LatLng pos) {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pos,
          infoWindow: const InfoWindow(title: 'Pickup Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });
  }

  void _onMapTapped(LatLng pos) async {
    setState(() {
      _destinationLatLng = pos;
      _markers.removeWhere((m) => m.markerId.value == 'destination');
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: pos,
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });

    // Get address for the tapped location
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        _destinationController.text = placemarks[0].name ?? "Selected Location";
      }
    } catch (e) {
      _destinationController.text = "Selected Location";
    }

    _drawRoute();
  }

  Future<void> _drawRoute() async {
    if (_pickupLatLng == null || _destinationLatLng == null) return;

    final mapService = MapService();
    final polylinePoints = await mapService.getRoutePolylines(
      _pickupLatLng!,
      _destinationLatLng!,
    );
    final details = await mapService.getDistanceAndETA(
      _pickupLatLng!,
      _destinationLatLng!,
    );

    if (mounted) {
      setState(() {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: polylinePoints,
            color: Colors.blue,
            width: 5,
          ),
        );
        if (details != null) {
          _distance = details['distance'];
          _duration = details['duration'];
        }
      });

      // Fit map to markers
      LatLngBounds bounds;
      if (_pickupLatLng!.latitude > _destinationLatLng!.latitude) {
        bounds = LatLngBounds(
          southwest: LatLng(
            _destinationLatLng!.latitude,
            _pickupLatLng!.longitude < _destinationLatLng!.longitude
                ? _pickupLatLng!.longitude
                : _destinationLatLng!.longitude,
          ),
          northeast: LatLng(
            _pickupLatLng!.latitude,
            _pickupLatLng!.longitude > _destinationLatLng!.longitude
                ? _pickupLatLng!.longitude
                : _destinationLatLng!.longitude,
          ),
        );
      } else {
        bounds = LatLngBounds(
          southwest: LatLng(
            _pickupLatLng!.latitude,
            _pickupLatLng!.longitude < _destinationLatLng!.longitude
                ? _pickupLatLng!.longitude
                : _destinationLatLng!.longitude,
          ),
          northeast: LatLng(
            _destinationLatLng!.latitude,
            _pickupLatLng!.longitude > _destinationLatLng!.longitude
                ? _pickupLatLng!.longitude
                : _destinationLatLng!.longitude,
          ),
        );
      }
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Book Your Ride",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              "Emergency Service",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Google Map
          _isLoadingLocation
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _pickupLatLng ?? const LatLng(11.6094, 76.0828),
                    zoom: 14,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  markers: _markers,
                  polylines: _polylines,
                  onTap: _onMapTapped,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  padding: const EdgeInsets.only(bottom: 300),
                ),

          // Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 380,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Distance and ETA
                    if (_distance != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Distance: $_distance",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "ETA: $_duration",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Pickup Location (Read-only)
                    const Text(
                      "Pickup Location",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isLoadingLocation
                                  ? "Fetching location..."
                                  : "My Current Location",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Destination
                    const Text(
                      "Destination",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _destinationController,
                      decoration: InputDecoration(
                        hintText: "Tap on map to select destination",
                        prefixIcon: const Icon(
                          Icons.near_me_outlined,
                          color: Colors.cyan,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                      onSubmitted: (val) async {
                        try {
                          List<Location> locations = await locationFromAddress(
                            val,
                          );
                          if (locations.isNotEmpty) {
                            _onMapTapped(
                              LatLng(
                                locations.first.latitude,
                                locations.first.longitude,
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Could not find address"),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Vehicle Selection
                    const Text(
                      "Select Vehicle",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildVehicleItem(
                            "Auto",
                            Icons.electric_rickshaw,
                            "299",
                          ),
                          _buildVehicleItem("Car", Icons.directions_car, "599"),
                          _buildVehicleItem(
                            "Truck",
                            Icons.local_shipping,
                            "799",
                          ),
                          _buildVehicleItem(
                            "Ambulance",
                            Icons.medical_services,
                            "1200",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Confirm Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                            (_isLoadingLocation ||
                                _selectedVehicleType == null ||
                                _destinationLatLng == null)
                            ? null
                            : () async {
                                final String? rideId = await RideService()
                                    .requestRide(
                                      pickupLocation: "My Location",
                                      pickupLat: _pickupLatLng!.latitude,
                                      pickupLng: _pickupLatLng!.longitude,
                                      destination: _destinationController.text
                                          .trim(),
                                      destLat: _destinationLatLng!.latitude,
                                      destLng: _destinationLatLng!.longitude,
                                      vehicleType: _selectedVehicleType!,
                                    );

                                if (rideId != null && context.mounted) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          WaitingForDriverScreen(
                                            rideId: rideId,
                                          ),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2855D3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Confirm Emergency Ride",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  Widget _buildVehicleItem(String title, IconData icon, String price) {
    final bool isSelected = _selectedVehicleType == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedVehicleType = title),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F0FF) : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade200,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue : Colors.black,
              ),
            ),
            Text(
              "₹$price",
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
