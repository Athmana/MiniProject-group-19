import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gowayanad/frontend/driver/homepage.dart';
import 'package:gowayanad/backend/services/ride_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockRideService extends Mock implements RideService {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late MockRideService mockRideService;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockRideService = MockRideService();
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    
    // Register fallback values for mocktail
    registerFallbackValue(const Offset(0.0, 0.0));

    // Setup default mock behaviors
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('test_driver_id');
    
    when(() => mockRideService.getBroadcastedRequests())
        .thenAnswer((_) => Stream.empty());
    when(() => mockRideService.getDriverCompletedRides(any()))
        .thenAnswer((_) => Stream.empty());
    when(() => mockRideService.updateDriverAvailability(any()))
        .thenAnswer((_) async => {});
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Widget Tests - DriverHomePage', () {
    testWidgets('DriverHomePage renders and shows Online/Offline status', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(DriverHomePage(
        rideService: mockRideService,
        firestore: fakeFirestore,
        auth: mockAuth,
      )));
      
      await tester.pumpAndSettle();
      expect(find.text('YOU ARE OFFLINE'), findsOneWidget);
    });

    testWidgets('Tapping status banner toggles status', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(DriverHomePage(
        rideService: mockRideService,
        firestore: fakeFirestore,
        auth: mockAuth,
      )));
      
      await tester.pumpAndSettle();

      // Tap the "YOU ARE OFFLINE" banner
      await tester.tap(find.text('YOU ARE OFFLINE'));
      await tester.pump();
      
      expect(find.text('YOU ARE ONLINE'), findsOneWidget);
    });
  });
}
