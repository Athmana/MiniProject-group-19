import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gowayanad/frontend/screens/homepage.dart';
import 'package:gowayanad/frontend/screens/homescreen.dart';
import 'package:gowayanad/frontend/screens/paymentscreen.dart';
import 'package:gowayanad/frontend/screens/ridecompleted.dart';
import 'package:gowayanad/backend/services/ride_service.dart';
import 'package:gowayanad/backend/services/location_service.dart';
import 'package:gowayanad/backend/services/geocoding_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;

class MockLocationService extends Mock implements LocationService {}
class MockGeocodingService extends Mock implements GeocodingService {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockLocationService mockLocationService;
  late MockGeocodingService mockGeocodingService;
  late RideService rideService;

  setUpAll(() {
    registerFallbackValue(const Offset(0.0, 0.0));
  });

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth(signedIn: true);
    mockLocationService = MockLocationService();
    mockGeocodingService = MockGeocodingService();
    rideService = RideService(firestore: fakeFirestore, auth: mockAuth);

    when(() => mockLocationService.getCurrentLocation()).thenAnswer(
      (_) async => Position(longitude: 76.08, latitude: 11.60, timestamp: DateTime.now(), accuracy: 1.0, altitude: 1.0, heading: 1.0, speed: 1.0, speedAccuracy: 1.0, altitudeAccuracy: 1.0, headingAccuracy: 1.0),
    );

    when(() => mockGeocodingService.placemarkFromCoordinates(any(), any()))
        .thenAnswer((_) async => [geo.Placemark(locality: "Kalpetta", administrativeArea: "Kerala", country: "India")]);
    
    when(() => mockGeocodingService.locationFromAddress(any()))
        .thenAnswer((_) async => [geo.Location(latitude: 11.65, longitude: 76.10, timestamp: DateTime.now())]);
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(home: child);
  }

  group('E2E Integration Flow', () {
    testWidgets('Step 1: Dashboard and Navigation to Booking', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(EmergencyRideHome(
        rideService: rideService, locationService: mockLocationService,
        geocodingService: mockGeocodingService, firestore: fakeFirestore, auth: mockAuth,
      )));

      await tester.pumpAndSettle();
      expect(find.text("GoWayanad"), findsOneWidget);

      await tester.tap(find.text("Request Emergency Ride"));
      await tester.pumpAndSettle();
      expect(find.byType(RiderBookingScreen), findsOneWidget);
    });

    testWidgets('Step 2: Ride Request Creation', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(RiderBookingScreen(
        rideService: rideService, locationService: mockLocationService,
        geocodingService: mockGeocodingService, firestore: fakeFirestore, auth: mockAuth,
      )));

      // 1. Wait for location to finish loading
      await tester.pump(const Duration(seconds: 2)); // Increased wait time
      await tester.pumpAndSettle();
      
      // 2. Enter Destination
      await tester.enterText(find.byType(TextField), "Sulthan Bathery");
      
      // 3. Wait for Debounce (1.5s) and Fare Calculation (async)
      await tester.pump(const Duration(seconds: 4)); // Increased wait time
      await tester.pumpAndSettle();

      // 4. Select 'Car'
      await tester.ensureVisible(find.text("Car").first);
      await tester.pumpAndSettle();
      await tester.tap(find.text("Car").first);
      await tester.pumpAndSettle();

      // 5. Confirm
      await tester.ensureVisible(find.text("Confirm Booking"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Confirm Booking"));
      // Use pump() instead of pumpAndSettle() to avoid timeout from WaitingForDriverScreen animations
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final requests = await fakeFirestore.collection('ride_requests').get();
      expect(requests.docs.length, 1);
    });

    testWidgets('Step 3: Payment and Completion Journey', (WidgetTester tester) async {
      final String riderId = mockAuth.currentUser!.uid;
      final String rideId = "integration_ride";
      await fakeFirestore.collection('ride_requests').doc(rideId).set({
        'riderId': riderId,
        'status': 'reached_destination',
        'fareAmount': 250.0,
        'paymentStatus': 'pending',
        'destinationLocation': 'Sulthan Bathery',
        'vehicleType': 'Car',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      await tester.pumpWidget(createTestWidget(PaymentScreen(
        rideId: rideId, rideService: rideService,
        firestore: fakeFirestore, auth: mockAuth,
      )));
      await tester.pumpAndSettle();

      expect(find.text("₹250.0"), findsOneWidget);
      
      // Select Cash to keep it simple
      await tester.tap(find.text("Cash on Arrival"));
      await tester.pumpAndSettle();

      await tester.tap(find.text("PAY NOW"));
      
      // Process payment delay (2s in code)
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byType(RideCompletedScreen), findsOneWidget);
      
      // Verify Recent Activity on Home
      await tester.pumpWidget(createTestWidget(EmergencyRideHome(
        rideService: rideService, locationService: mockLocationService,
        geocodingService: mockGeocodingService, firestore: fakeFirestore, auth: mockAuth,
      )));
      // Wait for stream to update and settle (give it plenty of time in fake environment)
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Scroll down to see recent activity - use the ScrollView directly
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text("Sulthan Bathery", skipOffstage: false), findsWidgets);
      // Use contains to match formatted text like ₹250.0
      expect(find.textContaining("250", skipOffstage: false), findsWidgets);
    });
  });
}
