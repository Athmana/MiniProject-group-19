import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gowayanad/frontend/screens/loginscreen.dart';
import 'package:gowayanad/backend/services/auth_services.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Widget Tests - LoginScreen', () {
    testWidgets('LoginScreen renders and shows title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(LoginScreen(authService: mockAuthService)));
      
      expect(find.text('GO WAYANAD'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('Shows error when fields are empty on login', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(LoginScreen(authService: mockAuthService)));
      
      await tester.tap(find.text('LOGIN'));
      await tester.pump();
      
      expect(find.text('Please fill in all fields'), findsOneWidget);
    });
  });
}
