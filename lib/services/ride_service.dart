import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> requestRide({
    required String pickupLocation,
    required double pickupLat,
    required double pickupLng,
    required String destination,
    required String vehicleType,
    required String price,
  }) async {
    try {
      final String? userId = _auth.currentUser?.uid;

      // We proceed even if userId is null for testing, but in production we'd require it.
      DocumentReference rideRef = await _firestore.collection('rides').add({
        'riderId': userId ?? 'anonymous_rider',
        'pickupLocation': pickupLocation,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'destination': destination,
        'vehicleType': vehicleType,
        'price': price,
        'status': 'pending', // pending, accepted, completed, cancelled
        'driverId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return rideRef.id;
    } catch (e) {
      print("Error requesting ride: $e");
      return null;
    }
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
        .orderBy('createdAt', descending: true)
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
      final String? driverId = _auth.currentUser?.uid;

      await _firestore.collection('rides').doc(rideId).update({
        'status': 'accepted',
        'driverId': driverId ?? 'anonymous_driver',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print("Error accepting ride: $e");
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
      print("Error cancelling ride: $e");
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
      print("Error updating ride status to $newStatus: $e");
      return false;
    }
  }
}
