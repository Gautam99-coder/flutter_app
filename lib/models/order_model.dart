import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:abc_app/models/address_model.dart';
import 'cart_item_model.dart';

class OrderModel {
  final String? id;
  final String userId;
  final String pharmacyId;
  final String pharmacyName;
  final List<CartItemModel> items;
  final AddressModel shippingAddress;
  final double subtotal;
  final double shipping;
  final double total;
  final String paymentMethod;
  final String status;
  final Timestamp createdAt;
  final String? cancellationReason;

  OrderModel({
    this.id,
    required this.userId,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.items,
    required this.shippingAddress,
    required this.subtotal,
    required this.shipping,
    required this.total,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.cancellationReason,
  });

  // To Firestore document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'items': items.map((item) => item.toMap()).toList(),
      'shippingAddress': shippingAddress.toMap(),
      'subtotal': subtotal,
      'shipping': shipping,
      'total': total,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': createdAt,
      'cancellationReason': cancellationReason,
    };
  }

  /// Create from Firestore DocumentSnapshot
  factory OrderModel.fromSnapshot(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return OrderModel.fromMapData(data, doc.id);
  }

  /// Create from raw Map + document id
  factory OrderModel.fromMapData(Map<String, dynamic> data, String id) {
    return OrderModel(
      id: id,
      userId: data['userId'] ?? '',
      pharmacyId: data['pharmacyId'] ?? '',
      pharmacyName: data['pharmacyName'] ?? '',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((itemData) => CartItemModel.fromMap(itemData))
          .toList(),

      // FIXED: Added a null check here to prevent crashes
      shippingAddress: data['shippingAddress'] != null
          ? AddressModel.fromMap(data['shippingAddress'])
          : AddressModel.empty(), // Assumes you have an .empty() constructor

      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      shipping: (data['shipping'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['paymentMethod'] ?? '',
      status: data['status'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      cancellationReason: data['cancellationReason'],
    );
  }
}
