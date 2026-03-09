import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class RideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> requestRide({
    required String pickupLocation,
    required double pickupLat,
    required double pickupLng,
    required String destination,
    required double destinationLat,
    required double destinationLng,
    required String vehicleType,
    required String price,
    required double distance,
  }) async {
    try {
      final String? riderId = FirebaseAuth.instance.currentUser?.uid;
      if (riderId == null) throw Exception("User not logged in");

      // Generate a random 4-digit OTP
      final String otp = (Random().nextInt(9000) + 1000).toString();

      double calculatedDistance = calculateDistance(
        pickupLat,
        pickupLng,
        destinationLat,
        destinationLng,
      );
      double computedPrice = 50 + (calculatedDistance * 12);
      computedPrice = double.parse(computedPrice.toStringAsFixed(2));

      String ridePin = (1000 + Random().nextInt(9000)).toString();

      DocumentReference docRef = await _firestore.collection('rides').add({
        'riderId': riderId,
        'otp': otp,
        'driverId': null,
        'status': 'pending',
        'pickupLocation': pickupLocation,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'destination': destination,
        'destinationLat': destinationLat,
        'destinationLng': destinationLng,
        'vehicleType': vehicleType,
        'distance': distance > 0 ? distance : calculatedDistance,
        'price': price,
        'ridePin': ridePin,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
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

  // 2. Rider or Driver listens to a specific ride's status updates
  Stream<DocumentSnapshot> listenToRide(String rideId) {
    return _firestore.collection('rides').doc(rideId).snapshots();
  }

  // 3. Driver listens to all pending rides
  Stream<QuerySnapshot> getPendingRides() {
    return _firestore
        .collection('rides')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // 3b. Driver listens to their own completed rides for history/earnings
  Stream<QuerySnapshot> getDriverCompletedRides(String driverId) {
    return _firestore
        .collection('rides')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'completed')
        // Ideally we'd order by completedAt, but that requires a composite index
        // .orderBy('completedAt', descending: true)
        .snapshots();
  }

  // 3c. Rider listens to their own completed rides for recent trips
  Stream<QuerySnapshot> getRiderCompletedRides(String riderId) {
    return _firestore
        .collection('rides')
        .where('riderId', isEqualTo: riderId)
        .where('status', isEqualTo: 'completed')
        .snapshots();
  }

  // 4. Driver accepts a ride
  Future<bool> acceptRide(String rideId) async {
    try {
      final String? driverId = FirebaseAuth.instance.currentUser?.uid;
      if (driverId == null) throw Exception("Driver not logged in");

      await _firestore.collection('rides').doc(rideId).update({
        'driverId': driverId,
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // 5. Cancel a ride
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

  // 6. Update a generic status (e.g. arrived, completed)
  Future<bool> updateRideStatus(String rideId, String newStatus) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'status': newStatus,
        '${newStatus}At':
            FieldValue.serverTimestamp(), // e.g., arrivedAt, completedAt
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // 7a. Update driver location
  Future<bool> updateDriverLocation(
    String rideId,
    double lat,
    double lng,
  ) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'driverLat': lat,
        'driverLng': lng,
      });
      return true;
    } catch (e) {
      // debugPrint("Error updating driver location: $e");
      return false;
    }
  }

  // 7. Update payment status
  Future<bool> updatePaymentStatus(String rideId, String paymentStatus) async {
    try {
      // For demonstration of failure/retry, we can simulate a random failure
      // if (Random().nextBool()) throw Exception("Payment Gateway Error");

      await _firestore.collection('rides').doc(rideId).update({
        'paymentStatus': paymentStatus,
        'paidAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // 8. Submit review
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

  // 7. Get User Details
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
