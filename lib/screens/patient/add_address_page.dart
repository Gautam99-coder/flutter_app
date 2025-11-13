import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
// Make sure these imports are correct for your project structure
import 'package:abc_app/models/address_model.dart';
import 'package:abc_app/services/firestore_service.dart';
import '../map/map_page.dart';

class AddAddressPage extends StatefulWidget {
  const AddAddressPage({super.key});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  // --- ADDED: To store the result from MapPage ---
  LatLng? _selectedLocation;

  // Controllers for each field
  final _titleController = TextEditingController();
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final String? userId = _firestoreService.currentUserId;

        if (userId == null) {
          throw Exception('User not logged in');
        }

        // NOTE: Make sure your AddressModel class supports
        // latitude and longitude fields.
        AddressModel newAddress = AddressModel(
          id: '', // Will be set by Firestore
          title: _titleController.text.trim(),
          addressLine1: _line1Controller.text.trim(),
          addressLine2: _line2Controller.text.trim(),
          city: _cityController.text.trim(),
          stateRegion: _stateController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          country: _countryController.text.trim(),
          isDefault: false, // New addresses are not default by default
          userId: userId,
          // --- ADDED: Pass the coordinates to your model ---
          // latitude: _selectedLocation?.latitude,
          // longitude: _selectedLocation?.longitude,
        );

        // This assumes your model is updated and addAddress can handle it
        await _firestoreService.addAddress(newAddress);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address saved successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save address: $e')),
          );
        }
      }
    }
  }

  // --- ADDED: Method to navigate to MapPage ---
  void _pickLocationOnMap() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (context) => const MapPage(isSelectingLocation: true)),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
      // Optional: You could use a reverse geocoding service here
      // to automatically fill the address fields based on the coordinates.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add New Address'),
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
            children: [
              _buildTextFormField(
                _titleController,
                'Address Title (e.g., Home, Office)',
                isRequired: true,
              ),
              _buildTextFormField(
                _line1Controller,
                'Address Line 1',
                isRequired: true,
              ),
              _buildTextFormField(
                _line2Controller,
                'Address Line 2 (Optional)',
              ),
              _buildTextFormField(
                _cityController,
                'City',
                isRequired: true,
              ),
              _buildTextFormField(
                _stateController,
                'State/Region',
                isRequired: true,
              ),
              _buildTextFormField(
                _postalCodeController,
                'Postal Code',
                isRequired: true,
                keyboardType: TextInputType.number,
              ),
              _buildTextFormField(
                _countryController,
                'Country',
                isRequired: true,
              ),
              const SizedBox(height: 16),

              // --- UPDATED: Map Picker Button ---
              // This is now a more informative ListTile
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedLocation != null ? Colors.green : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedLocation != null ? Colors.green.shade50 : Colors.transparent,
                ),
                child: ListTile(
                  leading: Icon(
                    _selectedLocation != null ? Icons.check_circle : Icons.map_outlined,
                    color: _selectedLocation != null ? Colors.green : Colors.blueAccent,
                  ),
                  title: Text(
                    _selectedLocation != null ? 'Location Selected' : 'Pick Location on Map',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _selectedLocation != null ? Colors.green[800] : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    _selectedLocation != null
                        ? '${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}'
                        : 'Tap to select coordinates',
                  ),
                  onTap: _pickLocationOnMap,
                ),
              ),

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
                  onPressed: _isLoading ? null : _saveAddress,
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Save Address',
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
        bool isRequired = false,
        TextInputType? keyboardType,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Enter ${label.toLowerCase()}',
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