import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:gowayanad/backend/services/ride_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late RideService rideService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth(signedIn: true);
    rideService = RideService(firestore: fakeFirestore, auth: mockAuth);
  });

  group('Ride Flow - Broadcast Matching', () {
    test('requestRide creates a waiting request with no driver pre-assigned', () async {
      final docId = await rideService.requestRide(
        pickupLocation: "Kalpetta",
        pickupLat: 10.0,
        pickupLng: 76.0,
        destination: "S. Bathery",
        destinationLat: 11.0,
        destinationLng: 77.0,
        distance: 25.0,
        price: 450.0,
        vehicleType: "Car",
      );

      final doc = await fakeFirestore.collection('ride_requests').doc(docId).get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['status'], 'waiting');
      expect(doc.data()?['driverId'], isNull); // Broadcast model
    });

    test('acceptRideRequest atomically assigns driver (Transaction)', () async {
      // 1. Create a waiting ride
      final requestId = "ride_abc";
      await fakeFirestore.collection('ride_requests').doc(requestId).set({
        'status': 'waiting',
        'riderId': 'rider_789',
      });

      // 2. Create an available driver
      final driverId = mockAuth.currentUser!.uid;
      await fakeFirestore.collection('drivers').doc(driverId).set({
        'status': 'available',
        'available': true,
      });

      // 3. Driver accepts
      final success = await rideService.acceptRideRequest(requestId);
      expect(success, isTrue);

      // 4. Verify ride is now accepted by THIS driver
      final rideDoc = await fakeFirestore.collection('ride_requests').doc(requestId).get();
      expect(rideDoc.data()?['status'], 'accepted');
      expect(rideDoc.data()?['acceptedDriverId'], driverId);

      // 5. Verify driver is now busy
      final driverDoc = await fakeFirestore.collection('drivers').doc(driverId).get();
      expect(driverDoc.data()?['status'], 'busy');
      expect(driverDoc.data()?['available'], isFalse);
    });

    test('acceptRideRequest fails if ride is already accepted by another', () async {
      // 1. Create an already accepted ride
      final requestId = "ride_taken";
      await fakeFirestore.collection('ride_requests').doc(requestId).set({
        'status': 'accepted',
        'acceptedDriverId': 'other_driver',
      });

      // 2. Another driver tries to accept
      final success = await rideService.acceptRideRequest(requestId);
      expect(success, isFalse);
    });
  });

  group('Ride Flow - Timeout Logic', () {
    test('updateRideStatus to no_driver_found works', () async {
      final requestId = "ride_timeout";
      await fakeFirestore.collection('ride_requests').doc(requestId).set({
        'status': 'waiting',
      });

      await rideService.updateRideStatus(requestId, 'no_driver_found');

      final doc = await fakeFirestore.collection('ride_requests').doc(requestId).get();
      expect(doc.data()?['status'], 'no_driver_found');
    });
  });
}
