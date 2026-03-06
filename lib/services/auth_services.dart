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

    // Save role to Firestore
    await _firestore.collection('users').doc(result.user!.uid).set({
      'email': email,
      'role': role, // 'user' or 'driver'
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

    // Check if user already exists (optional, createUserWithEmailAndPassword handles it)
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: pseudoEmail,
      password: password,
    );

    // Save role and details to Firestore
    await _firestore.collection('users').doc(result.user!.uid).set({
      'name': name,
      'phone': phone,
      'password':
          password, // Storing plain text password as requested (Note: Not secure for production)
      'role': role, // 'rider' or 'driver'
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


      print("Tried login with $loginEmail");


      // Fetch user role from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get();

      String role = userDoc['role'];

      if (context.mounted) {
        if (role == 'driver') {
          Navigator.pushReplacementNamed(context, '/driverHome');
        } else {
          Navigator.pushReplacementNamed(context, '/userHome');
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
