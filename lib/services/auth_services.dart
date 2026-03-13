import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign Up with Role (Email/Password)
  Future<void> signUp(String email, String password, String role) async {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Determine collection name
    String collectionName = (role == 'driver') ? 'drivers' : 'riders';

    // Save role and details to the specific collection
    await _firestore.collection(collectionName).doc(result.user!.uid).set({
      'email': email,
      'role': role, // 'rider' or 'driver'
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Sign Up with Phone and Password (Used by Admin Panel CSV Upload)
  Future<void> signUpWithPhone(
    String name,
    String phone,
    String password,
    String role,
  ) async {
    // Generate a pseudo-email for Firebase Auth since it requires an email for password login
    String pseudoEmail = "$phone@gowayanad.app";

    // Create user in Firebase Auth
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: pseudoEmail,
      password: password,
    );

    // Determine collection name
    String collectionName = (role == 'driver') ? 'drivers' : 'riders';

    // Save role and details to the specific collection
    await _firestore.collection(collectionName).doc(result.user!.uid).set({
      'name': name,
      'phone': phone,
      'password':
          password, // Storing plain text password as requested (Note: Not secure for production)
      'role': role, // 'rider' or 'driver'
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Login and Route
  Future<void> loginAndRoute(
    String identifier, // Can be email or phone
    String password,
    BuildContext context,
  ) async {
    try {
      // Determine if identifier is a phone number (just numbers, or numbers with '+')
      bool isProbablyPhone = RegExp(r'^\+?[0-9]+$').hasMatch(identifier);
      String loginEmail = isProbablyPhone
          ? "$identifier@gowayanad.app"
          : identifier;

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );

      debugPrint("Tried login with $loginEmail");

      // Fetch user role from Firestore by checking both collections
      String? role;
      DocumentSnapshot userDoc =
          await _firestore.collection('riders').doc(result.user!.uid).get();

      if (userDoc.exists) {
        role = 'rider';
      } else {
        userDoc =
            await _firestore.collection('drivers').doc(result.user!.uid).get();
        if (userDoc.exists) {
          role = 'driver';
        }
      }

      if (role == null) {
        throw Exception("User data not found in either riders or drivers collection.");
      }

      if (context.mounted) {
        if (role == 'driver') {
          Navigator.pushReplacementNamed(context, '/driverHome');
        } else {
          Navigator.pushReplacementNamed(context, '/riderHome');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed: ${e.toString()}')),
        );
      }
    }
  }
}
