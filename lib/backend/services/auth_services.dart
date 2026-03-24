import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Normalizes phone number to always include +91
  String _normalizePhone(String phone) {
    // Remove all non-numeric characters
    String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    
    // If it's 10 digits, assume India (+91)
    if (digits.length == 10) {
      String fullNumber = "+91$digits"; // Corrected `digitsOnly` to `digits`
      return fullNumber; // Added return statement to maintain original logic
    }
    
    // If it's already 12 digits starting with 91, just add the +
    if (digits.length == 12 && digits.startsWith('91')) {
      return '+$digits';
    }
    
    // If it already has a +, just return cleaned version
    if (phone.startsWith('+')) {
      return '+${phone.replaceAll(RegExp(r'[^0-9]'), '')}';
    }

    // Fallback: prepend + if missing
    return phone.startsWith('+') ? phone : '+$digits';
  }

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

  Future<void> signUpWithPhone(
    String name,
    String phone,
    String password,
    String role, {
    String? vehicleType,
  }) async {
    final normalizedPhone = _normalizePhone(phone);
    
    // Check for existing accounts with this phone number across both collections
    final riderQuery = await _firestore
        .collection('riders')
        .where('phone', isEqualTo: normalizedPhone)
        .get();
    final driverQuery = await _firestore
        .collection('drivers')
        .where('phone', isEqualTo: normalizedPhone)
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
    Map<String, dynamic> userData = {
      'fullName': name,
      'name': name,
      'phone': normalizedPhone,
      'phoneNumber': normalizedPhone,
      'internalEmail': pseudoEmail,
      'role': role,
      'available': false, // Ensure field exists
      'rating': 0.0,
      'totalRides': 0,
      'createdAt': FieldValue.serverTimestamp(),
      // ignore: use_null_aware_elements
      if (vehicleType != null) 'vehicleType': vehicleType,
    };

    await _firestore.collection(collectionName).doc(result.user!.uid).set(userData);
  }

  // Admin helper: Create user using a secondary Firebase app instance
  // to avoid signing out the current admin user.
  Future<void> signUpWithPhoneAsAdmin(
    String name,
    String phone,
    String password,
    String role, {
    String? vehicleType,
  }) async {
    final normalizedPhone = _normalizePhone(phone);

    // 1. Check existing (Firestore part is fine as it doesn't affect Auth session)
    final riderQuery = await _firestore
        .collection('riders')
        .where('phone', isEqualTo: normalizedPhone)
        .get();
    final driverQuery = await _firestore
        .collection('drivers')
        .where('phone', isEqualTo: normalizedPhone)
        .get();

    int totalExisting = riderQuery.docs.length + driverQuery.docs.length;
    if (totalExisting >= 10) { // Increased for testing
      throw Exception("Phone number limit exceeded (Maximum 10 accounts).");
    }

    int index = totalExisting + 1;
    String cleanPhone = normalizedPhone.replaceAll('+', '');
    String pseudoEmail = "${cleanPhone}_$index@gowayanad.app";

    // 2. Create in Auth via secondary app
    // We use a fixed name and don't delete to avoid "FirebaseApp was deleted" errors
    const String adminAppName = 'gowayanad_admin';
    FirebaseApp secondaryApp;
    try {
      secondaryApp = Firebase.app(adminAppName);
    } catch (_) {
      secondaryApp = await Firebase.initializeApp(
        name: adminAppName,
        options: Firebase.app().options,
      );
    }

    try {
      FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      UserCredential result = await secondaryAuth.createUserWithEmailAndPassword(
        email: pseudoEmail,
        password: password,
      );

      String collectionName = (role == 'driver' ? 'drivers' : 'riders');

      // 3. Save to Firestore using the SECONDARY app instance
      // This works because the secondary app is authenticated as the new user
      FirebaseFirestore secondaryFirestore = FirebaseFirestore.instanceFor(app: secondaryApp);

      Map<String, dynamic> userData = {
        'fullName': name,
        'name': name,
        'phone': normalizedPhone,
        'phoneNumber': normalizedPhone,
        'internalEmail': pseudoEmail,
        'role': role,
        'available': false, // Ensure field exists
        'rating': 0.0,
        'totalRides': 0,
        'createdAt': FieldValue.serverTimestamp(),
        // ignore: use_null_aware_elements
        if (vehicleType != null) 'vehicleType': vehicleType,
      };

      await secondaryFirestore.collection(collectionName).doc(result.user!.uid).set(userData);
      
      // Sign out from the secondary app instance so it's clean for the next use
      await secondaryAuth.signOut();
    } catch (e) {
      rethrow;
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
        final normalizedPhone = _normalizePhone(identifier);
        
        // Search in both collections
        List<DocumentSnapshot> allDocs = [];
        try {
          final riderQuery = await _firestore
              .collection('riders')
              .where('phone', isEqualTo: normalizedPhone)
              .get();
          final driverQuery = await _firestore
              .collection('drivers')
              .where('phone', isEqualTo: normalizedPhone)
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
