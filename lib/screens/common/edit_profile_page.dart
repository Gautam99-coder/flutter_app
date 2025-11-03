import 'dart:io';
import 'package:abc_app/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final UserModel user;
  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Updated controllers to match new UI
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  File? _imageFile; // Holds the new image picked from the gallery
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Function to pick an image
  Future<void> _pickImage() async {
    final XFile? pickedFile =
    await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Function to upload the image and save data
  Future<void> _saveProfile() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    String newImageUrl = widget.user.profileImageUrl; // Start with the old URL

    try {
      // 1. If a new image was picked, upload it
      if (_imageFile != null) {
        // Create a reference in Firebase Storage
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${widget.user.uid}.jpg');

        // Upload the file
        UploadTask uploadTask = storageRef.putFile(_imageFile!);

        // Get the download URL
        TaskSnapshot snapshot = await uploadTask;
        newImageUrl = await snapshot.ref.getDownloadURL();
      }

      // 2. Create the updated data map
      Map<String, dynamic> updatedData = {
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(), // <-- SAVES THE NUMBER AS TEXT
        'profileImageUrl': newImageUrl,
        // We DO NOT update the email here.
      };

      // 3. Update the user document in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update(updatedData);

      // 4. If successful, show snackbar and pop
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("Error saving profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine which image to show in the preview
    ImageProvider currentImage;
    if (_imageFile != null) {
      currentImage = FileImage(_imageFile!);
    } else if (widget.user.profileImageUrl.isNotEmpty) {
      currentImage = NetworkImage(widget.user.profileImageUrl);
    } else {
      currentImage = const AssetImage('assets/images/user_avatar.png');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        elevation: 1,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image Preview and Picker
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: currentImage,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    backgroundColor: Colors.blue, // Blue circle
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: _pickImage,
                    ),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: _pickImage,
              child: const Text(
                'Change Profile Photo',
                style: TextStyle(color: Color(0xFF0052CC), fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),

            // Text Fields
            _buildTextField(
                controller: _nameController,
                labelText: 'Name',
                readOnly: false),
            const SizedBox(height: 16),
            _buildTextField(
                controller: _emailController,
                labelText: 'Email',
                readOnly: true, // IMPORTANT: Email is read-only
                helperText: 'Email cannot be changed.'),
            const SizedBox(height: 16),
            _buildTextField(
                controller: _phoneController,
                labelText: 'Phone Number',
                readOnly: false,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052CC), // Blue color
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for a consistent text field style
  Widget _buildTextField(
      {required TextEditingController controller,
        required String labelText,
        required bool readOnly,
        String? helperText,
        TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        helperText: helperText,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0052CC), width: 2),
        ),
      ),
    );
  }
}
