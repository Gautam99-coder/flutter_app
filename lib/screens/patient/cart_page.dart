import 'package:abc_app/models/cart_item_model.dart';
import 'package:abc_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final double _shipping = 30.0; // Fixed shipping cost from your UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Cart', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: StreamBuilder<List<CartItemModel>>(
        stream: _firestoreService.getCartStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyCart();
          }

          List<CartItemModel> cartItems = snapshot.data!;

          double subtotal = 0;
          for (var item in cartItems) {
            subtotal += item.price * item.quantity;
          }
          double total = subtotal + _shipping;

          //
          // vvvv THIS IS THE FIX vvvv
          //
          // The Column now correctly contains the List, Summary, and Button
          //
          return Column(
            children: [
              // 1. List of Cart Items
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    return _buildCartItem(cartItems[index]);
                  },
                ),
              ),

              // 2. Summary Section
              _buildSummary(subtotal, total, cartItems.length),

              // 3. Checkout Button
              _buildCheckoutButton(subtotal, total, cartItems),
            ],
          );
          //
          // ^^^^ THIS IS THE FIX ^^^^
          //
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Your Cart is Empty',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            'Looks like you haven\'t added any items yet.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItemModel item) {
    bool hasImage = item.imageUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              width: 60,
              height: 60,
              color: Colors.grey[100],
              child: hasImage
                  ? Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                const Icon(Icons.medication_liquid, color: Colors.grey),
              )
                  : const Icon(Icons.medication_liquid, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),

          // Title and Subtitle (Price)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.medicineName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rs. ${item.price.toStringAsFixed(2)}', // Use price as subtitle
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Quantity Stepper
          Row(
            children: [
              _buildQuantityButton(
                icon: Icons.remove,
                onPressed: () {
                  _firestoreService.updateCartQuantity(
                      item.id, item.quantity - 1);
                },
              ),
              SizedBox(
                width: 30,
                child: Center(
                  child: Text(
                    item.quantity.toString(),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              _buildQuantityButton(
                icon: Icons.add,
                onPressed: () {
                  _firestoreService.updateCartQuantity(
                      item.id, item.quantity + 1);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildSummary(double subtotal, double total, int itemCount) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Subtotal ($itemCount items)', subtotal),
          _buildSummaryRow('Shipping', _shipping),
          const Divider(height: 24, thickness: 1),
          _buildSummaryRow('Total', total, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              color: Colors.grey[700],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'Rs. ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              color: Colors.black,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton(double subtotal, double total, List<CartItemModel> cartItems) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0052CC), // Blue color
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            // Navigate to the new Checkout Page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CheckoutPage(
                  cartItems: cartItems,
                  subtotal: subtotal,
                  shipping: _shipping,
                  total: total,
                ),
              ),
            );
          },
          child: const Text(
            'Checkout',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}