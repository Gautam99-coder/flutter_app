import 'dart:io';
import 'package:abc_app/models/address_model.dart';
import 'package:abc_app/models/cart_model.dart';
import 'package:abc_app/models/medicine_model.dart';
import 'package:abc_app/models/notification_model.dart';
import 'package:abc_app/models/order_model.dart';
import 'package:abc_app/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final CloudinaryPublic _cloudinary = CloudinaryPublic(
      'dfqqs04rn', // Your Cloud Name
      'ml_default', // Your Upload Preset
      cache: false
  );

  String? get currentUserId => _auth.currentUser?.uid;

  // --- User Functions ---
  Stream<UserModel> getCurrentUserStream() {
    final String? uid = currentUserId;
    if (uid == null) {
      return Stream.value(UserModel(
          uid: '', email: '', name: '', role: '',
          bio: '', location: '', phoneNumber: '',
          pharmacyName: '', pharmacyAddress: '', pharmacyContact: ''
      ));
    }
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromMap(snapshot.data() as Map<String, dynamic>);
      } else {
        return UserModel(
            uid: uid, email: _auth.currentUser?.email ?? '', name: 'No Name', role: '',
            bio: '', location: '', phoneNumber: '',
            pharmacyName: '', pharmacyAddress: '', pharmacyContact: ''
        );
      }
    });
  }

  Future<String> uploadProfileImage(File imageFile) async {
    if (!await imageFile.exists()) {
      throw Exception('File does not exist. Please pick the image again.');
    }
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(imageFile.path,
            resourceType: CloudinaryResourceType.Image,
            folder: 'profile_images'
        ),
      );
      if (response.secureUrl.isNotEmpty) {
        return response.secureUrl;
      } else {
        throw Exception('Upload failed but no error message provided.');
      }
    } catch (e) {
      print('Error uploading profile image to Cloudinary: $e');
      throw Exception('Failed to upload profile image. Check your Cloud Name and Upload Preset.');
    }
  }

  Future<void> updateUser(UserModel user) async {
    if (user.uid.isEmpty) {
      throw Exception('User ID is required to update user.');
    }
    await _db.collection('users').doc(user.uid).update(user.toMap());
  }

  Future<UserModel?> getPharmacyById(String pharmacyId) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(pharmacyId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print("Error getting pharmacy by ID: $e");
    }
    return null;
  }

  Stream<List<UserModel>> getOtherPharmacies(String currentPharmacyId) {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'pharmacy')
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
        .where((user) => user.uid != currentPharmacyId)
        .toList());
  }

  // --- Medicine Functions ---
  Future<MedicineModel?> getMedicineById(String medicineId) async {
    try {
      DocumentSnapshot doc = await _db.collection('medicines').doc(medicineId).get();
      if (doc.exists && doc.data() != null) {
        return MedicineModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print("Error getting medicine by ID: $e");
    }
    return null;
  }

  Stream<List<MedicineModel>> getSimilarMedicines(String currentMedicineId, String category) {
    return _db
        .collection('medicines')
        .where('category', isEqualTo: category)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MedicineModel.fromMap(doc.data(), doc.id))
        .where((medicine) => medicine.id != currentMedicineId)
        .toList());
  }

  Stream<List<MedicineModel>> getMoreMedicines(String currentMedicineId) {
    return _db
        .collection('medicines')
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MedicineModel.fromMap(doc.data(), doc.id))
        .where((medicine) => medicine.id != currentMedicineId)
        .toList());
  }

  // --- Cart Functions ---
  Future<void> addToCart(MedicineModel medicine) async {
    final String? uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');
    CollectionReference cart = _db.collection('users').doc(uid).collection('cart');
    QuerySnapshot existingItem = await cart.where('medicineId', isEqualTo: medicine.id).limit(1).get();

    if (existingItem.docs.isNotEmpty) {
      DocumentSnapshot cartDoc = existingItem.docs.first;
      int newQuantity = (cartDoc['quantity'] ?? 0) + 1;
      await cart.doc(cartDoc.id).update({'quantity': newQuantity});
    } else {
      UserModel? pharmacy = await getPharmacyById(medicine.pharmacyId);
      String pName = pharmacy?.pharmacyName ?? pharmacy?.name ?? 'Unknown Pharmacy';
      Map<String, dynamic> newItem = {
        'medicineId': medicine.id,
        'medicineName': medicine.medicineName,
        'imageUrl': medicine.imageUrl,
        'price': medicine.price,
        'quantity': 1,
        'pharmacyId': medicine.pharmacyId,
        'pharmacyName': pName,
      };
      await cart.add(newItem);
    }
  }

  Stream<List<CartItemModel>> getCartStream() {
    final String? uid = currentUserId;
    if (uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(uid)
        .collection('cart')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => CartItemModel.fromMap(doc)).toList());
  }

  Future<void> updateCartQuantity(String cartItemId, int newQuantity) async {
    final String? uid = currentUserId;
    if (uid == null) return;
    if (newQuantity > 0) {
      await _db
          .collection('users')
          .doc(uid)
          .collection('cart')
          .doc(cartItemId)
          .update({'quantity': newQuantity});
    } else {
      await removeFromCart(cartItemId);
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    final String? uid = currentUserId;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('cart')
        .doc(cartItemId)
        .delete();
  }

  Future<void> clearCart() async {
    final String? uid = currentUserId;
    if (uid == null) return;
    final cartCollection = _db.collection('users').doc(uid).collection('cart');
    final snapshot = await cartCollection.get();
    WriteBatch batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // --- Address Functions ---
  Stream<List<AddressModel>> getAddresses() {
    final String? uid = currentUserId;
    if (uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => AddressModel.fromMap(doc)).toList());
  }

  Future<void> addAddress(AddressModel address) async {
    final String? uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');
    await _db
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .add(address.toMap());
  }

  Future<void> deleteAddress(String addressId) async {
    final String? uid = currentUserId;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .doc(addressId)
        .delete();
  }

  Future<void> setDefaultAddress(String addressId) async {
    final String? uid = currentUserId;
    if (uid == null) return;
    final CollectionReference addressesRef =
    _db.collection('users').doc(uid).collection('addresses');
    WriteBatch batch = _db.batch();
    QuerySnapshot allAddresses = await addressesRef.get();
    for (var doc in allAddresses.docs) {
      batch.update(doc.reference, {'isDefault': false});
    }
    DocumentReference newDefaultRef = addressesRef.doc(addressId);
    batch.update(newDefaultRef, {'isDefault': true});
    await batch.commit();
  }

  // --- Order Functions ---
  Future<void> placeOrder(OrderModel order) async {
    if (order.userId.isEmpty) throw Exception('User not logged in');

    // 1. Create the order
    DocumentReference orderRef = await _db.collection('orders').add(order.toMap());

    // 2. Create notification for the PHARMACY
    await createNotification(
      userId: order.pharmacyId,
      title: 'New Order Received!',
      body: 'You have a new order (#${orderRef.id.substring(0, 6)}) from ${order.shippingAddress.title}.',
      orderId: orderRef.id,
    );

    // 3. (Optional) Create an "earning" document for the pharmacy
    await _db.collection('earnings').add({
      'pharmacyId': order.pharmacyId,
      'orderId': orderRef.id,
      'amount': order.total,
      'createdAt': order.createdAt,
      'status': 'Pending', // Earning is pending until order is delivered
    });

    // 4. Clear the user's cart
    await clearCart();
  }

  Stream<List<OrderModel>> getPatientOrders() {
    final String? uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => OrderModel.fromMap(doc)).toList());
  }
  Stream<List<OrderModel>> getPharmacyOrders() {
    final String? uid = currentUserId;
    if (uid == null) return Stream.value([]);
    return _db
        .collection('orders')
        .where('pharmacyId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => OrderModel.fromMap(doc)).toList());
  }

  // This function is for the Earning Page
  Stream<QuerySnapshot> getPharmacyEarnings() {
    final String? uid = currentUserId;
    if (uid == null) {
      return const Stream.empty();
    }
    return _db
        .collection('earnings')
        .where('pharmacyId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }


  Future<void> updateOrderStatus(String orderId, String status, String userId, {String? cancellationReason}) async {
    Map<String, dynamic> dataToUpdate = {'status': status};
    if (cancellationReason != null) {
      dataToUpdate['cancellationReason'] = cancellationReason;
    }
    await _db.collection('orders').doc(orderId).update(dataToUpdate);

    // If delivered, update the earning status
    if (status == 'Delivered') {
      QuerySnapshot earningSnap = await _db.collection('earnings').where('orderId', isEqualTo: orderId).limit(1).get();
      if (earningSnap.docs.isNotEmpty) {
        await earningSnap.docs.first.reference.update({'status': 'Completed'});
      }
    }

    // Send notification to the PATIENT
    await createNotification(
      userId: userId,
      title: 'Order $status',
      body: 'Your order (#${orderId.substring(0, 6)}) has been $status.',
      orderId: orderId,
    );
  }

  // --- Notification Functions ---
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    String? orderId,
  }) async {
    final notif = NotificationModel(
      userId: userId,
      title: title,
      body: body,
      createdAt: Timestamp.now(),
      orderId: orderId,
    );
    await _db.collection('users').doc(userId).collection('notifications').add(notif.toMap());
  }

  Stream<List<NotificationModel>> getNotifications() {
    final String? uid = currentUserId;
    if (uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => NotificationModel.fromMap(doc)).toList());
  }

  // --- Rating Function ---
  Future<void> submitRating(MedicineModel medicine, double rating, String review) async {
    final double newRating = ((medicine.rating * medicine.reviewCount) + rating) / (medicine.reviewCount + 1);
    final int newReviewCount = medicine.reviewCount + 1;
    await _db.collection('medicines').doc(medicine.id).update({
      'rating': newRating,
      'reviewCount': newReviewCount,
    });
    await _db.collection('medicines').doc(medicine.id).collection('reviews').add({
      'userId': currentUserId,
      'rating': rating,
      'review': review,
      'createdAt': Timestamp.now(),
    });
  }

  // --- Pharmacy (Inventory) Functions ---
  // (These are duplicated in your file, I am only keeping one set)
  Stream<List<MedicineModel>> getPharmacyMedicines() {
    final String? uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('medicines')
        .where('pharmacyId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) =>
        MedicineModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<String> _uploadImageToCloudinary(File imageFile, String medicineName) async {
    if (!await imageFile.exists()) {
      throw Exception('File does not exist. Please pick the image again.');
    }
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(imageFile.path,
            resourceType: CloudinaryResourceType.Image,
            folder: 'medicine_images'
        ),
      );
      if (response.secureUrl.isNotEmpty) {
        return response.secureUrl;
      } else {
        throw Exception('Upload failed but no error message provided.');
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      throw Exception('Failed to upload image. Check your Cloud Name and Upload Preset.');
    }
  }

  Future<void> addMedicine(MedicineModel medicine, File imageFile) async {
    String imageUrl = await _uploadImageToCloudinary(imageFile, medicine.medicineName);
    MedicineModel medicineWithUrl = MedicineModel(
      medicineName: medicine.medicineName,
      price: medicine.price,
      quantity: medicine.quantity,
      expiryDate: medicine.expiryDate,
      description: medicine.description,
      imageUrl: imageUrl,
      pharmacyId: currentUserId!,
      category: medicine.category,
      isFeatured: medicine.isFeatured,
      inStock: medicine.inStock,
    );
    await _db.collection('medicines').add(medicineWithUrl.toMap());
  }

  Future<void> updateMedicine(MedicineModel medicine, File? newImageFile) async {
    String imageUrl = medicine.imageUrl;
    if (newImageFile != null) {
      imageUrl = await _uploadImageToCloudinary(newImageFile, medicine.medicineName);
    }
    MedicineModel updatedMedicine = MedicineModel(
      id: medicine.id,
      medicineName: medicine.medicineName,
      price: medicine.price,
      quantity: medicine.quantity,
      expiryDate: medicine.expiryDate,
      description: medicine.description,
      imageUrl: imageUrl,
      pharmacyId: medicine.pharmacyId,
      category: medicine.category,
      isFeatured: medicine.isFeatured,
      inStock: medicine.inStock,
    );
    await _db.collection('medicines').doc(medicine.id).update(updatedMedicine.toMap());
  }

  Future<void> deleteMedicine(String medicineId) async {
    await _db.collection('medicines').doc(medicineId).delete();
  }

  Future<void> updateMedicineQuantity(String medicineId, int newQuantity) async {
    await _db.collection('medicines').doc(medicineId).update({
      'quantity': newQuantity,
      'inStock': newQuantity > 0,
    });
  }
}
