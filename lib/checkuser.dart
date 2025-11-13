import 'package:abc_app/screens/splash_screen.dart';
import 'package:abc_app/widgets/bottom_navbar.dart';
import 'package:abc_app/widgets/pharmacy_bottom_navbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// This widget is the new "home" for your app.
/// It only listens for the authentication state (logged in vs. logged out).
class Checkuser extends StatelessWidget {
  const Checkuser({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While checking auth state, show a loading circle
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If a user is logged in (snapshot has data)
        if (snapshot.hasData) {
          // Go to the RoleBasedRedirector to figure out *which* dashboard to show
          return const RoleBasedRedirector();
        }

        // If no user is logged in
        // Send them to the SplashScreen (which will likely lead to Login)
        return const SplashScreen();
      },
    );
  }
}


/// This widget's only job is to check the user's role *after*
/// we already know they are logged in.
class RoleBasedRedirector extends StatelessWidget {
  const RoleBasedRedirector({super.key});

  Future<String?> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null; // Should not happen if Checkuser is working

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        return userDoc.data()?['role']; // Returns 'patient' or 'pharmacy'
      } else {
        // Handle case where user is authenticated but has no 'users' document
        print("User document does not exist for UID: ${user.uid}");
        return null; // Or return 'patient' as a default
      }
    } catch (e) {
      print("Error fetching user role: $e");
      return null; // On error, treat as logged out
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        // While fetching the role
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If we have the role data
        if (snapshot.hasData && snapshot.data != null) {
          final role = snapshot.data;
          if (role == 'pharmacy') {
            return const PharmacyBottomNavbar();
          } else {
            // Default to patient dashboard
            return const BottomNavbar();
          }
        }

        // If something went wrong (error, no data, no user doc)
        // Send them back to the splash screen to be safe.
        // You could also log them out here.
        // E.g., FirebaseAuth.instance.signOut();
        return const SplashScreen();
      },
    );
  }
}