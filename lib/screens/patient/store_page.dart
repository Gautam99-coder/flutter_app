import 'package:abc_app/screens/patient/medicine_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
// --- ADDED: Imports for location services ---
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _activeSortFilter = 'none'; // 'none', 'priceLowToHigh', 'priceHighToLow', 'nearest'

  // --- ADDED: State for location-based sorting ---
  List<DocumentSnapshot>? _nearestMedicines;
  bool _isLoadingLocation = false;
  Position? _currentPosition;
  // --- ADDED: Map to store distances for each medicine ---
  final Map<String, double> _medicineDistances = {};

  // This function builds the correct Firestore query for price sorting
  Stream<QuerySnapshot> _buildMedicinesStream() {
    Query query = FirebaseFirestore.instance.collection('medicines');

    // Apply sorting based on the filter
    if (_activeSortFilter == 'priceLowToHigh') {
      query = query.orderBy('price', descending: false);
    } else if (_activeSortFilter == 'priceHighToLow') {
      query = query.orderBy('price', descending: true);
    }
    // If 'none' or 'nearest', we just get the default collection
    // 'nearest' is handled by a different logic path
    return query.snapshots();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- ADDED: Function to get user's location ---
  /// Tries to get the user's current position.
  /// Handles permissions and returns the Position if successful.
  Future<Position?> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location services are disabled. Please enable them.')));
      }
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')));
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Location permissions are permanently denied, we cannot request permissions.')));
        // You might want to show a dialog to open app settings
        await openAppSettings();
      }
      return null;
    }

    // When we reach here, permissions are granted and we can
    // access the position
    try {
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      }
      return null;
    }
  }

  // --- ADDED: Function to fetch and sort medicines by distance ---
  Future<void> _fetchAndSortByNearest() async {
    setState(() {
      _isLoadingLocation = true;
      _activeSortFilter = 'nearest';
      _nearestMedicines = null; // Clear previous list
      _medicineDistances.clear(); // Clear distances
    });

    // 1. Get user's location
    _currentPosition = await _getUserLocation();

    if (_currentPosition == null) {
      // Failed to get location
      setState(() {
        _isLoadingLocation = false;
        _activeSortFilter = 'none'; // Revert filter
      });
      return;
    }

    // 2. Fetch all medicines *once*
    try {
      QuerySnapshot snapshot = await _firestore.collection('medicines').get();
      List<DocumentSnapshot> allDocs = snapshot.docs;

      // 3. Calculate distance for each
      List<Map<String, dynamic>> medicinesWithDistance = [];
      int docsWithLocationFound = 0;

      for (var doc in allDocs) {
        var data = doc.data() as Map<String, dynamic>;

        // *** IMPORTANT ASSUMPTION ***
        // This assumes you have a 'location' field in your 'medicines'
        // documents saved as a Firestore GeoPoint.
        if (data['location'] != null && data['location'] is GeoPoint) {
          GeoPoint medicineLocation = data['location'];
          double distanceInMeters = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            medicineLocation.latitude,
            medicineLocation.longitude,
          );

          medicinesWithDistance.add({
            'doc': doc,
            'distance': distanceInMeters,
          });
          // --- ADDED: Store the distance by doc ID ---
          _medicineDistances[doc.id] = distanceInMeters;
          docsWithLocationFound++;
        }
      }

      // --- ADDED: Check if any locations were found ---
      if (docsWithLocationFound == 0 && allDocs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Error: No medicines have a "location" (GeoPoint) field in the database.'),
            duration: Duration(seconds: 4),
          ));
        }
        setState(() {
          _isLoadingLocation = false;
          _activeSortFilter = 'none'; // Revert filter
        });
        return;
      }

      // 4. Sort the list by distance
      medicinesWithDistance.sort((a, b) => a['distance'].compareTo(b['distance']));

      // 5. Save the sorted list of documents to state
      setState(() {
        _nearestMedicines = medicinesWithDistance
            .map((e) => e['doc'] as DocumentSnapshot)
            .toList();
        _isLoadingLocation = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error fetching medicines: $e')));
      }
      setState(() {
        _isLoadingLocation = false;
        _activeSortFilter = 'none';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Store'),
        elevation: 1,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            _buildFilterChips(),
            _buildBannerCarousel(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
              child: Text(
                'Recommended Medicines',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            _buildMedicinesGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Material(
        color: Colors.transparent,
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search medicines or health products',
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
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: [
          // --- UPDATED: 'nearest' filter logic ---
          _buildFilterChip("Nearest Location", 'nearest'),
          _buildFilterChip("Price: Low to High", 'priceLowToHigh'),
          _buildFilterChip("Price: High to Low", 'priceHighToLow'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterKey) {
    final bool isSelected = _activeSortFilter == filterKey;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          // --- UPDATED: Handle 'nearest' filter selection ---
          if (filterKey == 'nearest') {
            if (selected) {
              _fetchAndSortByNearest(); // Call our new function
            } else {
              setState(() {
                _activeSortFilter = 'none';
                _nearestMedicines = null; // Clear the list
                _medicineDistances.clear();
              });
            }
          } else {
            // Logic for other filters (price)
            setState(() {
              if (selected) {
                _activeSortFilter = filterKey;
              } else {
                _activeSortFilter = 'none';
              }
              _nearestMedicines = null; // Clear nearest list if a price filter is chosen
              _medicineDistances.clear();
            });
          }
        },
        selectedColor: Colors.blue[100],
        checkmarkColor: Colors.blue[800],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(color: Colors.grey[300]!),
        ),
        backgroundColor: Colors.grey[50],
        elevation: 0,
      ),
    );
  }

  // --- This logic is now shared by both StreamBuilder and FutureBuilder ---
  List<DocumentSnapshot> _applySearchFilter(List<DocumentSnapshot> docs) {
    if (_searchQuery.isEmpty) {
      return docs; // No filter applied
    }

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final medicineName = data['medicineName']?.toLowerCase() ?? '';
      return medicineName.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // --- UPDATED: This widget now decides which list to show ---
  Widget _buildMedicinesGrid() {
    // --- PATH 1: Show "Nearest Location" results ---
    if (_activeSortFilter == 'nearest') {
      if (_isLoadingLocation) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Getting your location and sorting...'),
              ],
            ),
          ),
        );
      }

      if (_nearestMedicines == null) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('Select the "Nearest Location" filter to see results.'),
          ),
        );
      }

      final filteredDocs = _applySearchFilter(_nearestMedicines!);

      if (filteredDocs.isEmpty) {
        return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No medicines found nearby, or matching your search.'),
            ));
      }

      // Build the grid using the pre-sorted list
      return _buildGridView(filteredDocs);
    }

    // --- PATH 2: Show Streamed results (for 'none' or 'price') ---
    return StreamBuilder<QuerySnapshot>(
      stream: _buildMedicinesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No medicines found.'));
        }

        var allDocs = snapshot.data!.docs;
        final filteredDocs = _applySearchFilter(allDocs);

        if (filteredDocs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: Text('No medicines match your search.')),
          );
        }

        // Build the grid using the stream's data
        return _buildGridView(filteredDocs);
      },
    );
  }

  // --- ADDED: Extracted GridView builder to avoid code duplication ---
  Widget _buildGridView(List<DocumentSnapshot> documents) {
    return GridView.builder(
      itemCount: documents.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12.0,
        crossAxisSpacing: 12.0,
        childAspectRatio: 0.7, // --- ADJUSTED: Made card slightly taller for distance text
      ),
      itemBuilder: (context, index) {
        var data = documents[index].data() as Map<String, dynamic>;
        String medicineId = documents[index].id;

        String medicineName = data['medicineName'] ?? 'No Name';
        String imageUrl = data['imageUrl'] ?? '';
        String category = data['category'] ?? 'General';

        // --- ADDED: Get the distance if it exists ---
        double? distance = _medicineDistances[medicineId];

        return _buildMedicineCard(
          context,
          medicineName,
          category,
          imageUrl,
          medicineId,
          distance, // --- ADDED: Pass the distance to the card
        );
      },
    );
  }

  Widget _buildMedicineCard(
      BuildContext context,
      String name,
      String category,
      String imageUrl,
      String medicineId,
      double? distanceInMeters, // --- UPDATED: Accept distance
      ) {
    bool hasImage = imageUrl.isNotEmpty;
    String distanceText = '';

    // --- ADDED: Format the distance text ---
    if (distanceInMeters != null) {
      if (distanceInMeters < 1000) {
        distanceText = '${distanceInMeters.toStringAsFixed(0)} m away';
      } else {
        distanceText = '${(distanceInMeters / 1000).toStringAsFixed(1)} km away';
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MedicineDetailPage(medicineId: medicineId),
          ),
        );
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: Colors.grey[200]!)
        ),
        color: Colors.white,
        clipBehavior: Clip.antiAlias, // Ensures image respects border radius
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.grey[100],
                child: hasImage
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.broken_image, color: Colors.grey[400], size: 40),
                )
                    : Icon(
                  Icons.medication_liquid,
                  color: Colors.grey[300],
                  size: 50,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // --- ADDED: Show distance if it exists ---
                  if (distanceText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        distanceText,
                        style: TextStyle(fontSize: 12, color: Colors.blue[800], fontWeight: FontWeight.bold),
                        maxLines: 1,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Banner Carousel (Unchanged) ---
  Widget _buildBannerCarousel() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('ads')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: _buildDefaultBannerContent(),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Error loading ads: ${snapshot.error}');
          return _buildDefaultBanner();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildDefaultBanner();
        }

        var ads = snapshot.data!.docs;

        // Filter ads by date
        List<DocumentSnapshot> activeAds = ads.where((doc) {
          try {
            var data = doc.data() as Map<String, dynamic>;
            if (data['startDate'] == null || data['endDate'] == null) {
              return false;
            }
            Timestamp start = data['startDate'];
            Timestamp end = data['endDate'];
            DateTime now = DateTime.now();
            return now.isAfter(start.toDate()) && now.isBefore(end.toDate());
          } catch (e) {
            debugPrint('Error processing ad date: $e');
            return false;
          }
        }).toList();

        if (activeAds.isEmpty) {
          return _buildDefaultBanner();
        }

        List<DocumentSnapshot> displayAds = activeAds.take(5).toList();

        return Container(
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: CarouselSlider.builder(
            itemCount: displayAds.length,
            options: CarouselOptions(
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: true,
              viewportFraction: 0.9,
              aspectRatio: 2.0,
            ),
            itemBuilder: (context, index, realIndex) {
              try {
                var adData = displayAds[index].data() as Map<String, dynamic>;
                return _buildAdBanner(adData);
              } catch (e) {
                debugPrint('Error building ad banner: $e');
                return _buildDefaultBannerContent();
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildAdBanner(Map<String, dynamic> adData) {
    String imageUrl = adData['imageUrl'] ?? '';
    String title = adData['title'] ?? '';
    String description = adData['description'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Stack(
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultBannerContent();
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultBanner() {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: _buildDefaultBannerContent(),
    );
  }

  Widget _buildDefaultBannerContent() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[800]!, Colors.blue[600]!],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_pharmacy, color: Colors.white, size: 50),
            SizedBox(height: 8),
            Text(
              'ABC Pharmacy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Your Health, Our Priority',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}