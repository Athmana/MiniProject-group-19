import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class RideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Centralized Fare Calculation
  static double calculateFare(double distanceKm, String vehicleType) {
    double baseFare;
    double ratePerKm;

    switch (vehicleType.toLowerCase()) {
      case 'ambulance':
        baseFare = 300.0;
        ratePerKm = 20.0;
        break;
      case 'car':
        baseFare = 100.0;
        ratePerKm = 18.0;
        break;
      case 'auto':
        baseFare = 50.0;
        ratePerKm = 12.0;
        break;
      case 'bike':
        baseFare = 30.0;
        ratePerKm = 8.0;
        break;
      default:
        baseFare = 50.0;
        ratePerKm = 12.0;
    }

    double price = baseFare + (distanceKm * ratePerKm);
    return double.parse(
      price.toStringAsFixed(0),
    ); // Standardized to whole numbers as per UI requirements
  }

  Future<String?> requestRide({
    required String pickupLocation,
    required double pickupLat,
    required double pickupLng,
    required String destination,
    required double destinationLat,
    required double destinationLng,
    required String vehicleType,
    required double distance,
    required double price,
  }) async {
    try {
      final String? riderId = FirebaseAuth.instance.currentUser?.uid;
      if (riderId == null) throw Exception("User not logged in");

      // 1. Find nearby available drivers
      List<String> nearbyDrivers = await getNearbyDrivers(pickupLat, pickupLng, vehicleType);

      String otp = (1000 + Random().nextInt(9000)).toString();

      // 2. Create Ride Request for Broadcast
      DocumentReference requestRef = await _firestore.collection('rideRequests').add({
        'riderId': riderId,
        'status': 'searching',
        'pickupLocation': pickupLocation,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'destinationLocation': destination,
        'destinationLat': destinationLat,
        'destinationLng': destinationLng,
        'vehicleType': vehicleType,
        'distanceKm': distance,
        'fareAmount': price,
        'otp': otp,
        'notifiedDrivers': nearbyDrivers,
        'declinedDrivers': [],
        'acceptedDriver': null,
        'createdAt': FieldValue.serverTimestamp(),
        // pinExpiryAt will be set when driver arrives
      });

      return requestRef.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getNearbyDrivers(double lat, double lng, String vehicleType) async {
    try {
      // Fetch all drivers and filter in Dart to handle missing fields (like available or vehicleType)
      QuerySnapshot snapshot = await _firestore
          .collection('drivers')
          .get();

      List<String> driverIds = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        double? dLat = (data['currentLat'] as num?)?.toDouble();
        double? dLng = (data['currentLng'] as num?)?.toDouble();

        if (dLat != null && dLng != null) {
          // Robust filtering for missing fields
          bool isAvailable = data['available'] ?? false;
          String? dVehicleType = data['vehicleType'];
          
          // Case-insensitive matching
          bool typeMatches = true;
          if (dVehicleType != null && dVehicleType.isNotEmpty) {
            typeMatches = dVehicleType.toLowerCase() == vehicleType.toLowerCase();
          }

          if (isAvailable && typeMatches) {
            double distance = calculateDistance(lat, lng, dLat, dLng);
            if (distance <= 10.0) { // Increased to 10km for testing flexibility
              debugPrint("DEBUG: Found nearby driver ${doc.id} at ${distance.toStringAsFixed(1)}km");
              driverIds.add(doc.id);
            } else {
              debugPrint("DEBUG: Driver ${doc.id} is too far: ${distance.toStringAsFixed(1)}km");
            }
          } else {
            debugPrint("DEBUG: Driver ${doc.id} skipped (Available: $isAvailable, TypeMatch: $typeMatches)");
          }
        } else {
          debugPrint("DEBUG: Driver ${doc.id} has no location data in Firestore");
        }
      }
      return driverIds;
    } catch (e) {
      return [];
    }
  }

  Future<bool> updatePaymentStatus(String rideId, String paymentStatus) async {
    try {
      await _firestore.collection('rideRequests').doc(rideId).update({
        'paymentStatus': paymentStatus,
        'paidAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> submitReview(
    String rideId,
    double rating,
    String feedback,
  ) async {
    try {
      // 1. Update the ride request with the rating
      await _firestore.collection('rideRequests').doc(rideId).update({
        'rating': rating,
        'feedback': feedback,
      });

      // 2. Dynamically update Driver's profile rating
      final rideDoc = await _firestore.collection('rideRequests').doc(rideId).get();
      if (rideDoc.exists) {
        final data = rideDoc.data() as Map<String, dynamic>;
        final driverId = data['driverId'] ?? data['acceptedDriver'];

        if (driverId != null) {
          final driverRef = _firestore.collection('drivers').doc(driverId);
          await _firestore.runTransaction((transaction) async {
            final driverDoc = await transaction.get(driverRef);
            if (driverDoc.exists) {
              final dData = driverDoc.data() as Map<String, dynamic>;
              double currentRating = (dData['rating'] ?? 0.0).toDouble();
              int totalRides = (dData['totalRides'] ?? 0);

              // Calculate new average
              double newRating = ((currentRating * totalRides) + rating) / (totalRides + 1);
              
              transaction.update(driverRef, {
                'rating': newRating,
                'totalRides': totalRides + 1,
              });
            }
          });
        }
      }
      return true;
    } catch (e) {
      debugPrint("Error updating dynamic rating: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('riders')
          .doc(userId)
          .get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }

      doc = await _firestore.collection('drivers').doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a =
        0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // distance in KM
  }

  Stream<DocumentSnapshot> listenToRide(String rideId) {
    return _firestore.collection('rideRequests').doc(rideId).snapshots();
  }

  Stream<QuerySnapshot> getPendingRides() {
    return _firestore
        .collection('rideRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot> getDriverCompletedRides(String driverId) {
    return _firestore
        .collection('rideRequests')
        .where('acceptedDriver', isEqualTo: driverId)
        .where('status', isEqualTo: 'completed')
        .snapshots();
  }

  Stream<QuerySnapshot> getRiderCompletedRides(String riderId) {
    return _firestore
        .collection('rideRequests')
        .where('riderId', isEqualTo: riderId)
        .where('status', isEqualTo: 'completed')
        .snapshots();
  }

  Future<bool> acceptRideRequest(String requestId) async {
    try {
      final String? driverId = FirebaseAuth.instance.currentUser?.uid;
      if (driverId == null) throw Exception("Driver not logged in");

      return await _firestore.runTransaction((transaction) async {
        DocumentReference requestRef = _firestore.collection('rideRequests').doc(requestId);
        DocumentSnapshot snapshot = await transaction.get(requestRef);

        if (!snapshot.exists) return false;
        final data = snapshot.data() as Map<String, dynamic>;

        if (data['status'] != 'searching') return false;

        // 1. Mark Request as Accepted
        transaction.update(requestRef, {
          'status': 'accepted',
          'driverId': driverId, // Adding for backward compatibility with rider screens
          'acceptedDriver': driverId,
          'acceptedAt': FieldValue.serverTimestamp(),
        });

        // 2. Set Driver as Unavailable
        transaction.update(_firestore.collection('drivers').doc(driverId), {
          'available': false,
          'currentRideId': requestId,
        });

        return true;
      });
    } catch (e) {
      return false;
    }
  }

  Future<bool> declineRideRequest(String requestId) async {
    try {
      final String? driverId = FirebaseAuth.instance.currentUser?.uid;
      if (driverId == null) throw Exception("Driver not logged in");

      await _firestore.collection('rideRequests').doc(requestId).update({
        'declinedDrivers': FieldValue.arrayUnion([driverId]),
        'lastDeclineAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateDriverAvailability(bool available) async {
    final String? driverId = FirebaseAuth.instance.currentUser?.uid;
    if (driverId == null) return;

    await _firestore.collection('drivers').doc(driverId).update({
      'available': available,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCurrentLocation(double lat, double lng) async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Update both driver record and any active ride
    WriteBatch batch = _firestore.batch();
    
    DocumentReference driverRef = _firestore.collection('drivers').doc(userId);
    batch.update(driverRef, {
      'currentLat': lat,
      'currentLng': lng,
      'locationUpdatedAt': FieldValue.serverTimestamp(),
    });

    // Also find if they have an active ride to update for the rider
    QuerySnapshot activeRides = await _firestore
        .collection('rideRequests')
        .where('acceptedDriver', isEqualTo: userId)
        .where('status', whereIn: ['accepted', 'arrived', 'started'])
        .limit(1)
        .get();

    if (activeRides.docs.isNotEmpty) {
      batch.update(activeRides.docs.first.reference, {
        'driverLat': lat,
        'driverLng': lng,
      });
    }

    await batch.commit();
  }

  Stream<DocumentSnapshot> listenToRideRequest(String requestId) {
    return _firestore.collection('rideRequests').doc(requestId).snapshots();
  }

  Stream<QuerySnapshot> getBroadcastedRequests() {
    // We listen for ALL searching rides. 
    // The DriverHomePage will filter them based on distance and notification status.
    return _firestore
        .collection('rideRequests')
        .where('status', isEqualTo: 'searching')
        .snapshots();
  }

  Future<bool> cancelRide(String rideId) async {
    try {
      return await updateRideStatus(rideId, 'cancelled');
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateRideStatus(String rideId, String newStatus) async {
    try {
      DocumentReference docRef = _firestore.collection('rideRequests').doc(rideId);
      
      return await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return false;

        final data = snapshot.data() as Map<String, dynamic>;
        if (data['status'] == 'cancelled' || data['status'] == 'completed') return false;

        transaction.update(docRef, {
          'status': newStatus,
          '${newStatus}At': FieldValue.serverTimestamp(),
          if (newStatus == 'arrived')
            'pinExpiryAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 15))),
        });

        // Cleanup driver if ride ends
        if (newStatus == 'completed' || newStatus == 'cancelled') {
          String? dId = data['acceptedDriver'];
          if (dId != null) {
            transaction.update(_firestore.collection('drivers').doc(dId), {
              'available': true,
              'currentRideId': null,
            });
          }
        }

        return true;
      });
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> verifyRidePin(
    String rideId,
    String enteredPin,
  ) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('rideRequests')
          .doc(rideId)
          .get();
      if (!doc.exists) return {'success': false, 'message': 'Ride not found'};

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String correctPin = data['otp']?.toString() ?? "";
      Timestamp? expiry = data['pinExpiryAt'];

      if (expiry != null && DateTime.now().isAfter(expiry.toDate())) {
        return {
          'success': false,
          'message': 'OTP expired. Please ask rider to refresh.',
        };
      }

      if (enteredPin == correctPin) {
        await updateRideStatus(rideId, 'started');
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Invalid PIN.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Verification error: $e'};
    }
  }

  Future<bool> updateDriverLocation(
    String rideId,
    double lat,
    double lng,
  ) async {
    try {
      await _firestore.collection('rideRequests').doc(rideId).update({
        'driverLat': lat,
        'driverLng': lng,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> regenerateRidePin(String rideId) async {
    try {
      String newOtp = (1000 + Random().nextInt(9000)).toString();
      DateTime newExpiry = DateTime.now().add(const Duration(minutes: 15));

      await _firestore.collection('rideRequests').doc(rideId).update({
        'otp': newOtp,
        'pinExpiryAt': Timestamp.fromDate(newExpiry),
        'pinUpdatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
