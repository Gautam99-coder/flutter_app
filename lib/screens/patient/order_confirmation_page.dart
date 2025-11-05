import 'package:abc_app/models/order_model.dart';
import 'package:abc_app/screens/patient/my_orders_page.dart';
import 'package:abc_app/widgets/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderConfirmationPage extends StatelessWidget {
  final OrderModel order;
  const OrderConfirmationPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('dd MMMM yyyy').format(order.createdAt.toDate());
    String estimatedDelivery = DateFormat('dd MMMM yyyy').format(order.createdAt.toDate().add(const Duration(days: 3)));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Order Confirmation'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Disable back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Icon(Icons.check_circle, color: Colors.green, size: 80),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Order Placed Successfully!',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Order Details
                    _buildInfoRow('Order Number', '#${order.id?.substring(0, 8) ?? 'N/A'}'),
                    _buildInfoRow('Order Date', formattedDate),
                    _buildInfoRow('Estimated Delivery', estimatedDelivery),
                    _buildInfoRow('Payment Method', order.paymentMethod),
                    _buildInfoRow('Status', order.status),

                    const SizedBox(height: 24),
                    const Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),

                    // Order Items
                    ...order.items.map((item) => _buildSummaryRow(
                      '${item.medicineName} (x${item.quantity})',
                      (item.price * item.quantity).toDouble(),
                    )).toList(),

                    const Divider(),
                    _buildSummaryRow('Subtotal', order.subtotal),
                    _buildSummaryRow('Shipping', order.shipping),
                    _buildSummaryRow('Total', order.total, isTotal: true),

                    const SizedBox(height: 24),

                    // Shipping Address
                    const Text('Shipping Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      '${order.shippingAddress.title}\n'
                          '${order.shippingAddress.addressLine1}\n'
                          '${order.shippingAddress.addressLine2.isNotEmpty ? '${order.shippingAddress.addressLine2}\n' : ''}'
                          '${order.shippingAddress.city}, ${order.shippingAddress.stateRegion}\n'
                          '${order.shippingAddress.postalCode}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),

                    const SizedBox(height: 24), // Add some space before buttons
                  ],
                ),
              ),
            ),

            // Action Buttons (fixed at bottom)
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const MyOrdersPage()),
                            (route) => false,
                      );
                    },
                    child: const Text('View My Orders', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey[300]!)
                    ),
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const BottomNavbar()),
                            (route) => false,
                      );
                    },
                    child: const Text('Continue Shopping', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
              color: isTotal ? Colors.black : Colors.grey[700],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
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
}
