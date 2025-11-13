import 'dart:io';
import 'package:abc_app/models/medicine_model.dart';
import 'package:abc_app/models/medicine_template_model.dart';
import 'package:abc_app/services/firestore_service.dart';
import 'package:abc_app/services/medicine_data_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'medicine_picker_page.dart';

class AddMedicinePage extends StatefulWidget {
  const AddMedicinePage({super.key});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final MedicineDataService _medicineDataService = MedicineDataService();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  File? _imageFile;
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

  // New method to open medicine picker
  Future<void> _openMedicinePicker() async {
    final MedicineTemplateModel? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MedicinePickerPage()),
    );

    if (result != null && mounted) {
      // Pre-fill the form with selected medicine data
      setState(() {
        _nameController.text = result.name;
        _categoryController.text = result.category;
        _descController.text = result.description;

        // Set default values for other fields
        if (_priceController.text.isEmpty) {
          _priceController.text = '0';
        }
        if (_quantityController.text.isEmpty) {
          _quantityController.text = '1';
        }
      });
    }
  }

  Future<void> _saveMedicine() async {
    if (_formKey.currentState!.validate() &&
        _imageFile != null &&
        _selectedExpiryDate != null) {
      setState(() => _isLoading = true);

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
          imageUrl: '',
          pharmacyId: '',
        );

        await _firestoreService.addMedicine(newMedicine, _imageFile!);

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
              // Medicine Picker Button
              _buildMedicinePickerButton(),
              const SizedBox(height: 16),

              // Image Picker
              _buildImagePicker(),
              const SizedBox(height: 24),

              // Form Fields
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

  // New widget for medicine picker button
  Widget _buildMedicinePickerButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _openMedicinePicker,
        icon: const Icon(Icons.medical_services),
        label: const Text('Pick from Medicine Database'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

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