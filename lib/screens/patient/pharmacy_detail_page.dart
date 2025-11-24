// screens/patient/pharmacy_detail_page.dart
import 'package:abc_app/models/pharmacy_model.dart';
import 'package:abc_app/models/medicine_model.dart';
import 'package:abc_app/screens/patient/medicine_detail_page.dart';
// import 'package:abc_app/screens/patient/pharmacy_map_page.dart'; // REMOVED
import 'package:abc_app/screens/map/map_page.dart'; // ADDED
import 'package:abc_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart' as latlong; // ADDED

class PharmacyDetailPage extends StatefulWidget {
  final String pharmacyId;

  const PharmacyDetailPage({super.key, required this.pharmacyId});

  @override
  State<PharmacyDetailPage> createState() => _PharmacyDetailPageState();
}

class _PharmacyDetailPageState extends State<PharmacyDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();
  // Using a Stream to keep the pharmacy details (including rating) updated
  Stream<PharmacyModel?>? _pharmacyStream;
  List<MedicineModel> _medicines = [];
  bool _isLoadingMedicines = true; // Use a separate loading flag for medicines

  @override
  void initState() {
    super.initState();
    // Start listening to the stream for pharmacy details (including live rating)
    _pharmacyStream = _firestoreService.getPharmacyStreamById(widget.pharmacyId);
    _fetchMedicines();
  }

  Future<void> _fetchMedicines() async {
    setState(() => _isLoadingMedicines = true);
    try {
      // Load medicines for this pharmacy (using a listen/setState approach for simplicity)
      _firestoreService.getPharmacyMedicines(widget.pharmacyId).listen((medicines) {
        if(mounted) {
          setState(() {
            _medicines = medicines;
            _isLoadingMedicines = false;
          });
        }
      });
    } catch (e) {
      if(mounted) {
        setState(() => _isLoadingMedicines = false);
      }
      print('Error fetching pharmacy medicines: $e');
    }
  }

  void _callPharmacy(PharmacyModel pharmacy) async {
    if (pharmacy.contactNumber.isNotEmpty) {
      final phoneNumber = 'tel:${pharmacy.contactNumber}';
      if (await canLaunchUrl(Uri.parse(phoneNumber))) {
        await launchUrl(Uri.parse(phoneNumber));
      }
    }
  }

  void _openMap(PharmacyModel pharmacy) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPage(
          locationToFocus: latlong.LatLng(
            pharmacy.latitude,
            pharmacy.longitude,
          ),
        ),
      ),
    );
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
          'Pharmacy Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<PharmacyModel?>(
        stream: _pharmacyStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final pharmacy = snapshot.data;
          if (pharmacy == null) {
            return const Center(child: Text('Pharmacy not found.'));
          }

          return _buildContent(pharmacy);
        },
      ),
    );
  }

  Widget _buildContent(PharmacyModel pharmacy) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pharmacy Header
          _buildPharmacyHeader(pharmacy),

          // Action Buttons
          _buildActionButtons(pharmacy),

          // Pharmacy Info
          _buildPharmacyInfo(pharmacy),

          // Services
          _buildServicesSection(pharmacy),

          // Medicines List
          _buildMedicinesSection(),
        ],
      ),
    );
  }

  Widget _buildPharmacyHeader(PharmacyModel pharmacy) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        image: pharmacy.profileImageUrl.isNotEmpty
            ? DecorationImage(
          image: NetworkImage(pharmacy.profileImageUrl),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: pharmacy.profileImageUrl.isEmpty
          ? const Icon(Icons.local_pharmacy, size: 80, color: Colors.grey)
          : null,
    );
  }

  Widget _buildActionButtons(PharmacyModel pharmacy) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _callPharmacy(pharmacy),
              icon: const Icon(Icons.call),
              label: const Text('Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _openMap(pharmacy),
              icon: const Icon(Icons.map),
              label: const Text('View Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyInfo(PharmacyModel pharmacy) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pharmacy.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                // This value is now live-updated via the StreamBuilder
                pharmacy.rating.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(' (${pharmacy.reviewCount} reviews)'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: pharmacy.isOpen ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pharmacy.isOpen ? 'OPEN' : 'CLOSED',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, pharmacy.address),
          _buildInfoRow(Icons.access_time, pharmacy.openingHours),
          _buildInfoRow(Icons.phone, pharmacy.contactNumber),
          _buildInfoRow(Icons.email, pharmacy.email),
          const SizedBox(height: 16),
          Text(
            pharmacy.description,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(PharmacyModel pharmacy) {
    if (pharmacy.services.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Services',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pharmacy.services.map((service) {
              return Chip(
                label: Text(service),
                backgroundColor: Colors.blue[50],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicinesSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Medicines',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _isLoadingMedicines
              ? const Center(child: CircularProgressIndicator())
              : _medicines.isEmpty
              ? const Center(child: Text('No medicines available'))
              : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12.0,
              crossAxisSpacing: 12.0,
              childAspectRatio: 0.75,
            ),
            itemCount: _medicines.length,
            itemBuilder: (context, index) {
              final medicine = _medicines[index];
              return _buildMedicineCard(medicine);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(MedicineModel medicine) {
    bool hasImage = medicine.imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MedicineDetailPage(medicineId: medicine.id!),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: hasImage
                      ? Image.network(
                    medicine.imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error, color: Colors.red),
                  )
                      : Icon(
                    Icons.medication_liquid,
                    color: Colors.grey[300],
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                medicine.medicineName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Rs ${medicine.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0052CC),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
