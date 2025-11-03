import 'dart:io';
import 'package:abc_app/models/medicine_model.dart';
import 'package:abc_app/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Make sure you have this package

class AddMedicinePage extends StatefulWidget {
  const AddMedicinePage({super.key});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  File? _imageFile; // This variable will hold your selected image
  DateTime? _selectedExpiryDate;
  bool _inStock = true;
  bool _isFeatured = false;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickExpiryDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedExpiryDate = pickedDate;
        _expiryController.text =
        "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }

  Future<void> _saveMedicine() async {
    // Check includes validation for the image file
    if (_formKey.currentState!.validate() &&
        _imageFile != null &&
        _selectedExpiryDate != null) {
      setState(() => _isLoading = true);

      // Check if file still exists (this prevents a crash)
      if (!await _imageFile!.exists()) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Error: Image file not found. Please pick the image again.')),
          );
        }
        return;
      }

      try {
        MedicineModel newMedicine = MedicineModel(
          medicineName: _nameController.text.trim(),
          price: num.parse(_priceController.text.trim()),
          quantity: int.parse(_quantityController.text.trim()),
          expiryDate: Timestamp.fromDate(_selectedExpiryDate!),
          description: _descController.text.trim(),
          category: _categoryController.text.trim(),
          inStock: _inStock,
          isFeatured: _isFeatured,
          imageUrl: '', // This will be set by the FirestoreService
          pharmacyId: '', // This will be set by the FirestoreService
        );

        //
        // vvvv THIS IS THE FIX vvvv
        //
        // Pass BOTH arguments to the function, as expected
        await _firestoreService.addMedicine(newMedicine, _imageFile!);
        //
        // ^^^^ THIS IS THE FIX ^^^V
        //

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine added successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add medicine: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields and upload an image.')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _expiryController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Stock'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // This is the image picker widget
              _buildImagePicker(),
              const SizedBox(height: 24),
              _buildTextFormField(_nameController, 'Medicine Name'),
              _buildTextFormField(_priceController, 'Price (₹)',
                  keyboardType: TextInputType.number),
              _buildTextFormField(_quantityController, 'Quantity Available',
                  keyboardType: TextInputType.number),
              _buildTextFormField(
                  _categoryController, 'Category (e.g., Pain Relief)'),
              _buildTextFormField(
                _expiryController,
                'Expiry Date',
                readOnly: true,
                onTap: _pickExpiryDate,
                suffixIcon: Icons.calendar_today,
              ),
              _buildTextFormField(_descController, 'Description', maxLines: 4),
              _buildSwitchRow(
                  'In Stock', _inStock, (value) => setState(() => _inStock = value)),
              _buildSwitchRow('Feature this item?', _isFeatured,
                      (value) => setState(() => _isFeatured = value)),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // Widget to show the selected image (or a prompt to upload)
  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border:
          Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
        ),
        child: _imageFile != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(_imageFile!, fit: BoxFit.cover),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Upload Medicine Image',
                style: TextStyle(fontSize: 16)),
            const Text('Tap to upload',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: _pickImage, child: const Text('Upload')),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField(
      TextEditingController controller,
      String label, {
        TextInputType? keyboardType,
        int maxLines = 1,
        bool readOnly = false,
        VoidCallback? onTap,
        IconData? suffixIcon,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSwitchRow(
      String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue[800],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[800],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isLoading ? null : _saveMedicine,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Save Changes',
            style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}
