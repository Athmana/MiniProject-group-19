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

  group('RideService - Pure Logic', () {
    test('calculateFare returns correct amount for 5km Auto', () {
      final fare = RideService.calculateFare(5.0, 'Auto');
      // 50 (base) + 5*12 (distance) = 110
      expect(fare, 110.0);
    });

    test('calculateFare returns correct amount for 10km Car', () {
      final fare = RideService.calculateFare(10.0, 'Car');
      // 100 (base) + 10*18 (distance) = 280
      expect(fare, 280.0);
    });

    test('calculateDistance returns 0 for same coordinates', () {
      final distance = rideService.calculateDistance(10.0, 10.0, 10.0, 10.0);
      expect(distance, 0.0);
    });
  });

  group('RideService - Firestore Interactions', () {
    test('requestRide creates a ride_request document', () async {
      final docId = await rideService.requestRide(
        pickupLocation: "Test pickup",
        pickupLat: 10.0,
        pickupLng: 76.0,
        destination: "Test destination",
        destinationLat: 11.0,
        destinationLng: 77.0,
        distance: 10.0,
        price: 200.0,
        vehicleType: "Car",
      );
      
      expect(docId, isNotNull);
      final doc = await fakeFirestore.collection('ride_requests').doc(docId).get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['status'], 'waiting');
    });
  });
}
