import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign Up with Role
  Future<void> signUp(String email, String password, String role) async {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    
    // Save role to Firestore
    await _firestore.collection('users').doc(result.user!.uid).set({
      'email': email,
      'role': role, // 'user' or 'driver'
    });
  }

  // Login and Route
  Future<void> loginAndRoute(String email, String password, BuildContext context) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
          print("Tried login");

      // Fetch user role from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get();

      String role = userDoc['role'];

      if (role == 'driver') {
        print("reached here");
        Navigator.pushReplacementNamed(context, '/driverHome');
      } else {
        Navigator.pushReplacementNamed(context, '/userHome');
      }
    } catch (e) {
      print("Login Error: $e");
    }
  }
}