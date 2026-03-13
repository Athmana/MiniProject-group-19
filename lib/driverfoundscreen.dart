import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gowayanad/ridestartedscreen.dart';
import 'package:gowayanad/driverreachedscreen.dart';
import 'package:gowayanad/services/ride_service.dart';
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
                _driverName = user['name'] ?? user['fullName'] ?? "Driver";
              });
            }
          });
        }

        if (_rideData?['status'] == 'arrived') {
          if (mounted) {
            _rideSubscription?.cancel();
            _countdownTimer?.cancel();
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
            _countdownTimer?.cancel();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RideStartedScreen(rideId: widget.rideId),
              ),
            );
          }
        } else if (_rideData?['status'] == 'cancelled') {
          if (mounted) {
            _rideSubscription?.cancel();
            _countdownTimer?.cancel();
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

  @override
  void dispose() {
    _rideSubscription?.cancel();
    _countdownTimer?.cancel();
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
            // 1. Header Section (Replacing Map)
            Container(
              height: 200,
              width: double.infinity,
              color: const Color(0xFFE3F2FD),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.local_taxi,
                      size: 60,
                      color: Color(0xFF2D62ED),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _driverName != null
                          ? "$_driverName is on the way"
                          : "Connecting with Driver...",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Expected soon at your pickup location",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
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
                          "Pickup Location",
                          _rideData?['pickupLocation'] ?? "Kalpetta Main Road",
                          "Wayanad, Kerala",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLocationCard(
                          "Destination",
                          _rideData?['destinationLocation'] ??
                              "Sulthan Bathery Hospital",
                          "Distance calculated",
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

  Widget _buildPinSection() {
    bool isExpired = _timeLeft == "Expired";
    String ridePin = _rideData?['ridePin']?.toString() ?? "------";

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
                "Ride PIN",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      isExpired ? "PIN Expired" : "Expires in: $_timeLeft",
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
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              setState(() {
                _isPinVisible = !_isPinVisible;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5FE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2D62ED).withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Text(
                    _isPinVisible ? ridePin.split('').join(' ') : "• • • • • •",
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Share this PIN with the driver to start your ride.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
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
            onPressed: () {},
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
