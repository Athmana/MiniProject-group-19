import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gowayanad/services/location_service.dart';
import 'package:gowayanad/services/map_service.dart';
import 'package:gowayanad/services/ride_service.dart';
import 'package:gowayanad/waitingfordriverscreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CabBookingHome extends StatefulWidget {
  const CabBookingHome({super.key});

  @override
  State<CabBookingHome> createState() => _CabBookingHomeState();
}

class _CabBookingHomeState extends State<CabBookingHome> {
  Position? _currentPosition;
  bool _isLoadingLocation = true;

  final TextEditingController _destinationController = TextEditingController();
  String? _selectedVehicleType;
  String? _selectedVehiclePrice;

  GoogleMapController? _mapController;
  List<LatLng> _routePoints = [];
  LatLng? _destinationLocation;
  Timer? _debounce;

  double? _calculatedDistance;
  final Map<String, String> _vehiclePrices = {
    "Bike": "...",
    "Auto": "...",
    "Car": "...",
    "Ambulance": "Free",
  };
  bool _isCalculatingFare = false;
  MapType _currentMapType = MapType.normal;
  final Set<Marker> _driverMarkers = {};
  StreamSubscription<QuerySnapshot>? _driverSubscription;
  BitmapDescriptor? _carIcon;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _loadMarkerIcons();
    _startListeningToDrivers();
  }

  Future<void> _loadMarkerIcons() async {
    _carIcon =
        await BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(30, 30)),
          'assets/car_icon.png',
        ).catchError(
          (_) =>
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        );
    if (mounted) setState(() {});
  }

  void _startListeningToDrivers() {
    _driverSubscription = RideService().getOnlineDriversStream().listen((
      snapshot,
    ) {
      if (!mounted) return;

      setState(() {
        _driverMarkers.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final String id = data['driverId'] ?? '';
          final double lat = data['lat'] ?? 0.0;
          final double lng = data['lng'] ?? 0.0;

          if (lat != 0 && lng != 0) {
            _driverMarkers.add(
              Marker(
                markerId: MarkerId('driver_$id'),
                position: LatLng(lat, lng),
                icon:
                    _carIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                infoWindow: const InfoWindow(title: 'Driver'),
              ),
            );
          }
        }
      });
    });
  }

  Future<void> _fetchLocation() async {
    try {
      Position position = await LocationService().getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
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

  Future<void> _calculateFares(String destination) async {
    if (destination.isEmpty || _currentPosition == null) return;

    setState(() {
      _isCalculatingFare = true;
    });

    try {
      final MapService mapService = MapService();
      final pickup = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      List<Location> locations = await locationFromAddress(destination);
      if (locations.isEmpty || !mounted) {
        if (mounted) setState(() => _isCalculatingFare = false);
        return;
      }

      final dest = LatLng(locations[0].latitude, locations[0].longitude);
      setState(() => _destinationLocation = dest);

      final results = await Future.wait([
        mapService.getPolylinePoints(pickup, dest),
        Future.value(
          Geolocator.distanceBetween(
                pickup.latitude,
                pickup.longitude,
                dest.latitude,
                dest.longitude,
              ) /
              1000,
        ),
      ]);

      if (!mounted) return;

      final points = results[0] as List<LatLng>;
      final double distanceInKm = results[1] as double;

      setState(() => _routePoints = points);
      if (_mapController != null && points.isNotEmpty) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(_getBounds(pickup, dest), 50),
        );
      }

      if (distanceInKm > 0 && mounted) {
        setState(() {
          _calculatedDistance = distanceInKm;
          _vehiclePrices["Bike"] = (30 + (8 * distanceInKm)).toStringAsFixed(0);
          _vehiclePrices["Auto"] = (50 + (12 * distanceInKm)).toStringAsFixed(
            0,
          );
          _vehiclePrices["Car"] = (100 + (18 * distanceInKm)).toStringAsFixed(
            0,
          );
          _vehiclePrices["Ambulance"] = "Free";
          _isCalculatingFare = false;
          if (_selectedVehicleType != null) {
            _selectedVehiclePrice = _vehiclePrices[_selectedVehicleType];
          }
        });
      } else {
        if (mounted) setState(() => _isCalculatingFare = false);
      }
    } catch (e) {
      debugPrint("Error calculating fares: $e");
      if (mounted) setState(() => _isCalculatingFare = false);
    }
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
    _debounce?.cancel();
    _driverSubscription?.cancel();
    _destinationController.dispose();
    super.dispose();
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
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Book Your Ride",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              "Emergency Service",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 250,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    _currentPosition == null
                        ? const Center(child: CircularProgressIndicator())
                        : GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              zoom: 14,
                            ),
                            mapType: _currentMapType,
                            markers: {
                              if (_currentPosition != null)
                                Marker(
                                  markerId: const MarkerId('pickup'),
                                  position: LatLng(
                                    _currentPosition!.latitude,
                                    _currentPosition!.longitude,
                                  ),
                                  infoWindow: const InfoWindow(
                                    title: 'Pickup Location',
                                  ),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueAzure,
                                  ),
                                ),
                              if (_destinationLocation != null)
                                Marker(
                                  markerId: const MarkerId('destination'),
                                  position: _destinationLocation!,
                                  infoWindow: const InfoWindow(
                                    title: 'Destination',
                                  ),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueRed,
                                  ),
                                ),
                              ..._driverMarkers,
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
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            onMapCreated: (controller) =>
                                _mapController = controller,
                          ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Column(
                        children: [
                          _buildMapControlButton(
                            icon: Icons.layers_outlined,
                            onPressed: () {
                              setState(() {
                                _currentMapType =
                                    _currentMapType == MapType.normal
                                    ? MapType.satellite
                                    : MapType.normal;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildMapControlButton(
                            icon: Icons.my_location,
                            onPressed: () {
                              if (_currentPosition != null &&
                                  _mapController != null) {
                                _mapController!.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                    LatLng(
                                      _currentPosition!.latitude,
                                      _currentPosition!.longitude,
                                    ),
                                    15,
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildMapControlButton(
                            icon: Icons.add,
                            onPressed: () => _mapController?.animateCamera(
                              CameraUpdate.zoomIn(),
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildMapControlButton(
                            icon: Icons.remove,
                            onPressed: () => _mapController?.animateCamera(
                              CameraUpdate.zoomOut(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _destinationController,
              onChanged: (value) {
                _debounce?.cancel();
                if (value.length > 3) {
                  _debounce = Timer(const Duration(milliseconds: 800), () {
                    _calculateFares(value);
                  });
                }
              },
              decoration: InputDecoration(
                hintText: "Enter destination address",
                suffixIcon: _isCalculatingFare
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : (_calculatedDistance != null
                          ? Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                "${_calculatedDistance!.toStringAsFixed(1)} km",
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null),
                prefixIcon: const Icon(
                  Icons.near_me_outlined,
                  color: Colors.cyan,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Select Vehicle Type",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
              children: [
                _buildVehicleCard(
                  title: "Bike",
                  desc: "Quick emergency response",
                  price: _vehiclePrices["Bike"] ?? "...",
                  seats: "1 seat",
                  time: "1-2 min",
                  icon: Icons.directions_bike,
                ),
                _buildVehicleCard(
                  title: "Auto",
                  desc: "Quick emergency response",
                  price: _vehiclePrices["Auto"] ?? "...",
                  seats: "3 seats",
                  time: "2-4 min",
                  icon: Icons.electric_rickshaw,
                ),
                _buildVehicleCard(
                  title: "Car",
                  desc: "Comfortable transport",
                  price: _vehiclePrices["Car"] ?? "...",
                  seats: "4 seats",
                  time: "3-5 min",
                  icon: Icons.directions_car,
                ),
                _buildVehicleCard(
                  title: "Ambulance",
                  desc: "Medical emergency",
                  price: _vehiclePrices["Ambulance"] ?? "Free",
                  seats: "2 seats",
                  time: "1-2 min",
                  icon: Icons.medical_services,
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    (_currentPosition != null &&
                        _destinationController.text.isNotEmpty &&
                        _selectedVehicleType != null &&
                        _selectedVehiclePrice != null &&
                        _selectedVehiclePrice != "..." &&
                        !_isCalculatingFare &&
                        !_isLoadingLocation)
                    ? () async {
                        if (_currentPosition == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Location is required'),
                            ),
                          );
                          return;
                        }

                        double destLat = 0.0;
                        double destLng = 0.0;
                        try {
                          List<Location> locations = await locationFromAddress(
                            _destinationController.text.trim(),
                          );
                          if (locations.isNotEmpty) {
                            destLat = locations.first.latitude;
                            destLng = locations.first.longitude;
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Destination not found: $e'),
                              ),
                            );
                          }
                          return;
                        }

                        final String? rideId = await RideService().requestRide(
                          pickupLocation:
                              "Lat: ${_currentPosition!.latitude}, Lng: ${_currentPosition!.longitude}",
                          pickupLat: _currentPosition!.latitude,
                          pickupLng: _currentPosition!.longitude,
                          destination: _destinationController.text.trim(),
                          destinationLat:
                              _destinationLocation?.latitude ?? destLat,
                          destinationLng:
                              _destinationLocation?.longitude ?? destLng,
                          vehicleType: _selectedVehicleType!,
                          price: _selectedVehiclePrice!,
                          distance: _calculatedDistance ?? 0.0,
                        );

                        if (rideId != null && mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  WaitingForDriverScreen(rideId: rideId),
                            ),
                          );
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to request ride'),
                              ),
                            );
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      (_selectedVehicleType != null &&
                          _destinationController.text.trim().isNotEmpty)
                      ? const Color(0xFF2855D3)
                      : const Color(0xFF94B5F9),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF94B5F9),
                  disabledForegroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Confirm Emergency Ride",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard({
    required String title,
    required String desc,
    required String price,
    required String seats,
    required String time,
    required IconData icon,
  }) {
    final bool isSelected = _selectedVehicleType == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVehicleType = title;
          _selectedVehiclePrice = _vehiclePrices[title] ?? price;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F0FF) : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.blueGrey),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              desc,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              maxLines: 2,
            ),
            const Spacer(),
            Text(
              price == "Free" ? "Free" : "₹$price",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.blueAccent, size: 20),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
