import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gowayanad/driver/homepage.dart';
import 'package:gowayanad/firebase_options.dart';
import 'package:gowayanad/homepage.dart';
import 'package:gowayanad/auth_screen.dart';
import 'package:gowayanad/welcomescreen.dart';

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
        '/userHome': (context) => EmergencyRideHome(),
        '/driverHome': (context) => DriverHomePage(),
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
          // User is logged in, grab their role
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
                String role = roleSnapshot.data!.get('role') ?? 'rider';
                if (role == 'driver') {
                  return const DriverHomePage();
                } else {
                  return const EmergencyRideHome();
                }
              }

              // Fallback if document doesn't exist
              return const EmergencyRideHome();
            },
          );
        }

        // User is NOT logged in
        return const WelcomeScreen();
      },
    );
  }
}
