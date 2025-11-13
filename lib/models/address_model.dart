// In models/address_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String id;
  final String title;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String stateRegion;
  final String postalCode;
  final String country;
  final bool isDefault;
  final String userId;

  AddressModel({
    required this.id,
    required this.title,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.stateRegion,
    required this.postalCode,
    required this.country,
    required this.isDefault,
    required this.userId,
  });

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
      'userId': userId,
    };
  }

  // Add this fromMap method
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
      userId: data['userId'] ?? '',
    );
  }

  // Keep your existing fromSnapshot method
  factory AddressModel.fromSnapshot(

      DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
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
      userId: data['userId'] ?? '',
    );
  }
  static AddressModel empty() {
    return AddressModel(
      id: '',
      title: '',
      addressLine1: '',
      addressLine2: '',
      city: '',
      stateRegion: '',
      postalCode: '',
      country: '',
      isDefault: false,
      userId: '',
    );
  }
}