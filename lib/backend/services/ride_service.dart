import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class RideService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  RideService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

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
    ); 
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
      final String? riderId = _auth.currentUser?.uid;
      if (riderId == null) throw Exception("User not logged in");

      String otp = (1000 + Random().nextInt(9000)).toString();
      DocumentReference requestRef = _db.collection('ride_requests').doc();

      Map<String, dynamic> rideData = {
        'id': requestRef.id,
        'riderId': riderId,
        'status': 'waiting',
        'assignedDriverId': null,
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
        'declinedDrivers': [],
        'acceptedDriverId': null,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await requestRef.set(rideData);
      return requestRef.id;
    } catch (e) {
      debugPrint("Error in requestRide: $e");
      rethrow;
    }
  }

  /// Helper to get multiple nearby available drivers
  Future<List<String>> _getNearestAvailableDrivers({
    required double lat,
    required double lng,
    required String vehicleType,
    int limit = 5,
    List<dynamic> declined = const [],
  }) async {
    try {
      Query query = _db.collection('drivers')
          .where('status', isEqualTo: 'available');

      QuerySnapshot snapshot = await query.get();
      List<Map<String, dynamic>> drivers = [];

      for (var doc in snapshot.docs) {
        if (declined.contains(doc.id)) continue;
        
        final data = doc.data() as Map<String, dynamic>;
        double? dLat = (data['currentLat'] as num?)?.toDouble() ?? (data['location'] as GeoPoint?)?.latitude;
        double? dLng = (data['currentLng'] as num?)?.toDouble() ?? (data['location'] as GeoPoint?)?.longitude;
        String? dVehicleType = data['vehicleType'];

        if (dLat != null && dLng != null) {
          bool typeMatches = true;
          if (dVehicleType != null && dVehicleType.isNotEmpty) {
            typeMatches = dVehicleType.toLowerCase() == vehicleType.toLowerCase();
          }

          if (typeMatches) {
            double distance = calculateDistance(lat, lng, dLat, dLng);
            // Only consider drivers within 10km for auto-assignment
            if (distance <= 10.0) {
              drivers.add({
                'id': doc.id,
                'distance': distance,
              });
            }
          }
        }
      }

      // Sort by distance
      drivers.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
      
      return drivers.map((d) => d['id'] as String).take(limit).toList();
    } catch (e) {
      debugPrint("Error searching drivers: $e");
      return [];
    }
  }

  Future<bool> updatePaymentStatus(String rideId, String paymentStatus) async {
    try {
      await _db.collection('ride_requests').doc(rideId).update({
        'paymentStatus': paymentStatus,
        'paidAt': FieldValue.serverTimestamp(),
        if (paymentStatus == 'completed') 'status': 'completed',
        if (paymentStatus == 'completed') 'completedAt': FieldValue.serverTimestamp(),
      });
      
      // Also cleanup driver if completed
      if (paymentStatus == 'completed') {
        final doc = await _db.collection('ride_requests').doc(rideId).get();
        if (doc.exists) {
           final data = doc.data() as Map<String, dynamic>;
           String? dId = data['assignedDriverId'] ?? data['acceptedDriverId'] ?? data['driverId'];
           if (dId != null) {
             await _db.collection('drivers').doc(dId).update({
               'status': 'available',
               'available': true,
               'currentRideId': null,
             });
           }
        }
      }
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
      await _db.collection('ride_requests').doc(rideId).update({
        'rating': rating,
        'feedback': feedback,
      });

      // 2. Dynamically update Driver's profile rating
      final rideDoc = await _db.collection('ride_requests').doc(rideId).get();
      if (rideDoc.exists) {
        final data = rideDoc.data() as Map<String, dynamic>;
        final driverId = data['driverId'] ?? data['acceptedDriverId'] ?? data['assignedDriverId'];

        if (driverId != null) {
          final driverRef = _db.collection('drivers').doc(driverId);
          await _db.runTransaction((transaction) async {
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
      DocumentSnapshot doc = await _db
          .collection('riders')
          .doc(userId)
          .get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }

      doc = await _db.collection('drivers').doc(userId).get();
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
    return _db.collection('ride_requests').doc(rideId).snapshots();
  }

  Stream<QuerySnapshot> getPendingRides() {
    return _db
        .collection('ride_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot> getDriverCompletedRides(String driverId) {
    return _db
        .collection('ride_requests')
        .where('acceptedDriverId', isEqualTo: driverId)
        .snapshots();
  }

  Stream<QuerySnapshot> getRiderCompletedRides(String riderId) {
    return _db
        .collection('ride_requests')
        .where('riderId', isEqualTo: riderId)
        .snapshots();
  }

  Future<bool> acceptRideRequest(String requestId) async {
    try {
      final String? driverId = _auth.currentUser?.uid;
      if (driverId == null) throw Exception("Driver not logged in");

      return await _db.runTransaction((transaction) async {
        DocumentReference requestRef = _db.collection('ride_requests').doc(requestId);
        DocumentSnapshot snapshot = await transaction.get(requestRef);

        if (!snapshot.exists) return false;
        final data = snapshot.data() as Map<String, dynamic>;

        // Broadcast Model: Check if status is still 'waiting'
        if (data['status'] != 'waiting') return false;

        // 1. Mark Request as Accepted by THIS driver
        transaction.update(requestRef, {
          'status': 'accepted',
          'driverId': driverId, 
          'acceptedDriverId': driverId,
          'acceptedAt': FieldValue.serverTimestamp(),
        });

        // 2. Mark Driver as Busy
        transaction.update(_db.collection('drivers').doc(driverId), {
          'status': 'busy',
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
      final String? driverId = _auth.currentUser?.uid;
      if (driverId == null) throw Exception("Driver not logged in");

      DocumentReference requestRef = _db.collection('ride_requests').doc(requestId);

      await _db.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(requestRef);
        if (!snapshot.exists) return false;
        
        final data = snapshot.data() as Map<String, dynamic>;
        List declined = List.from(data['declinedDrivers'] ?? []);
        if (!declined.contains(driverId)) {
          declined.add(driverId);
        }

        // Just add to declined list so this driver doesn't see it anymore.
        // The ride status remains 'waiting' for other drivers.
        transaction.update(requestRef, {
          'declinedDrivers': declined,
          'lastDeclineAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
      return true;

    } catch (e) {
      debugPrint("Error declining ride: $e");
      return false;
    }
  }

  /// Reassigns a ride that is 'waiting' or timed out
  Future<void> reassignRide(String rideId) async {
    try {
       DocumentSnapshot rSnap = await _db.collection('ride_requests').doc(rideId).get();
       if (!rSnap.exists) return;
       final data = rSnap.data() as Map<String, dynamic>;
       
       if (data['status'] != 'waiting' && data['status'] != 'assigned') return;

       double pLat = data['pickupLat'];
       double pLng = data['pickupLng'];
       String vType = data['vehicleType'];
       List declined = data['declinedDrivers'] ?? [];

       List<String> nextDrivers = await _getNearestAvailableDrivers(
         lat: pLat, 
         lng: pLng, 
         vehicleType: vType,
         declined: declined,
         limit: 3
       );

       if (nextDrivers.isNotEmpty) {
         await _db.runTransaction((transaction) async {
            String? selectedId;
            for (String rid in nextDrivers) {
              DocumentSnapshot dSnap = await transaction.get(_db.collection('drivers').doc(rid));
              if (dSnap.exists) {
                final dData = dSnap.data() as Map<String, dynamic>;
                if (dData['status'] == 'available') {
                  selectedId = rid;
                  break;
                }
              }
            }

            if (selectedId != null) {
              transaction.update(_db.collection('ride_requests').doc(rideId), {
                'status': 'assigned',
                'assignedDriverId': selectedId,
              });
              transaction.update(_db.collection('drivers').doc(selectedId), {
                'status': 'busy',
                'available': false,
                'currentRideId': rideId,
              });
            }
         });
       }
    } catch (e) {
      debugPrint("Error reassigning ride: $e");
    }
  }

  Future<void> updateDriverAvailability(bool available) async {
    final String? driverId = _auth.currentUser?.uid;
    if (driverId == null) return;

    await _db.collection('drivers').doc(driverId).update({
      'status': available ? 'available' : 'offline',
      'available': available,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCurrentLocation(double lat, double lng) async {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Update both driver record and any active ride
    WriteBatch batch = _db.batch();
    
    DocumentReference driverRef = _db.collection('drivers').doc(userId);
    batch.update(driverRef, {
      'currentLat': lat,
      'currentLng': lng,
      'locationUpdatedAt': FieldValue.serverTimestamp(),
    });

    // Also find if they have an active ride to update for the rider
    QuerySnapshot activeRides = await _db
        .collection('ride_requests')
        .where('acceptedDriverId', isEqualTo: userId)
        .where('status', whereIn: ['accepted', 'arrived', 'ongoing'])
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

  Stream<QuerySnapshot> getBroadcastedRequests() {
    return _db
        .collection('ride_requests')
        .where('status', isEqualTo: 'waiting')
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
      DocumentReference docRef = _db.collection('ride_requests').doc(rideId);
      
      return await _db.runTransaction((transaction) async {
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
          String? dId = data['assignedDriverId'] ?? data['acceptedDriverId'] ?? data['driverId'];
          if (dId != null) {
            transaction.update(_db.collection('drivers').doc(dId), {
              'status': 'available',
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

  Stream<DocumentSnapshot> listenToRideRequest(String requestId) {
    return _db.collection('ride_requests').doc(requestId).snapshots();
  }

  Stream<QuerySnapshot> getAssignedRequests() {
    final String? driverId = _auth.currentUser?.uid;
    if (driverId == null) return const Stream.empty();

    return _db
        .collection('ride_requests')
        .where('assignedDriverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'assigned')
        .snapshots();
  }

  Future<Map<String, dynamic>> verifyRidePin(
    String rideId,
    String enteredPin,
  ) async {
    try {
      DocumentSnapshot doc = await _db
          .collection('ride_requests')
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
        await updateRideStatus(rideId, 'ongoing');
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
      await _db.collection('ride_requests').doc(rideId).update({
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

      await _db.collection('ride_requests').doc(rideId).update({
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
