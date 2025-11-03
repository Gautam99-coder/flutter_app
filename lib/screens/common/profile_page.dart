import 'package:abc_app/models/user_model.dart';
import 'package:abc_app/screens/patient/add_address_page.dart';
import 'package:abc_app/screens/patient/my_orders_page.dart';
import 'package:abc_app/screens/patient/saved_addresses_page.dart';
import 'package:abc_app/services/firestore_service.dart'; // <-- Import new service
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:abc_app/loginpage.dart';
import 'edit_profile_page.dart'; // <-- This is the patient's edit page
import '../common/placeholder_page.dart'; // <-- Placeholder for other buttons

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  // Create an instance of your new service
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaceholderPage(title: 'Settings')));
            },
          ),
        ],
      ),
      // Use the new service to get the user data stream
      body: StreamBuilder<UserModel>(
        stream: _firestoreService.getCurrentUserStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.uid.isEmpty) {
            return const Center(child: Text("Could not load profile."));
          }

          // We get the UserModel directly from the stream
          UserModel user = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header Section
                      _buildHeader(context, user), // <-- Pass the user
                      const SizedBox(height: 20),

                      // List Options
                      _buildProfileOptionRow(
                        context,
                        icon: Icons.edit,
                        title: 'Edit Profile',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfilePage(user: user),
                            ),
                          );
                        },
                      ),
                      _buildProfileOptionRow(
                        context,
                        icon: Icons.shopping_bag_outlined,
                        title: 'My Orders',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const MyOrdersPage()));
                        },
                      ),
                      _buildProfileOptionRow(
                        context,
                        icon: Icons.location_on_outlined,
                        title: 'New Addresses',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddAddressPage()));
                        },
                      ),
                      _buildProfileOptionRow(
                        context,
                        icon: Icons.location_on_outlined,
                        title: 'Saved Addresses',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedAddressesPage()));
                        },
                      ),
                      _buildProfileOptionRow(
                        context,
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaceholderPage(title: 'Change Password')));
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Logout Button (Stays at the bottom)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0052CC), // Blue color
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Loginpage()),
                              (route) => false,
                        );
                      }
                    },
                    child: const Text(
                      'Logout',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Header Widget
  Widget _buildHeader(BuildContext context, UserModel user) {
    bool hasImage = user.profileImageUrl.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      color: const Color(0xFFE6F0FF), // Light blue background
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white, // Background for the icon
            backgroundImage:
            hasImage ? NetworkImage(user.profileImageUrl) : null,
            child: !hasImage
                ? Icon(
              Icons.person,
              size: 60,
              color: Colors.grey[400],
            )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            user.name.isEmpty ? "User" : user.name,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: const TextStyle(fontSize: 16, color: Color(0xFF0052CC)),
          ),
          const SizedBox(height: 4),
          Text(
            user.phoneNumber.isEmpty
                ? "Add your phone number" // Updated placeholder
                : user.phoneNumber,
            style: const TextStyle(fontSize: 16, color: Color(0xFF0052CC)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0052CC),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(user: user),
                ),
              );
            },
            child: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  // List Option Row Widget
  Widget _buildProfileOptionRow(BuildContext context,
      {required IconData icon,
        required String title,
        required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
