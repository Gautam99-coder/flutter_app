import 'package:abc_app/models/medicine_model.dart';
import 'package:abc_app/models/user_model.dart';
import 'package:abc_app/screens/pharmacy/add_medicine_page.dart';
import 'package:abc_app/screens/pharmacy/pharmacy_profile_page.dart';
import 'package:abc_app/screens/pharmacy/update_medicine_page.dart';
import 'package:abc_app/screens/settings_screen.dart';
import 'package:abc_app/services/firestore_service.dart';
import 'package:flutter/material.dart';

import '../common/profile_page.dart';
import 'add_ad_page.dart';

class PharmacyHomepage extends StatefulWidget {
  const PharmacyHomepage({super.key});

  @override
  State<PharmacyHomepage> createState() => _PharmacyHomepageState();
}

class _PharmacyHomepageState extends State<PharmacyHomepage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setFilter(String filterKey) {
    setState(() {
      if (_activeFilter == filterKey) {
        _activeFilter = 'all';
      } else {
        _activeFilter = filterKey;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel>(
      stream: _firestoreService.getCurrentUserStream(),
      builder: (context, userSnapshot) {
        Widget leadingAvatar;
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          leadingAvatar = const CircleAvatar(backgroundColor: Colors.transparent);
        } else if (userSnapshot.hasData &&
            userSnapshot.data!.profileImageUrl.isNotEmpty) {
          leadingAvatar = CircleAvatar(
            backgroundImage: NetworkImage(userSnapshot.data!.profileImageUrl),
          );
        } else {
          leadingAvatar = CircleAvatar(
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.person, color: Colors.grey),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            title: const Text('MediCare Pharmacy',
                style: TextStyle(color: Colors.black)),
            leading: Padding(
              padding: const EdgeInsets.all(10.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>  PharmacyProfilePage()),
                  );
                },
                child: leadingAvatar,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.black),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>SettingsScreen()));
                },
              ),
            ],
          ),
          body: StreamBuilder<List<MedicineModel>>(
            // FIXED: Use getCurrentPharmacyMedicines() instead of getPharmacyMedicines()
            stream: _firestoreService.getCurrentPharmacyMedicines(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              final allMedicines = snapshot.data!;
              int inStockCount = allMedicines.where((m) => m.quantity > 30).length;
              int lowStockCount = allMedicines
                  .where((m) => m.quantity > 0 && m.quantity <= 30)
                  .length;
              int outOfStockCount = allMedicines.where((m) => m.quantity == 0).length;

              List<MedicineModel> filteredByStock;
              if (_activeFilter == 'inStock') {
                filteredByStock = allMedicines.where((m) => m.quantity > 30).toList();
              } else if (_activeFilter == 'lowStock') {
                filteredByStock = allMedicines.where((m) => m.quantity > 0 && m.quantity <= 30).toList();
              } else if (_activeFilter == 'outOfStock') {
                filteredByStock = allMedicines.where((m) => m.quantity == 0).toList();
              } else {
                filteredByStock = allMedicines;
              }

              final filteredMedicines = filteredByStock.where((m) {
                return m.medicineName.toLowerCase().contains(_searchQuery);
              }).toList();

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(inStockCount, lowStockCount, outOfStockCount),
                  ),
                  SliverToBoxAdapter(
                    child: _buildSearchAndAdd(),
                  ),
                  SliverToBoxAdapter(
                    child: _buildInventoryTitle(),
                  ),
                  _buildInventoryList(filteredMedicines),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Your inventory is empty.', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Medicine'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddMedicinePage()),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildHeader(int inStock, int lowStock, int outOfStock) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard(
                'In Stock', inStock.toString(), const Color(0xFF4DD0E1),
                filterKey: 'inStock',
                onTap: () => _setFilter('inStock'),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Low Stock', lowStock.toString(), const Color(0xFF4DD0E1),
                filterKey: 'lowStock',
                onTap: () => _setFilter('lowStock'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Out of Stock', outOfStock.toString(), const Color(0xFF4DD0E1),
            isFullWidth: true,
            filterKey: 'outOfStock',
            onTap: () => _setFilter('outOfStock'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color,
      {bool isFullWidth = false, required String filterKey, required VoidCallback onTap}) {

    final bool isSelected = _activeFilter == filterKey;
    final bool isFaded = _activeFilter != 'all' && !isSelected;

    Widget cardContent = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isFaded ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: Colors.blue.shade900, width: 3)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            Text(count,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );

    Widget clickableCard = GestureDetector(
      onTap: onTap,
      child: cardContent,
    );

    return isFullWidth ? clickableCard : Expanded(child: clickableCard);
  }

  Widget _buildSearchAndAdd() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search medicines...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddMedicinePage()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddAdPage()),
                );
              },
              child: const Text('Post Ad/Offer',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Inventory',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (_activeFilter != 'all')
            TextButton(
              onPressed: () => _setFilter('all'),
              child: const Text('Show All'),
            )
        ],
      ),
    );
  }

  Widget _buildInventoryList(List<MedicineModel> medicines) {
    if (medicines.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('No medicines found for this filter.', style: TextStyle(fontSize: 16)),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final medicine = medicines[index];
          return _buildInventoryItem(medicine);
        },
        childCount: medicines.length,
      ),
    );
  }

  Widget _buildInventoryItem(MedicineModel medicine) {
    String stockStatus;
    Color stockColor;
    if (medicine.quantity == 0) {
      stockStatus = 'Out of Stock';
      stockColor = Colors.red;
    } else if (medicine.quantity <= 30) {
      stockStatus = 'Low Stock';
      stockColor = Colors.orange;
    } else {
      stockStatus = 'In Stock';
      stockColor = Colors.green;
    }

    bool hasImage = medicine.imageUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  // FIXED: Replace withOpacity with withOpacity from Color
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stockStatus,
                          style: TextStyle(
                              color: stockColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      Text(medicine.medicineName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        '${medicine.category} • ${medicine.description.length > 20 ? medicine.description.substring(0, 20) : medicine.description}...',
                        style:
                        TextStyle(color: Colors.grey[600], fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹ ${medicine.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800]),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.edit, size: 14, color: Colors.grey[600]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: hasImage
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      medicine.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) =>
                      const Icon(Icons.error, color: Colors.red),
                    ),
                  )
                      : const Icon(
                    Icons.medication_liquid,
                    color: Colors.grey,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildActionButton(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UpdateMedicinePage(medicine: medicine),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          onPressed: () => _showDeleteDialog(medicine.id!),
                        ),
                      ],
                    ),
                    Text('Quantity: ${medicine.quantity}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 48, maxWidth: 48),
                      child: _buildQuantityButton(
                        icon: Icons.remove,
                        onPressed: medicine.quantity == 0
                            ? null
                            : () {
                          _firestoreService.updateMedicineQuantity(
                              medicine.id!, medicine.quantity - 1);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        medicine.quantity.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 48, maxWidth: 48),
                      child: _buildQuantityButton(
                        icon: Icons.add,
                        onPressed: () {
                          _firestoreService.updateMedicineQuantity(
                              medicine.id!, medicine.quantity + 1);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(
      {required IconData icon, VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: onPressed == null ? Colors.grey[200] : Colors.blue[50],
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 18,
            color: onPressed == null ? Colors.grey[400] : Colors.blue[800]),
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
        required String label,
        required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(String medicineId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: const Text(
            'Are you sure you want to delete this item from your inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _firestoreService.deleteMedicine(medicineId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}