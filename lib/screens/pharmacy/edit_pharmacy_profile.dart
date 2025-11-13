import 'dart:io';
import 'package:abc_app/models/user_model.dart';
import 'package:abc_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditPharmacyProfilePage extends StatefulWidget {
  final UserModel user;
  const EditPharmacyProfilePage({super.key, required this.user});

  @override
  State<EditPharmacyProfilePage> createState() => _EditPharmacyProfilePageState();
}

class _EditPharmacyProfilePageState extends State<EditPharmacyProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _pharmacyNameController;
  late TextEditingController _pharmacyAddressController;
  late TextEditingController _pharmacyContactController;

  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneNumberController = TextEditingController(text: widget.user.phoneNumber);
    _pharmacyNameController = TextEditingController(text: widget.user.pharmacyName);
    _pharmacyAddressController = TextEditingController(text: widget.user.pharmacyAddress);
    _pharmacyContactController = TextEditingController(text: widget.user.pharmacyContact);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _pharmacyNameController.dispose();
    _pharmacyAddressController.dispose();
    _pharmacyContactController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String? newImageUrl;
        if (_imageFile != null) {
          // If a new image is picked, upload it
          // This method now exists in your service
          newImageUrl = await _firestoreService.uploadProfileImage(_imageFile!);
        }

        UserModel updatedUser = widget.user.copyWith(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(), // Note: changing email in Firestore doesn't change it in Auth
          phoneNumber: _phoneNumberController.text.trim(),
          pharmacyName: _pharmacyNameController.text.trim(),
          pharmacyAddress: _pharmacyAddressController.text.trim(),
          pharmacyContact: _pharmacyContactController.text.trim(),
          profileImageUrl: newImageUrl ?? widget.user.profileImageUrl, // Use new URL or existing
        );

        // This method now exists in your service
        await _firestoreService.updateUser(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          Navigator.pop(context); // Go back to profile page
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    // Profile Image
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (widget.user.profileImageUrl.isNotEmpty
                          ? NetworkImage(widget.user.profileImageUrl)
                          : null) as ImageProvider?,
                      child: _imageFile == null && widget.user.profileImageUrl.isEmpty
                          ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                          : null,
                    ),
                    const SizedBox(height: 12),
                    // User Name
                    Text(
                      _pharmacyNameController.text.isNotEmpty ? _pharmacyNameController.text : (widget.user.name.isNotEmpty ? widget.user.name : 'Your Name'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    // Change Profile Photo button
                    GestureDetector(
                      onTap: _pickImage,
                      child: const Text(
                        'Change Profile Photo',
                        style: TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Personal Information Section
              Text(
                'Personal Information',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800]),
              ),
              const SizedBox(height: 16),
              _buildTextFormField(_nameController, 'Your Name', isRequired: true),
              _buildTextFormField(_emailController, 'Your Email',
                  keyboardType: TextInputType.emailAddress, isRequired: true,
                  readOnly: true, // <-- ADDED: Prevents changing email
                  helperText: "Email cannot be changed." // <-- ADDED
              ),
              _buildTextFormField(_phoneNumberController, 'Your Phone Number',
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 32),

              // Pharmacy Information Section
              Text(
                'Pharmacy Information',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800]),
              ),
              const SizedBox(height: 16),
              _buildTextFormField(_pharmacyNameController, 'Pharmacy Name',
                  isRequired: true),
              _buildTextFormField(_pharmacyAddressController, 'Pharmacy Address',
                  maxLines: 2),
              _buildTextFormField(_pharmacyContactController, 'Pharmacy Contact (for customers)',
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 48),

              // Save Changes Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(
      TextEditingController controller,
      String label, {
        TextInputType? keyboardType,
        int maxLines = 1,
        bool isRequired = false,
        bool readOnly = false,
        String? helperText,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          filled: true,
          fillColor: readOnly ? Colors.grey[200] : Colors.grey[100], // Grey out if read-only
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}
