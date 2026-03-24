import 'package:flutter/material.dart';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gowayanad/frontend/screens/driverfoundscreen.dart';
import 'package:gowayanad/frontend/screens/homepage.dart';
import 'package:gowayanad/backend/services/ride_service.dart';

class WaitingForDriverScreen extends StatefulWidget {
  final String rideId;
  final RideService? rideService;
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;

  const WaitingForDriverScreen({
    super.key,
    required this.rideId,
    this.rideService,
    this.firestore,
    this.auth,
  });

  @override
  State<WaitingForDriverScreen> createState() => _WaitingForDriverScreenState();
}

class _WaitingForDriverScreenState extends State<WaitingForDriverScreen> {
  late final RideService _rideService;
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  StreamSubscription<DocumentSnapshot>? _rideSubscription;

  DateTime _screenOpenTime = DateTime.now();
  Timer? _timeoutTimer;
  bool _isNavigating = false;
  String _statusTitle = "Booking Confirmed!";
  String _statusMessage = "Searching for the nearest available driver to accept your emergency request...";

  @override
  void initState() {
    super.initState();
    _rideService = widget.rideService ?? RideService();
    _firestore = widget.firestore ?? FirebaseFirestore.instance;
    _auth = widget.auth ?? FirebaseAuth.instance;
    _listenToRideStatus();
    _startTimeoutTimer();
  }

  void _startTimeoutTimer() {
    _timeoutTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (!mounted) return;
      
      final snapshot = await _rideService.listenToRideRequest(widget.rideId).first;
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final String status = data['status'] ?? '';

        // In broadcast model, 'any' driver can accept. 
        // We only care if status is still 'waiting'.
        if (status == 'waiting') {
           debugPrint("DEBUG: Researching... no drivers accepted yet after 15s.");
           // Optional: We could trigger a local notification or update UI
        }
      }

      // Final 120s (2 mins) hard timeout
      if (DateTime.now().difference(_screenOpenTime).inSeconds > 120) {
        _timeoutTimer?.cancel();
        if (mounted && !_isNavigating) {
          _isNavigating = true;
          // Update status so drivers no longer see the broadcast
          await _rideService.updateRideStatus(widget.rideId, 'no_driver_found');
          if (!mounted) return;
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No drivers accepted your request. Please try again later.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => EmergencyRideHome(
                rideService: _rideService,
                firestore: _firestore,
                auth: _auth,
              ),
            ),
            (route) => false,
          );
        }
      }
    });
  }

  void _listenToRideStatus() {
    _rideSubscription = _rideService.listenToRideRequest(widget.rideId).listen((
      snapshot,
    ) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final String status = data['status'] ?? '';
        
        // Show different messages based on status
        if (mounted) {
          setState(() {
            if (status == 'waiting') {
              _statusTitle = "Searching for Drivers";
              _statusMessage = "Your request is being broadcasted to all nearby available drivers...";
            } else if (status == 'accepted') {
              _statusTitle = "Driver Found!";
              _statusMessage = "A driver has accepted your request.";
            }
          });
        }
        
        // Check for declines
        final lastDecline = data['lastDeclineAt'] as Timestamp?;
        if (lastDecline != null && lastDecline.toDate().isAfter(_screenOpenTime)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('A driver declined your request. Re-assigning to the next nearest driver...'),
                duration: Duration(seconds: 2),
              ),
            );
            _screenOpenTime = lastDecline.toDate().add(const Duration(seconds: 1));
          }
        }

        if (status == 'accepted') {
          _timeoutTimer?.cancel();
          if (mounted && !_isNavigating) {
            _isNavigating = true;
            _rideSubscription?.cancel();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DriverFoundScreen(
                  rideId: widget.rideId,
                  rideService: _rideService,
                  firestore: _firestore,
                  auth: _auth,
                ),
              ),
            );
          }
        } else if (status == 'cancelled' || status == 'no_driver_found') {
          _timeoutTimer?.cancel();
          if (mounted && !_isNavigating) {
            _isNavigating = true;
            _rideSubscription?.cancel();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(status == 'cancelled' ? 'Ride request was cancelled.' : 'No drivers found.')),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => EmergencyRideHome(
                  rideService: _rideService,
                  firestore: _firestore,
                  auth: _auth,
                ),
              ),
              (route) => false,
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      strokeWidth: 8,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        // ignore: deprecated_member_use
                        const Color(0xFF2D62ED).withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF2D62ED),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.location_searching,
                    size: 40,
                    color: Color(0xFF2D62ED),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // 2. Status Text
              Text(
                _statusTitle,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 50),

              // 3. User Tips / Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF2D62ED),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Please keep your phone nearby. You will be notified once a driver accepts.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 4. Cancel Option
              TextButton(
                onPressed: () async {
                  if (_isNavigating) return;
                  _isNavigating = true;
                  // Cancel the ride in Firestore before popping
                  await _rideService.cancelRide(widget.rideId);
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmergencyRideHome(
                          rideService: _rideService,
                          firestore: _firestore,
                          auth: _auth,
                        ),
                      ),
                      (route) => false,
                    );
                  }
                },
                child: const Text(
                  "Cancel Request",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
