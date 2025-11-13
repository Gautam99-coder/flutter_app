import 'dart:io';
import 'package:abc_app/models/medicine_model.dart';
import 'package:abc_app/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UpdateMedicinePage extends StatefulWidget {
  final MedicineModel medicine;
  const UpdateMedicinePage({super.key, required this.medicine});

  @override
  State<UpdateMedicinePage> createState() => _UpdateMedicinePageState();
}

class _UpdateMedicinePageState extends State<UpdateMedicinePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _expiryController;
  late TextEditingController _descController;
  late TextEditingController _categoryController;

  File? _imageFile; // This will hold the NEW image if one is picked
  DateTime? _selectedExpiryDate;
  late bool _inStock;
  late bool _isFeatured;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill all controllers with the existing medicine data
    final medicine = widget.medicine;
    _nameController = TextEditingController(text: medicine.medicineName);
    _priceController = TextEditingController(text: medicine.price.toString());
    _quantityController =
        TextEditingController(text: medicine.quantity.toString());
    _descController = TextEditingController(text: medicine.description);
    _categoryController = TextEditingController(text: medicine.category);

    _selectedExpiryDate = medicine.expiryDate.toDate();
    _expiryController = TextEditingController(
        text:
        "${_selectedExpiryDate!.day}/${_selectedExpiryDate!.month}/${_selectedExpiryDate!.year}");

    _inStock = medicine.inStock;
    _isFeatured = medicine.isFeatured;
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
      initialDate: _selectedExpiryDate ?? DateTime.now(),
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

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate() && _selectedExpiryDate != null) {
      setState(() => _isLoading = true);

      try {
        // Check if a NEW image was picked AND if it still exists
        if (_imageFile != null && !await _imageFile!.exists()) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Error: New image file not found. Please pick the image again.')),
            );
          }
          return;
        }

        MedicineModel updatedMedicine = MedicineModel(
          id: widget.medicine.id, // Keep the original ID
          medicineName: _nameController.text.trim(),
          price: num.parse(_priceController.text.trim()),
          quantity: int.parse(_quantityController.text.trim()),
          expiryDate: Timestamp.fromDate(_selectedExpiryDate!),
          description: _descController.text.trim(),
          category: _categoryController.text.trim(),
          inStock: _inStock,
          isFeatured: _isFeatured,
          imageUrl:
          widget.medicine.imageUrl, // Keep old URL (service will update it)
          pharmacyId: widget.medicine.pharmacyId, // Keep old pharmacyId
        );

        //
        // vvvv THIS IS THE FIX vvvv
        //
        // Pass BOTH arguments, 'updatedMedicine' and the '_imageFile' (which can be null)
        await _firestoreService.updateMedicine(updatedMedicine, _imageFile);
        //
        // ^^^^ THIS IS THE FIX ^^^^
        //

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine updated successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update medicine: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Stock'),
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
              // This is the image picker
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

  // This widget shows the new image (if picked) or the old one
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _imageFile != null
              ? Image.file(_imageFile!, fit: BoxFit.cover) // Show new local image
              : Image.network(widget.medicine.imageUrl,
              fit: BoxFit.cover), // Show existing network image
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
        onPressed: _isLoading ? null : _saveChanges,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Save Changes',
            style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}