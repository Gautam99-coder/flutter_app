// services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:abc_app/models/pharmacy_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current location with permission handling
  Future<LatLng?> getCurrentLocation() async {
    try {
      final status = await Permission.location.request();

      if (status.isGranted) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        return LatLng(position.latitude, position.longitude);
      } else {
        throw Exception('Location permission denied');
      }
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Get nearby pharmacies with distance calculation
  Stream<List<PharmacyModel>> getNearbyPharmacies(LatLng userLocation, double radiusInKm) {
    return _firestore
        .collection('pharmacies')
        .snapshots()
        .map((snapshot) {
      List<PharmacyModel> pharmacies = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final pharmacy = PharmacyModel.fromMap(data, doc.id);

        // Calculate distance
        final distance = _calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          pharmacy.latitude,
          pharmacy.longitude,
        );

        // Return only pharmacies within the radius
        if (distance <= radiusInKm) {
          // Create a new pharmacy with distance info
          final nearbyPharmacy = PharmacyModel(
            id: pharmacy.id,
            name: pharmacy.name,
            description: pharmacy.description,
            address: pharmacy.address,
            contactNumber: pharmacy.contactNumber,
            email: pharmacy.email,
            latitude: pharmacy.latitude,
            longitude: pharmacy.longitude,
            profileImageUrl: pharmacy.profileImageUrl,
            rating: pharmacy.rating,
            reviewCount: pharmacy.reviewCount,
            isOpen: pharmacy.isOpen,
            openingHours: pharmacy.openingHours,
            services: pharmacy.services,
          );
          pharmacies.add(nearbyPharmacy);
        }
      }

      // Sort by distance
      pharmacies.sort((a, b) {
        final distanceA = _calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          a.latitude,
          a.longitude,
        );
        final distanceB = _calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          b.latitude,
          b.longitude,
        );
        return distanceA.compareTo(distanceB);
      });

      return pharmacies;
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distance in km
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  // Helper method to calculate distance for a specific pharmacy
  double calculateDistanceToPharmacy(LatLng userLocation, PharmacyModel pharmacy) {
    return _calculateDistance(
      userLocation.latitude,
      userLocation.longitude,
      pharmacy.latitude,
      pharmacy.longitude,
    );
  }
}