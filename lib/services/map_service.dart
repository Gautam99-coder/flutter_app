// services/map_service.dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:abc_app/models/location_model.dart';

class MapService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save user location
  Future<void> saveUserLocation(LocationPoint location) async {
    await _db.collection('user_locations').add(location.toMap());
  }

  // Save pharmacy location
  Future<void> savePharmacyLocation(LocationPoint location) async {
    await _db.collection('pharmacy_locations').add(location.toMap());
  }

  // Get all pharmacy locations
  Stream<List<LocationPoint>> getPharmacyLocations() {
    return _db.collection('pharmacy_locations').snapshots().map(
            (snapshot) => snapshot.docs.map(
                (doc) => LocationPoint.fromMap(doc.data(), doc.id)
        ).toList()
    );
  }

  // Get nearby pharmacies (simple radius calculation)
  Stream<List<LocationPoint>> getNearbyPharmacies(double lat, double lng, double radiusInKm) {
    return _db.collection('pharmacy_locations').snapshots().map(
            (snapshot) {
          return snapshot.docs.map((doc) => LocationPoint.fromMap(doc.data(), doc.id))
              .where((pharmacy) {
            double distance = _calculateDistance(
                lat, lng,
                pharmacy.latitude, pharmacy.longitude
            );
            return distance <= radiusInKm;
          })
              .toList();
        }
    );
  }

  // Haversine formula to calculate distance between two points
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat/2) * sin(dLat/2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
            sin(dLon/2) * sin(dLon/2);

    double c = 2 * atan2(sqrt(a), sqrt(1-a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }
}