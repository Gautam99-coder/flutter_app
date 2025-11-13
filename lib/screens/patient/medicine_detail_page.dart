// medicine_detail_page.dart
import 'package:abc_app/models/medicine_model.dart';
import 'package:abc_app/models/pharmacy_model.dart';
import 'package:abc_app/models/user_model.dart';
import 'package:abc_app/models/cart_item_model.dart'; // Add this import
import 'package:abc_app/screens/patient/checkout_page.dart';
import 'package:abc_app/screens/patient/pharmacy_detail_page.dart'; // <-- 1. IMPORT ADDED
import 'package:abc_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class MedicineDetailPage extends StatefulWidget {
  final String medicineId; // You will pass the medicine ID to this page

  const MedicineDetailPage({super.key, required this.medicineId});

  @override
  State<MedicineDetailPage> createState() => _MedicineDetailPageState();
}

class _MedicineDetailPageState extends State<MedicineDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();
  MedicineModel? _medicine;
  PharmacyModel? _pharmacy; // Changed from UserModel to PharmacyModel
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMedicineDetails();
  }

  Future<void> _fetchMedicineDetails() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch the medicine details
      MedicineModel? medicine =
      await _firestoreService.getMedicineById(widget.medicineId);

      if (medicine != null) {
        // 2. If medicine exists, fetch the pharmacy details
        PharmacyModel? pharmacy =
        await _firestoreService.getPharmacyById(medicine.pharmacyId);

        setState(() {
          _medicine = medicine;
          _pharmacy = pharmacy;
          _isLoading = false;
        });
      } else {
        // Handle case where medicine isn't found
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error fetching medicine details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load medicine details: $e')),
        );
      }
    }
  }

  // Method to handle Buy Now button press
  void _onBuyNowPressed() {
    if (_medicine != null && _pharmacy != null) {
      // Create a CartItemModel from the medicine
      CartItemModel cartItem = CartItemModel(
        medicineId: _medicine!.id!,
        medicineName: _medicine!.medicineName,
        imageUrl: _medicine!.imageUrl,
        price: _medicine!.price,
        quantity: 1, // Default quantity for Buy Now
        pharmacyId: _medicine!.pharmacyId,
        pharmacyName: _pharmacy!.name,
        id: '',
      );

      // Calculate order totals
      double subtotal = _medicine!.price.toDouble();
      double shipping = 0.0; // You can calculate shipping based on your logic
      double total = subtotal + shipping;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutPage(
            cartItems: [cartItem], // Pass as list with one item
            subtotal: subtotal,
            shipping: shipping,
            total: total,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to proceed with purchase')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Medicine Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _medicine == null
          ? const Center(child: Text('Medicine not found.'))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    // Format expiry date
    String expiryDateFormatted =
    DateFormat('dd MMMM yyyy').format(_medicine!.expiryDate.toDate());

    // Get pharmacy name from PharmacyModel
    String pharmacyName = _pharmacy?.name ?? 'Unknown Pharmacy';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medicine Image
                  Center(
                    child: Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey[100], // Placeholder color
                        borderRadius: BorderRadius.circular(12),
                        image: _medicine!.imageUrl.isNotEmpty
                            ? DecorationImage(
                          image: NetworkImage(_medicine!.imageUrl),
                          fit: BoxFit.contain,
                        )
                            : null,
                      ),
                      child: _medicine!.imageUrl.isEmpty
                          ? Icon(Icons.medication_liquid,
                          size: 100, color: Colors.grey[400])
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Medicine Name
                  Text(
                    _medicine!.medicineName,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Medicine Description
                  Text(
                    _medicine!.description,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Details: Expiry Date, Category, Pharmacy Name
                  _buildDetailRow('Expiry Date:', expiryDateFormatted,
                      Icons.calendar_today_outlined),
                  _buildDetailRow(
                      'Category:', _medicine!.category, Icons.category_outlined),
                  _buildDetailRow('Pharmacy:', pharmacyName,
                      Icons.local_pharmacy_outlined),
                  const SizedBox(height: 24),

                  // "Other Pharmacies" Section (Replaces "Nearby")
                  const Text(
                    'Other Pharmacies',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildOtherPharmaciesList(_medicine!.pharmacyId),

                  const SizedBox(height: 32),

                  // More Medicines Section
                  const Text(
                    'More Medicines',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildMoreMedicinesList(_medicine!.id!),
                ],
              ),
            ),
          ),
        ),

        // Bottom "Add to Cart" and "Buy Now" Bar
        _buildBottomActionBar(),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text(
            '$label ',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // This widget builds the "Other Pharmacies" list dynamically
  Widget _buildOtherPharmaciesList(String currentPharmacyId) {
    return StreamBuilder<List<UserModel>>(
      stream: _firestoreService.getOtherPharmacies(currentPharmacyId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: Text('Loading other pharmacies...'));
        }
        if (snapshot.data!.isEmpty) {
          return const Center(child: Text('No other pharmacies found.'));
        }

        List<UserModel> pharmacies = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pharmacies.length,
          itemBuilder: (context, index) {
            final pharmacy = pharmacies[index];
            bool hasImage = pharmacy.profileImageUrl.isNotEmpty;

            // <-- 2. WRAPPED WITH GESTUREDETECTOR -->
            return GestureDetector(
              onTap: () {
                // <-- 3. ADDED ONTAP NAVIGATION -->
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PharmacyDetailPage(pharmacyId: pharmacy.uid!),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: hasImage
                            ? NetworkImage(pharmacy.profileImageUrl)
                            : null,
                        backgroundColor: Colors.blueGrey[100],
                        child: !hasImage
                            ? const Icon(Icons.local_pharmacy,
                            size: 20, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          pharmacy.pharmacyName ?? pharmacy.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Icon(Icons.location_on_outlined,
                          color: Color(0xFF0052CC)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // This widget builds the "More Medicines" list dynamically
  Widget _buildMoreMedicinesList(String currentMedicineId) {
    return SizedBox(
      height: 200, // Fixed height for the horizontal list
      child: StreamBuilder<List<MedicineModel>>(
        stream: _firestoreService.getMoreMedicines(currentMedicineId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text('No other medicines found.'));
          }

          List<MedicineModel> similarMedicines = snapshot.data!;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: similarMedicines.length,
            itemBuilder: (context, index) {
              final similarMedicine = similarMedicines[index];
              return _buildSimilarMedicineCard(similarMedicine);
            },
          );
        },
      ),
    );
  }

  // A reusable card for the "Similar/More Medicines" list
  Widget _buildSimilarMedicineCard(MedicineModel medicine) {
    bool hasImage = medicine.imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: () {
        // Navigate to detail page of similar medicine
        Navigator.pushReplacement(
          // Use replacement to avoid stack build-up
          context,
          MaterialPageRoute(
            builder: (context) => MedicineDetailPage(medicineId: medicine.id!),
          ),
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
                  image: hasImage
                      ? DecorationImage(
                    image: NetworkImage(medicine.imageUrl),
                    fit: BoxFit.contain,
                  )
                      : null,
                ),
                child: !hasImage
                    ? Icon(Icons.medication_liquid,
                    color: Colors.grey[400], size: 40)
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.medicineName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Qty: ${medicine.quantity}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs ${medicine.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0052CC),
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // This is the bottom bar with "Add to Cart" and "Buy Now"
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16.0).copyWith(top: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                if (_medicine != null) {
                  _firestoreService.addToCart(_medicine!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                        Text('Added ${_medicine!.medicineName} to cart!')),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0052CC), // Text color
                side: const BorderSide(color: Color(0xFF0052CC)), // Border color
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add to Cart', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _onBuyNowPressed, // Use the new method
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFF0052CC), // Button background color
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Buy Now',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}