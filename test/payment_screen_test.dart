import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gowayanad/frontend/screens/paymentscreen.dart';
import 'package:gowayanad/backend/services/ride_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

class MockRideService extends Mock implements RideService {}

void main() {
  late MockRideService mockRideService;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  const String testRideId = 'test_ride_123';

  setUp(() {
    mockRideService = MockRideService();
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth(signedIn: true);
    
    // Seed initial data
    fakeFirestore.collection('ride_requests').doc(testRideId).set({
      'fareAmount': 250.0,
      'status': 'reached_destination',
    });
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Widget Tests - PaymentScreen', () {
    testWidgets('PaymentScreen renders and shows amount from Firestore', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(PaymentScreen(
        rideId: testRideId,
        rideService: mockRideService,
        firestore: fakeFirestore,
        auth: mockAuth,
      )));

      await tester.pump(); // Let StreamBuilder fire

      expect(find.text('Select Payment Method'), findsOneWidget);
      expect(find.text('₹250.0'), findsOneWidget);
      expect(find.text('PAY NOW'), findsOneWidget);
    });

    testWidgets('Tapping a payment method selects it', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(PaymentScreen(
        rideId: testRideId,
        rideService: mockRideService,
        firestore: fakeFirestore,
        auth: mockAuth,
      )));

      await tester.pump();

      // Tap Cash
      await tester.tap(find.text('Cash on Arrival'));
      await tester.pump();

      // Verify selection (the tile with "Cash" should now have the check_circle icon)
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
