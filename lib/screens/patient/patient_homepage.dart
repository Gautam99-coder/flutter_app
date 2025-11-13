import 'package:abc_app/screens/common/profile_page.dart';
import 'package:abc_app/screens/patient/medicine_detail_page.dart';
import 'package:abc_app/screens/patient/notifications_page.dart';
import 'package:abc_app/screens/patient/pharmacy_detail_page.dart';
import 'package:abc_app/screens/map/map_page.dart';
import 'package:abc_app/models/ad_model.dart';
import 'package:abc_app/models/pharmacy_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:abc_app/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  // Add Firestore instance directly
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  // Function to launch phone call
  void _makeEmergencyCall() async {
    const phoneNumber = 'tel:108';
    if (await canLaunchUrl(Uri.parse(phoneNumber))) {
      await launchUrl(Uri.parse(phoneNumber));
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Error: Not logged in.")),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. The Custom App Bar (StreamBuilder)
          StreamBuilder<DocumentSnapshot>(
            stream: _firestore.collection('users').doc(uid).snapshots(),
            builder: (context, snapshot) {
              UserModel? user;
              if (snapshot.hasData && snapshot.data!.exists) {
                user = UserModel.fromMap(
                    snapshot.data!.data() as Map<String, dynamic>);
              }

              bool hasImage = (user != null && user.profileImageUrl.isNotEmpty);

              return SliverAppBar(
                backgroundColor: Colors.white,
                elevation: 1,
                pinned: true,
                leading: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                      hasImage ? NetworkImage(user!.profileImageUrl) : null,
                      child: !hasImage
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                  ),
                ),
                title: Text(
                  user?.location ?? "Set your location",
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.call_outlined, color: Colors.red),
                    onPressed: _makeEmergencyCall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.grey),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationsPage()),
                      );
                    },
                  ),
                ],
              );
            },
          ),

          // 2. The Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search Medicines',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
            ),
          ),

          // 3. The Banner Carousel (Ads & Offers)
          SliverToBoxAdapter(
            child: _buildBannerCarousel(),
          ),

          // 4. "Quick Access" Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
              child: Text(
                'Quick Access',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
            ),
          ),

          // 5. Quick Access Horizontal List (Pharmacies & Map)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .where('role', isEqualTo: 'pharmacy')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    debugPrint('Error loading pharmacies: ${snapshot.error}');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[300], size: 40),
                          const SizedBox(height: 8),
                          const Text('Error loading pharmacies'),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No pharmacies found.'));
                  }

                  var pharmacies = snapshot.data!.docs;

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    itemCount: pharmacies.length + 1, // +1 for the map card
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Map Card
                        return _buildMapCard(context);
                      } else {
                        // Pharmacy Cards
                        var pharmacyDoc = pharmacies[index - 1];
                        var pharmacyData = pharmacyDoc.data() as Map<String, dynamic>;
                        String pharmacyId = pharmacyDoc.id;
                        return _buildPharmacyCard(context, pharmacyData, pharmacyId);
                      }
                    },
                  );
                },
              ),
            ),
          ),

          // 6. "All Medicines" Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
              child: Text(
                'All Medicines',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
            ),
          ),

          // 7. Main Medicine Grid
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('medicines').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                debugPrint('Error loading medicines: ${snapshot.error}');
                return SliverToBoxAdapter(
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[300], size: 50),
                        const SizedBox(height: 8),
                        const Text('Error loading medicines'),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('No medicines found.')),
                );
              }

              var docs = snapshot.data!.docs;
              return SliverPadding(
                padding: const EdgeInsets.all(12.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12.0,
                    crossAxisSpacing: 12.0,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      String medicineId = docs[index].id;

                      return _buildMedicineCard(
                        context,
                        data['medicineName'] ?? 'No Name',
                        data['category'] ?? 'No Category',
                        data['imageUrl'] ?? '',
                        medicineId,
                      );
                    },
                    childCount: docs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Map Card Widget
  Widget _buildMapCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MapPage(),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, size: 50, color: Colors.blue[700]),
              const SizedBox(height: 12),
              const Text(
                'View Map',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Find pharmacies near you',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Pharmacy Card Widget
  Widget _buildPharmacyCard(BuildContext context, Map<String, dynamic> pharmacyData, String pharmacyId) {
    String pharmacyName = pharmacyData['pharmacyName'] ?? pharmacyData['name'] ?? 'Pharmacy';
    String profileImageUrl = pharmacyData['profileImageUrl'] ?? '';
    bool hasImage = profileImageUrl.isNotEmpty;
    bool isOpen = pharmacyData['isOpen'] ?? true;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PharmacyDetailPage(pharmacyId: pharmacyId),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              // Pharmacy Image
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  image: hasImage
                      ? DecorationImage(
                    image: NetworkImage(profileImageUrl),
                    fit: BoxFit.cover,
                  )
                      : null,
                  color: Colors.grey[100],
                ),
                child: !hasImage
                    ? const Icon(Icons.local_pharmacy, size: 40, color: Colors.grey)
                    : null,
              ),
              // Pharmacy Info
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pharmacyName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber[600], size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          '4.5',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          color: isOpen ? Colors.green : Colors.red,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOpen ? 'Open' : 'Closed',
                          style: TextStyle(
                            color: isOpen ? Colors.green : Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Banner Carousel
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
                var ad = AdModel.fromSnapshot(displayAds[index]);
                return _buildAdBanner(ad);
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

  Widget _buildAdBanner(AdModel ad) {
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
              ad.imageUrl,
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
                  if (ad.title.isNotEmpty)
                    Text(
                      ad.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (ad.description.isNotEmpty)
                    Text(
                      ad.description,
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
            const Icon(Icons.local_pharmacy, color: Colors.white, size: 50),
            const SizedBox(height: 8),
            const Text(
              'ABC Pharmacy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
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

  // Medicine Card Widget
  Widget _buildMedicineCard(
      BuildContext context,
      String name,
      String category,
      String imageUrl,
      String medicineId,
      ) {
    bool hasImage = imageUrl.isNotEmpty;

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
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: hasImage
                      ? Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
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
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                category,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}