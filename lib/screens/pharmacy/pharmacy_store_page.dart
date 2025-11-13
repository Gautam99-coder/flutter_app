import 'package:abc_app/screens/pharmacy/update_medicine_page.dart';
import 'package:flutter/material.dart';
import 'package:abc_app/models/medicine_model.dart';
import 'package:abc_app/services/firestore_service.dart';
import 'package:abc_app/screens/pharmacy/add_medicine_page.dart';

class PharmacyStorePage extends StatefulWidget {
  const PharmacyStorePage({super.key});

  @override
  State<PharmacyStorePage> createState() => _PharmacyStorePageState();
}

class _PharmacyStorePageState extends State<PharmacyStorePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  // Main categories from the UI image
  final List<String> _mainCategories = [
    'Painkillers',
    'Antibiotics',
    'Vitamins',
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background as per image
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header matching the image
            _buildHeader(),

            // Search Bar
            _buildSearchBar(),

            // Main Content
            Expanded(
              child: StreamBuilder<List<MedicineModel>>(
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

                  // If searching, show grid. If not, show Category Layout
                  if (_searchQuery.isNotEmpty) {
                    return _buildSearchResultsGrid(snapshot.data!);
                  } else {
                    return _buildCategoryLayout(snapshot.data!);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Header Section ---
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'All Medicines',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddMedicinePage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A5F), // Dark Blue
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Add Medicine',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search medicines...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // --- Main Layouts ---

  // 1. The "Image Style" Layout (Categories)
  Widget _buildCategoryLayout(List<MedicineModel> allMedicines) {
    // --- THIS IS THE FIX ---
    // Create a list of category widgets
    List<Widget> categoryWidgets = [];

    // 1. Add widgets for all MAIN categories
    for (String category in _mainCategories) {
      List<MedicineModel> categoryMedicines = allMedicines
          .where((m) => m.category.toLowerCase() == category.toLowerCase())
          .toList();

      if (categoryMedicines.isNotEmpty) {
        categoryWidgets.add(_buildCategorySection(category, categoryMedicines));
      }
    }

    // 2. Find all medicines that are NOT in the main categories
    List<MedicineModel> otherMedicines = allMedicines.where((m) {
      return !_mainCategories
          .any((c) => c.toLowerCase() == m.category.toLowerCase());
    }).toList();

    // 3. Add a final "Other" section if it has any medicines
    if (otherMedicines.isNotEmpty) {
      categoryWidgets
          .add(_buildCategorySection("Other Medicines", otherMedicines));
    }
    // --- END OF FIX ---

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: categoryWidgets, // Display the dynamically built list
    );
  }

  // Helper widget to build one category section (e.g., "Painkillers" + list)
  Widget _buildCategorySection(
      String title, List<MedicineModel> medicines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Title Row
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),

        // Horizontal List of Cards
        SizedBox(
          height: 260, // Height for the horizontal scroll area
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: medicines.length,
            itemBuilder: (context, index) {
              return _buildHorizontalMedicineCard(medicines[index]);
            },
          ),
        ),

        // View All Button
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "View All",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        )
      ],
    );
  }

  // 2. The Search Results Layout (Grid)
  Widget _buildSearchResultsGrid(List<MedicineModel> allMedicines) {
    final results = allMedicines
        .where((medicine) =>
    medicine.medicineName.toLowerCase().contains(_searchQuery) ||
        medicine.category.toLowerCase().contains(_searchQuery))
        .toList();

    if (results.isEmpty) return _buildNoResultsState();

    // This is your old GridView, used for search results.
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7, // Adjusted for more space
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return _buildGridMedicineCard(results[index]);
      },
    );
  }

  // --- Card Widgets ---

  // Card style for the horizontal "Category" layout
  Widget _buildHorizontalMedicineCard(MedicineModel medicine) {
    return Container(
      width: 160, // Fixed width for horizontal items
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () => _navigateToUpdatePage(medicine),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Container
            Container(
              height: 160,
              width: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: _getPastelColor(medicine.category), // Color by category
                image: medicine.imageUrl.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(medicine.imageUrl),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: medicine.imageUrl.isEmpty
                  ? const Center(
                  child: Icon(Icons.medical_services_outlined,
                      color: Colors.white, size: 40))
                  : null,
            ),
            const SizedBox(height: 12),
            // Medicine Name
            Text(
              medicine.medicineName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Subtitle (Price and dosage/desc)
            Text(
              '₹${medicine.price.toStringAsFixed(0)} • ${medicine.description.isNotEmpty ? medicine.description : medicine.category}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blueGrey[400],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Card style for the "Search" GridView
  Widget _buildGridMedicineCard(MedicineModel medicine) {
    return InkWell(
      onTap: () => _navigateToUpdatePage(medicine),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _getPastelColor(medicine.category),
                image: medicine.imageUrl.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(medicine.imageUrl),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: medicine.imageUrl.isEmpty
                  ? const Center(
                  child: Icon(Icons.medical_services_outlined,
                      color: Colors.white, size: 40))
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            medicine.medicineName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '₹${medicine.price.toStringAsFixed(0)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  // --- Helper Functions ---

  Color _getPastelColor(String category) {
    final colors = [
      const Color(0xFFB2DFDB), // Teal-ish (Ibuprofen)
      const Color(0xFFFFCCBC), // Orange-ish (Acetaminophen)
      const Color(0xFFFFE0B2), // Yellow-ish (Naproxen)
      const Color(0xFFD1C4E9), // Purple-ish
      const Color(0xFFF0F4C3), // Lime-ish
    ];
    // Pick a color based on the category hash
    return colors[category.length % colors.length];
  }

  void _navigateToUpdatePage(MedicineModel medicine) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateMedicinePage(medicine: medicine),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No medicines added yet',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Tap "Add Medicine" to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No medicines found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}