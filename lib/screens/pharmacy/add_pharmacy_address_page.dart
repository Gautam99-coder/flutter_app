import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:abc_app/models/pharmacy_model.dart';
import 'package:abc_app/models/user_model.dart';
import 'package:abc_app/services/firestore_service.dart';
import '../map/map_page.dart';

class AddPharmacyAddressPage extends StatefulWidget {
  final bool isEditing;
  final PharmacyModel? existingPharmacy;

  const AddPharmacyAddressPage({
    super.key,
    this.isEditing = false,
    this.existingPharmacy,
  });

  @override
  State<AddPharmacyAddressPage> createState() => _AddPharmacyAddressPageState();
}

class _AddPharmacyAddressPageState extends State<AddPharmacyAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  LatLng? _selectedLocation;

  // Controllers for each field
  final _pharmacyNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _openingHoursController = TextEditingController();
  final _servicesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.isEditing && widget.existingPharmacy != null) {
      final pharmacy = widget.existingPharmacy!;
      _pharmacyNameController.text = pharmacy.name;
      _descriptionController.text = pharmacy.description;
      _addressController.text = pharmacy.address;
      _contactNumberController.text = pharmacy.contactNumber;
      _emailController.text = pharmacy.email;
      _openingHoursController.text = pharmacy.openingHours;
      _servicesController.text = pharmacy.services.join(', ');
      _selectedLocation = LatLng(pharmacy.latitude, pharmacy.longitude);
    }
  }

  @override
  void dispose() {
    _pharmacyNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _openingHoursController.dispose();
    _servicesController.dispose();
    super.dispose();
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => const MapPage(isSelectingLocation: true),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
      if (_addressController.text.isEmpty) {
        _addressController.text =
        '${result.latitude.toStringAsFixed(6)}, ${result.longitude.toStringAsFixed(6)}';
      }
    }
  }

  Future<void> _savePharmacyAddress() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a location on the map')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final String? userId = _firestoreService.currentUserId;
        if (userId == null) {
          throw Exception('User not logged in');
        }

        // Parse services from comma-separated string
        final services = _servicesController.text
            .split(',')
            .map((service) => service.trim())
            .where((service) => service.isNotEmpty)
            .toList();

        // Create UserModel with pharmacy data - FIXED NULLABLE FIELDS
        final userModel = UserModel(
          uid: userId,
          email: _emailController.text.trim(),
          name: _pharmacyNameController.text.trim(),
          role: 'pharmacy',
          profileImageUrl: '', // Provide empty string instead of null
          bio: _descriptionController.text.trim(),
          location: _addressController.text.trim(),
          phoneNumber: _contactNumberController.text.trim(),
          pharmacyName: _pharmacyNameController.text.trim(), // Now non-nullable
          pharmacyAddress: _addressController.text.trim(), // Now non-nullable
          pharmacyContact: _contactNumberController.text.trim(), // Now non-nullable
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
          openingHours: _openingHoursController.text.trim(),
          services: services,
          isOpen: true,
          rating: 0.0, // Provide default value
          reviewCount: 0, // Provide default value
        );

        await _firestoreService.updateUser(userModel);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isEditing
                    ? 'Pharmacy updated successfully!'
                    : 'Pharmacy address saved successfully!',
              ),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save pharmacy: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Pharmacy Details' : 'Add Pharmacy Address',
        ),
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
              _buildTextFormField(
                _pharmacyNameController,
                'Pharmacy Name',
                isRequired: true,
              ),
              _buildTextFormField(
                _descriptionController,
                'Description',
                maxLines: 3,
              ),
              _buildTextFormField(
                _addressController,
                'Full Address',
                isRequired: true,
                maxLines: 2,
              ),
              _buildTextFormField(
                _contactNumberController,
                'Contact Number',
                isRequired: true,
                keyboardType: TextInputType.phone,
              ),
              _buildTextFormField(
                _emailController,
                'Email',
                isRequired: true,
                keyboardType: TextInputType.emailAddress,
              ),
              _buildTextFormField(
                _openingHoursController,
                'Opening Hours',
                hintText: 'e.g., 9:00 AM - 9:00 PM',
              ),
              _buildTextFormField(
                _servicesController,
                'Services',
                hintText: 'Comma separated services (e.g., Delivery, Consultation)',
                maxLines: 2,
              ),

              // Location Selection Section
              const SizedBox(height: 16),
              const Text(
                'Pharmacy Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select your pharmacy location on the map. Customers will see this location.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),

              // Location Selection Button
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectLocation,
                  icon: const Icon(Icons.location_on, size: 24),
                  label: const Text(
                    'Select Location on Map',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[50],
                    foregroundColor: Colors.blue[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.blue[300]!),
                    ),
                  ),
                ),
              ),

              // Selected Location Display
              if (_selectedLocation != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Location Selected ✓',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: _selectLocation,
                          tooltip: 'Change Location',
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.orange[50],
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Please select a location for your pharmacy',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _savePharmacyAddress,
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    widget.isEditing ? 'Update Pharmacy' : 'Save Pharmacy',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
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
        bool isRequired = false,
        TextInputType? keyboardType,
        int maxLines = 1,
        String? hintText,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText ?? 'Enter ${label.toLowerCase()}',
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
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