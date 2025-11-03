import 'package:abc_app/models/user_model.dart';
import 'package:abc_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- IMPORT FIREBASE AUTH
import 'package:abc_app/loginpage.dart'; // <-- IMPORT YOUR LOGIN PAGE

import 'edit_pharmacy_profile_page.dart';
import '../common/placeholder_page.dart';

class PharmacyProfilePage extends StatelessWidget {
  const PharmacyProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    // final AuthService authService = AuthService(); // <-- REMOVED THIS LINE

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<UserModel>(
        stream: firestoreService.getCurrentUserStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.uid.isEmpty) {
            return const Center(child: Text('User not found.'));
          }

          final UserModel user = snapshot.data!;
          // Use pharmacyName first, fall back to user's name
          final String displayName = (user.pharmacyName != null && user.pharmacyName!.isNotEmpty)
              ? user.pharmacyName!
              : user.name;
          final String displayEmail = user.email;
          final String profileImageUrl = user.profileImageUrl;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  // Profile Picture
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                      profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
                      child: profileImageUrl.isEmpty
                          ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name and Email
                  Text(
                    displayName,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayEmail,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),

                  // Profile Options List
                  _buildProfileOption(
                    context,
                    'Edit Profile',
                    Icons.arrow_forward_ios, // <-- Changed icon
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditPharmacyProfilePage(user: user),
                        ),
                      );
                    },
                  ),
                  _buildProfileOption(
                    context,
                    'Change Password',
                    Icons.arrow_forward_ios,
                        () {
                      // Navigate to Change Password Page
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaceholderPage(title: 'Change Password')));
                    },
                  ),
                  _buildProfileOption(
                    context,
                    'Earnings',
                    Icons.arrow_forward_ios,
                        () {
                      // Navigate to Earnings Page
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaceholderPage(title: 'Earnings')));
                    },
                  ),
                  _buildProfileOption(
                    context,
                    'Settings',
                    Icons.arrow_forward_ios,
                        () {
                      // Navigate to Settings Page
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaceholderPage(title: 'Settings')));
                    },
                  ),
                  _buildProfileOption(
                    context,
                    'Location',
                    Icons.arrow_forward_ios,
                        () {
                      // Navigate to Location Page
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaceholderPage(title: 'Location')));
                    },
                  ),
                  const SizedBox(height: 48),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        //
                        // vvvv THIS IS THE FIX vvvv
                        //
                        await FirebaseAuth.instance.signOut(); // <-- Use this instead
                        //
                        // ^^^^ THIS IS THE FIX ^^^^
                        //
                        if (context.mounted) {
                          // Navigate all the way back to the Loginpage
                          Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const Loginpage()),
                                  (route) => false // This removes all routes behind it
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileOption(
      BuildContext context, String title, IconData trailingIcon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Icon(trailingIcon, color: Colors.grey[600], size: 18), // <-- Sized icon
            ],
          ),
        ),
      ),
    );
  }
}
