import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String? id; // Document ID
  final String title; // e.g., "Home", "Office"
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String stateRegion;
  final String postalCode;
  final String country;
  final bool isDefault;

  AddressModel({
    this.id,
    required this.title,
    required this.addressLine1,
    this.addressLine2 = '',
    required this.city,
    required this.stateRegion,
    required this.postalCode,
    required this.country,
    this.isDefault = false,
  });

  // From Firestore DocumentSnapshot (for addresses collection)
  factory AddressModel.fromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AddressModel(
      id: doc.id,
      title: data['title'] ?? '',
      addressLine1: data['addressLine1'] ?? '',
      addressLine2: data['addressLine2'] ?? '',
      city: data['city'] ?? '',
      stateRegion: data['stateRegion'] ?? '',
      postalCode: data['postalCode'] ?? '',
      country: data['country'] ?? '',
      isDefault: data['isDefault'] ?? false,
    );
  }

  // From Map<String, dynamic> (for embedded objects like in orders)
  factory AddressModel.fromMap(Map<String, dynamic> data) {
    return AddressModel(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      addressLine1: data['addressLine1'] ?? '',
      addressLine2: data['addressLine2'] ?? '',
      city: data['city'] ?? '',
      stateRegion: data['stateRegion'] ?? '',
      postalCode: data['postalCode'] ?? '',
      country: data['country'] ?? '',
      isDefault: data['isDefault'] ?? false,
    );
  }

  // To Firestore document
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'stateRegion': stateRegion,
      'postalCode': postalCode,
      'country': country,
      'isDefault': isDefault,
    };
  }
}
