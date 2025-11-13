class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String profileImageUrl;
  final String bio;
  final String location;
  final String phoneNumber;
  final String? pharmacyName;
  final String? pharmacyAddress;
  final String? pharmacyContact;
  final double? latitude; // Add this
  final double? longitude; // Add this
  final double? rating; // Add this
  final int? reviewCount; // Add this
  final bool? isOpen; // Add this
  final String? openingHours; // Add this
  final List<String>? services; // Add this

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.profileImageUrl = '',
    this.bio = '',
    this.location = '',
    this.phoneNumber = '',
    this.pharmacyName,
    this.pharmacyAddress,
    this.pharmacyContact,
    this.latitude, // Add this
    this.longitude, // Add this
    this.rating, // Add this
    this.reviewCount, // Add this
    this.isOpen, // Add this
    this.openingHours, // Add this
    this.services, // Add this
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      bio: data['bio'] ?? '',
      location: data['location'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      pharmacyName: data['pharmacyName'],
      pharmacyAddress: data['pharmacyAddress'],
      pharmacyContact: data['pharmacyContact'],
      latitude: (data['latitude'] ?? 0.0).toDouble(), // Add this
      longitude: (data['longitude'] ?? 0.0).toDouble(), // Add this
      rating: (data['rating'] ?? 0.0).toDouble(), // Add this
      reviewCount: (data['reviewCount'] ?? 0).toInt(), // Add this
      isOpen: data['isOpen'] ?? true, // Add this
      openingHours: data['openingHours'] ?? '9:00 AM - 9:00 PM', // Add this
      services: List<String>.from(data['services'] ?? []), // Add this
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'location': location,
      'phoneNumber': phoneNumber,
      'pharmacyName': pharmacyName,
      'pharmacyAddress': pharmacyAddress,
      'pharmacyContact': pharmacyContact,
      'latitude': latitude, // Add this
      'longitude': longitude, // Add this
      'rating': rating, // Add this
      'reviewCount': reviewCount, // Add this
      'isOpen': isOpen, // Add this
      'openingHours': openingHours, // Add this
      'services': services, // Add this
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? profileImageUrl,
    String? bio,
    String? location,
    String? phoneNumber,
    String? pharmacyName,
    String? pharmacyAddress,
    String? pharmacyContact,
    double? latitude, // Add this
    double? longitude, // Add this
    double? rating, // Add this
    int? reviewCount, // Add this
    bool? isOpen, // Add this
    String? openingHours, // Add this
    List<String>? services, // Add this
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      pharmacyAddress: pharmacyAddress ?? this.pharmacyAddress,
      pharmacyContact: pharmacyContact ?? this.pharmacyContact,
      latitude: latitude ?? this.latitude, // Add this
      longitude: longitude ?? this.longitude, // Add this
      rating: rating ?? this.rating, // Add this
      reviewCount: reviewCount ?? this.reviewCount, // Add this
      isOpen: isOpen ?? this.isOpen, // Add this
      openingHours: openingHours ?? this.openingHours, // Add this
      services: services ?? this.services, // Add this
    );
  }
}