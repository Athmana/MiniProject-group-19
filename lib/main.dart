import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gowayanad/driver/homepage.dart';
import 'package:gowayanad/firebase_options.dart';
import 'package:gowayanad/homepage.dart';
import 'package:gowayanad/auth_screen.dart';
import 'package:gowayanad/welcomescreen.dart';
import 'package:gowayanad/homescreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const AuthScreen(isLogin: true),
        '/signup': (context) => const AuthScreen(isLogin: false),
        '/riderHome': (context) => const EmergencyRideHome(),
        '/riderBooking': (context) => const RiderBookingScreen(),
        '/driverHome': (context) => const DriverHomePage(),
      },
    ),
  );
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in, grab their role by checking riders then drivers
          return FutureBuilder<String?>(
            future: () async {
              DocumentSnapshot riderDoc = await FirebaseFirestore.instance
                  .collection('riders')
                  .doc(snapshot.data!.uid)
                  .get();
              if (riderDoc.exists) return 'rider';

              DocumentSnapshot driverDoc = await FirebaseFirestore.instance
                  .collection('drivers')
                  .doc(snapshot.data!.uid)
                  .get();
              if (driverDoc.exists) return 'driver';

              return null;
            }(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (roleSnapshot.hasData) {
                String role = roleSnapshot.data!;
                if (role == 'driver') {
                  return const DriverHomePage();
                } else {
                  return const EmergencyRideHome();
                }
              }

              // Fallback if document doesn't exist (e.g., deleted from Firestore but auth remains)
              return const WelcomeScreen();
            },
          );
        }

        // User is NOT logged in
        return const WelcomeScreen();
      },
    );
  }
}
