import 'package:cloud_firestore/cloud_firestore.dart';


class MedicineModel {
  final String? id; // Document ID
  final String medicineName;
  final num price;
  final int quantity;
  final Timestamp expiryDate;
  final String description;
  final String imageUrl;
  final String pharmacyId;
  final String category;
  final bool isFeatured;
  // This 'inStock' is based on the switch, not just quantity
  final bool inStock;final double rating;
  final int reviewCount;

  MedicineModel({
    this.id,
    required this.medicineName,
    required this.price,
    required this.quantity,
    required this.expiryDate,
    required this.description,
    required this.imageUrl,
    required this.pharmacyId,
    required this.category,
    required this.isFeatured,
    required this.inStock,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  // Convert a Firestore DocumentSnapshot to a MedicineModel
  factory MedicineModel.fromMap(Map<String, dynamic> data, String documentId) {
    return MedicineModel(
      id: documentId,
      medicineName: data['medicineName'] ?? '',
      price: data['price'] ?? 0,
      quantity: data['quantity'] ?? 0,
      expiryDate: data['expiryDate'] ?? Timestamp.now(),
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      pharmacyId: data['pharmacyId'] ?? '',
      category: data['category'] ?? 'Uncategorized',
      isFeatured: data['isFeatured'] ?? false,
      inStock: data['inStock'] ?? true,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] ?? 0,
    );
  }

  // Convert a MedicineModel to a Map for uploading to Firestore
  Map<String, dynamic> toMap() {
    return {
      'medicineName': medicineName,
      'price': price,
      'quantity': quantity,
      'expiryDate': expiryDate,
      'description': description,
      'imageUrl': imageUrl,
      'pharmacyId': pharmacyId,
      'category': category,
      'isFeatured': isFeatured,
      'inStock': inStock,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }
}