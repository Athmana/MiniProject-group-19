import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
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

    String collectionName = (role == 'driver') ? 'drivers' : 'riders';

    await _firestore.collection(collectionName).doc(result.user!.uid).set({
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Sign Up with Phone and Password
  Future<void> signUpWithPhone(
    String name,
    String phone,
    String password,
    String role,
  ) async {
    // Check for existing accounts with this phone number across both collections
    final riderQuery = await _firestore
        .collection('riders')
        .where('phone', isEqualTo: phone)
        .get();
    final driverQuery = await _firestore
        .collection('drivers')
        .where('phone', isEqualTo: phone)
        .get();

    int totalExisting = riderQuery.docs.length + driverQuery.docs.length;

    if (totalExisting >= 3) {
      throw Exception("Phone number limit exceeded (Maximum 3 accounts).");
    }

    // Generate a unique pseudo-email
    int index = totalExisting + 1;
    String pseudoEmail = "${phone}_$index@gowayanad.app";

    // Create user in Firebase Auth
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: pseudoEmail,
      password: password,
    );

    String collectionName = (role == 'driver') ? 'drivers' : 'riders';

    // Save details to Firestore
    await _firestore.collection(collectionName).doc(result.user!.uid).set({
      'fullName': name,
      'name': name,
      'phone': phone,
      'phoneNumber': phone,
      'internalEmail': pseudoEmail,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Admin helper: Create user using a secondary Firebase app instance
  // to avoid signing out the current admin user.
  Future<void> signUpWithPhoneAsAdmin(
    String name,
    String phone,
    String password,
    String role,
  ) async {
    // 1. Check existing (Firestore part is fine as it doesn't affect Auth session)
    final riderQuery = await _firestore
        .collection('riders')
        .where('phone', isEqualTo: phone)
        .get();
    final driverQuery = await _firestore
        .collection('drivers')
        .where('phone', isEqualTo: phone)
        .get();

    int totalExisting = riderQuery.docs.length + driverQuery.docs.length;
    if (totalExisting >= 3) {
      throw Exception("Phone number limit exceeded (Maximum 3 accounts).");
    }

    int index = totalExisting + 1;
    String pseudoEmail = "${phone}_$index@gowayanad.app";

    // 2. Create in Auth via secondary app
    FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: 'AdminApp_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );

    try {
      FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      UserCredential result = await secondaryAuth.createUserWithEmailAndPassword(
        email: pseudoEmail,
        password: password,
      );

      String collectionName = (role == 'driver') ? 'drivers' : 'riders';

      // 3. Save to Firestore
      await _firestore.collection(collectionName).doc(result.user!.uid).set({
        'fullName': name,
        'name': name,
        'phone': phone,
        'phoneNumber': phone,
        'internalEmail': pseudoEmail,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Sign out from the secondary app instance
      await secondaryAuth.signOut();
    } finally {
      // Clean up the secondary app
      await secondaryApp.delete();
    }
  }

  // Login and Route
  Future<void> loginAndRoute(
    String identifier,
    String password,
    BuildContext context,
  ) async {
    try {
      String? loginEmail;

      // Handle phone number identifier
      bool isPhone = RegExp(r'^\+?[0-9]+$').hasMatch(identifier);
      if (isPhone) {
        // Search in both collections
        List<DocumentSnapshot> allDocs = [];
        try {
          final riderQuery = await _firestore
              .collection('riders')
              .where('phone', isEqualTo: identifier)
              .get();
          final driverQuery = await _firestore
              .collection('drivers')
              .where('phone', isEqualTo: identifier)
              .get();

          allDocs = [...riderQuery.docs, ...driverQuery.docs];
        } catch (e) {
          if (e.toString().contains('permission-denied')) {
            throw Exception(
              "Access Denied: Please check Firestore Security Rules. Ensure public read is allowed for phone lookups.",
            );
          }
          rethrow;
        }

        if (allDocs.isEmpty) {
          throw Exception("No account found for this phone number.");
        }

        // Try login for each pseudo-account
        for (var doc in allDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final email = data['internalEmail'] ?? data['email'];
          if (email != null) {
            try {
              await _auth.signInWithEmailAndPassword(
                email: email,
                password: password,
              );
              loginEmail = email;
              break;
            } catch (e) {
              continue;
            }
          }
        }

        if (loginEmail == null) {
          throw Exception("Invalid phone or password.");
        }
      } else {
        // Standard email login
        await _auth.signInWithEmailAndPassword(
          email: identifier,
          password: password,
        );
      }

      // After successful login, determine role and navigate
      User? user = _auth.currentUser;
      if (user == null) throw Exception("Auth failed.");

      String? role;
      DocumentSnapshot userDoc = await _firestore
          .collection('riders')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        role = 'rider';
      } else {
        userDoc = await _firestore.collection('drivers').doc(user.uid).get();
        if (userDoc.exists) {
          role = 'driver';
        }
      }

      if (role == null) throw Exception("User role not found.");

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

  // Logout
  Future<void> logout(BuildContext context) async {
    await _auth.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }
}
