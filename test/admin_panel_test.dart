import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gowayanad/frontend/admin/admin_panel.dart';
import 'package:gowayanad/backend/services/auth_services.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    mockAuthService = MockAuthService();
    fakeFirestore = FakeFirebaseFirestore();
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Widget Tests - Admin Panel', () {
    testWidgets('AdminPanel renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(AdminPanel(
        authService: mockAuthService,
        firestore: fakeFirestore,
      )));

      expect(find.text('Admin Panel'), findsOneWidget);
      expect(find.text('Riders'), findsOneWidget);
      expect(find.text('Drivers'), findsOneWidget);
    });

    testWidgets('Tapping Add shows New Rider/Driver dialog', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(AdminPanel(
        authService: mockAuthService,
        firestore: fakeFirestore,
      )));

      // Find the manual add button (it has icon person_add_rounded)
      final addButton = find.byIcon(Icons.person_add_rounded);
      await tester.tap(addButton);
      await tester.pump();

      expect(find.text('Add New Rider'), findsOneWidget);
    });
  });
}
