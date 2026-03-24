import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gowayanad/frontend/screens/homepage.dart';
import 'package:gowayanad/frontend/screens/homescreen.dart';
import 'package:gowayanad/backend/services/ride_service.dart';
import 'package:gowayanad/backend/services/location_service.dart';
import 'package:gowayanad/backend/services/geocoding_service.dart';
import 'package:gowayanad/backend/utils/design_system.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

class MockRideService extends Mock implements RideService {}
class MockLocationService extends Mock implements LocationService {}
class MockGeocodingService extends Mock implements GeocodingService {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late MockRideService mockRideService;
  late MockLocationService mockLocationService;
  late MockGeocodingService mockGeocodingService;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late FakeFirebaseFirestore fakeFirestore;

  setUpAll(() {
    registerFallbackValue(const Offset(0.0, 0.0));
  });

  setUp(() {
    mockRideService = MockRideService();
    mockLocationService = MockLocationService();
    mockGeocodingService = MockGeocodingService();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    fakeFirestore = FakeFirebaseFirestore();

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('test_rider_id');

    // Default mock for location
    when(() => mockLocationService.getCurrentLocation()).thenAnswer(
      (_) async => Position(
        longitude: 76.0,
        latitude: 11.0,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 1.0,
        heading: 1.0,
        speed: 1.0,
        speedAccuracy: 1.0,
        altitudeAccuracy: 1.0,
        headingAccuracy: 1.0,
      ),
    );

    // Default mock for geocoding
    when(() => mockGeocodingService.placemarkFromCoordinates(any(), any()))
        .thenAnswer((_) async => [
              Placemark(
                locality: "Kalpetta",
                administrativeArea: "Kerala",
                country: "India",
              )
            ]);
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Widget Tests - Homepage & Flow', () {
    testWidgets('EmergencyRideHome renders and shows title', (WidgetTester tester) async {
      when(() => mockRideService.getRiderCompletedRides(any()))
          .thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(createTestWidget(EmergencyRideHome(
        rideService: mockRideService,
        locationService: mockLocationService,
        geocodingService: mockGeocodingService,
        firestore: fakeFirestore,
        auth: mockAuth,
      )));

      await tester.pump(const Duration(milliseconds: 500)); 

      expect(find.text('GoWayanad'), findsOneWidget);
      expect(find.text('Emergency Ride Services'), findsOneWidget);
      expect(find.byType(CustomButton), findsWidgets);
    });

    testWidgets('Tapping Request Emergency Ride navigates to Booking Screen', (WidgetTester tester) async {
      when(() => mockRideService.getRiderCompletedRides(any()))
          .thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(createTestWidget(EmergencyRideHome(
        rideService: mockRideService,
        locationService: mockLocationService,
        geocodingService: mockGeocodingService,
        firestore: fakeFirestore,
        auth: mockAuth,
      )));

      await tester.pump(const Duration(milliseconds: 500));

      final requestButton = find.byType(CustomButton);
      expect(requestButton, findsWidgets);
      
      await tester.tap(requestButton.first);
      
      // Pump multiple times to handle transition
      for(int i=0; i<10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(RiderBookingScreen), findsOneWidget);
    });
  });
}
