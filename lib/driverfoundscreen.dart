import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gowayanad/ridestartedscreen.dart';
import 'package:gowayanad/driverreachedscreen.dart';
import 'package:gowayanad/services/ride_service.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

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
  String? _driverPhone;
  bool _isPinVisible = false;
  Timer? _countdownTimer;
  String _timeLeft = "15:00";

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
        setState(() {
          _rideData = data;
        });

        _startCountdown();

        if (_driverName == null && _rideData?['driverId'] != null) {
          _rideService.getUserDetails(_rideData!['driverId']).then((user) {
            if (mounted && user != null) {
              setState(() {
                _driverName = user['fullName'] ?? user['name'] ?? "Driver";
                _driverPhone = user['phoneNumber'];
              });
            }
          });
        }

        if (_rideData?['status'] == 'arrived') {
          if (mounted) {
            _stopTimers();
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
            _stopTimers();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RideStartedScreen(rideId: widget.rideId),
              ),
            );
          }
        } else if (_rideData?['status'] == 'cancelled') {
          if (mounted) {
            _stopTimers();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ride was cancelled.')),
            );
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      }
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    final expiry = _rideData?['pinExpiryAt'] as Timestamp?;
    if (expiry == null) return;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final difference = expiry.toDate().difference(now);

      if (difference.isNegative) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _timeLeft = "Expired";
          });
          _rideService.regenerateRidePin(widget.rideId);
        }
      } else {
        final minutes = difference.inMinutes;
        final seconds = difference.inSeconds % 60;
        if (mounted) {
          setState(() {
            _timeLeft =
                "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
          });
        }
      }
    });
  }

  void _stopTimers() {
    _rideSubscription?.cancel();
    _countdownTimer?.cancel();
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }

  Future<void> _makeCall() async {
    if (_driverPhone == null || _driverPhone!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Driver phone number not available")),
        );
      }
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: _driverPhone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
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
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Map / Header Section
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF2D62ED), const Color(0xFF5386FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.airport_shuttle,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _rideData?['status'] == 'arrived'
                        ? "Driver is Here"
                        : "Driver is coming...",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _driverName != null
                        ? "$_driverName is on the way"
                        : "Connecting with Driver...",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
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

                  // 3b. Dynamic PIN Section
                  _buildPinSection(),
                  const SizedBox(height: 16),

                  // 4. Pickup & Destination Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildLocationCard(
                          "Pickup",
                          _rideData?['pickupLocation'] ?? "Kalpetta",
                          "Wayanad, Kerala",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLocationCard(
                          "Destination",
                          _rideData?['destinationLocation'] ??
                              _rideData?['destination'] ??
                              "S. Bathery",
                          "Distance: ${(_rideData?['distanceKm'] ?? _rideData?['distance'] ?? 0).toStringAsFixed(1)} KM",
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
                        ? "Driver has arrived"
                        : "Driver is on the way",
                    _rideData?['status'] == 'arrived'
                        ? "Waiting for you"
                        : "Arriving shortly",
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
            isArrived ? Icons.info_outline : Icons.check_circle_outline,
            color: isArrived ? Colors.orange : Colors.green,
            size: 24,
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
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinSection() {
    bool isExpired = _timeLeft == "Expired";
    String otp = _rideData?['otp']?.toString() ?? "----";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Ride OTP",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isExpired ? Colors.red.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: isExpired ? Colors.red : Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isExpired ? "Expired" : "Expires in: $_timeLeft",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isExpired ? Colors.red : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _isPinVisible = !_isPinVisible),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5FE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2D62ED).withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _isPinVisible ? otp.split('').join(' ') : "• • • •",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: Color(0xFF2D62ED),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isPinVisible ? "Tap to hide" : "Tap to reveal",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Share this OTP with the driver to start your ride.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFEBF2FF),
            child: Icon(Icons.person, color: Color(0xFF2D62ED), size: 35),
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
                  children: const [
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
            onPressed: _driverPhone != null ? _makeCall : null,
            icon: const Icon(Icons.call, size: 18, color: Colors.white),
            label: const Text(
              "Call Driver",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFF2D62ED) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone
                      ? const Color(0xFF2D62ED)
                      : Colors.grey.shade300,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(width: 2, height: 30, color: Colors.grey.shade300),
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
                fontSize: 14,
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
