import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gowayanad/driver/homepage.dart';
import 'package:gowayanad/firebase_options.dart';
import 'package:gowayanad/homepage.dart';
import 'package:gowayanad/loginscreen.dart';
import 'package:gowayanad/splashscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/userHome': (context) => EmergencyRideHome(),
        '/driverHome': (context) => DriverHomePage(),
      },
    ),
  );
}

// Dummy Screens
class UserDashboard extends StatelessWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text("User Area")));
}

class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text("Driver Area")));
}
