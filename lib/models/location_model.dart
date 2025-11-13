// models/location_model.dart
class LocationPoint {
  final double latitude;
  final double longitude;
  final String address;
  final String title;
  final String? id;
  final String? userId;
  final String? pharmacyId;
  final DateTime? createdAt;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.title,
    this.id,
    this.userId,
    this.pharmacyId,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'title': title,
      'userId': userId,
      'pharmacyId': pharmacyId,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  factory LocationPoint.fromMap(Map<String, dynamic> data, String id) {
    return LocationPoint(
      id: id,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      address: data['address'] ?? '',
      title: data['title'] ?? '',
      userId: data['userId'],
      pharmacyId: data['pharmacyId'],
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : null,
    );
  }
}