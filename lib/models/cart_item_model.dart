import 'package:cloud_firestore/cloud_firestore.dart';

class CartItemModel {
  final String id; // This is the cart document ID
  final String medicineId; // This is the original medicine ID
  final String pharmacyId; // The ID of the pharmacy selling this
  final String pharmacyName; // The name of the pharmacy
  final String medicineName;
  final String imageUrl;
  final num price;
  int quantity;

  CartItemModel({
    required this.id,
    required this.medicineId,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.medicineName,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });

  // From Firestore DocumentSnapshot (when reading from cart stream)
  factory CartItemModel.fromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CartItemModel(
      id: doc.id,
      medicineId: data['medicineId'] ?? '',
      pharmacyId: data['pharmacyId'] ?? '',
      pharmacyName: data['pharmacyName'] ?? '',
      medicineName: data['medicineName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      price: data['price'] ?? 0,
      quantity: data['quantity'] ?? 0,
    );
  }

  // From a plain Map (used when reading from an Order)
  factory CartItemModel.fromMap(Map<String, dynamic> data) {
    return CartItemModel(
      id: data['id'] ?? '',
      medicineId: data['medicineId'] ?? '',
      pharmacyId: data['pharmacyId'] ?? '',
      pharmacyName: data['pharmacyName'] ?? '',
      medicineName: data['medicineName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      price: data['price'] ?? 0,
      quantity: data['quantity'] ?? 0,
    );
  }

  // To Firestore document
  Map<String, dynamic> toMap() {
    return {
      'medicineId': medicineId,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'medicineName': medicineName,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
    };
  }
}