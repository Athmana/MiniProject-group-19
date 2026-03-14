import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

      String otp = (1000 + Random().nextInt(9000)).toString(); // 4-digit OTP
      DateTime expiryTime = DateTime.now().add(const Duration(minutes: 15));

      DocumentReference docRef = await _firestore.collection('rides').add({
        'riderId': riderId,
        'driverId': null,
        'status': 'pending',
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
        'rideStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'pinExpiryAt': Timestamp.fromDate(expiryTime),
      });
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updatePaymentStatus(String rideId, String paymentStatus) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
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
      await _firestore.collection('rides').doc(rideId).update({
        'rating': rating,
        'feedback': feedback,
      });
      return true;
    } catch (e) {
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
    return _firestore.collection('rides').doc(rideId).snapshots();
  }

  Stream<QuerySnapshot> getPendingRides() {
    return _firestore
        .collection('rides')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot> getDriverCompletedRides(String driverId) {
    return _firestore
        .collection('rides')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'completed')
        .snapshots();
  }

  Stream<QuerySnapshot> getRiderCompletedRides(String riderId) {
    return _firestore
        .collection('rides')
        .where('riderId', isEqualTo: riderId)
        .where('status', isEqualTo: 'completed')
        .snapshots();
  }

  Future<bool> acceptRide(String rideId) async {
    try {
      final String? driverId = FirebaseAuth.instance.currentUser?.uid;
      if (driverId == null) throw Exception("Driver not logged in");

      return await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(
          _firestore.collection('rides').doc(rideId),
        );
        if (!snapshot.exists) return false;

        final data = snapshot.data() as Map<String, dynamic>;
        if (data['status'] != 'pending') return false;

        transaction.update(snapshot.reference, {
          'driverId': driverId,
          'status': 'accepted',
          'acceptedAt': FieldValue.serverTimestamp(),
          'rideStatus': 'accepted',
        });
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelRide(String rideId) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'status': 'cancelled',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateRideStatus(String rideId, String newStatus) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(
          _firestore.collection('rides').doc(rideId),
        );
        if (!snapshot.exists) return false;

        final data = snapshot.data() as Map<String, dynamic>;
        // Don't update if already cancelled or completed
        if (data['status'] == 'cancelled' || data['status'] == 'completed')
          return false;

        transaction.update(snapshot.reference, {
          'status': newStatus,
          'rideStatus': newStatus,
          '${newStatus}At': FieldValue.serverTimestamp(),
        });
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  Future<bool> regenerateRidePin(String rideId) async {
    try {
      String newOtp = (1000 + Random().nextInt(9000)).toString();
      DateTime newExpiry = DateTime.now().add(const Duration(minutes: 15));

      await _firestore.collection('rides').doc(rideId).update({
        'otp': newOtp,
        'pinExpiryAt': Timestamp.fromDate(newExpiry),
        'pinUpdatedAt': FieldValue.serverTimestamp(),
      });
      return true;
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
          .collection('rides')
          .doc(rideId)
          .get();
      if (!doc.exists) return {'success': false, 'message': 'Ride not found'};

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String correctPin = data['otp']?.toString() ?? "";
      Timestamp? expiry = data['pinExpiryAt'];

      if (expiry != null && DateTime.now().isAfter(expiry.toDate())) {
        await regenerateRidePin(rideId);
        return {
          'success': false,
          'message': 'OTP expired and has been refreshed.',
        };
      }

      if (enteredPin == correctPin) {
        await _firestore.collection('rides').doc(rideId).update({
          'status': 'started',
          'rideStatus': 'started',
          'startedAt': FieldValue.serverTimestamp(),
        });
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
      await _firestore.collection('rides').doc(rideId).update({
        'driverLat': lat,
        'driverLng': lng,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
