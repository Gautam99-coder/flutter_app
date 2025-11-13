import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  late Razorpay _razorpay;
  // Your Key ID is public and safe to have here.
  final String keyId = '...'; // Replace with your key ID
  final String keySecret = '...'; // Replace with your secret

  // Callbacks
  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;
  Function(ExternalWalletResponse)? onExternalWallet;

  void initialize() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (onSuccess != null) {
      onSuccess!(response);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (onFailure != null) {
      onFailure!(response);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (onExternalWallet != null) {
      onExternalWallet!(response);
    }
  }

  /// Creates a Razorpay Order by calling YOUR backend server.
  /// This is the secure way to create orders.
  Future<Map<String, dynamic>?> createRazorpayOrder(double amount) async {
    // This is the URL to YOUR backend (e.g., a Firebase Cloud Function)
    // You must create this backend function yourself.
    const String yourBackendUrl = 'https://us-central1-your-project-id.cloudfunctions.net/createRazorpayOrder';

    try {
      final int amountInPaise = (amount * 100).toInt();

      final response = await http.post(
        Uri.parse(yourBackendUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amountInPaise,
          'currency': 'INR',
          // You can pass other user/receipt info here
        }),
      );

      if (response.statusCode == 200) {
        // Your backend should return the order details from Razorpay
        final orderData = jsonDecode(response.body);
        print('Razorpay order created via backend: ${orderData['id']}');
        return orderData;
      } else {
        // If your server fails, log the error
        throw Exception('Failed to create order via backend: ${response.body}');
      }
    } catch (e) {
      print('Error calling createRazorpayOrder: $e');
      return null; // Return null on failure
    }
  }

  void openCheckout({
    required double amount,
    required String orderId,
    required String name,
    required String email,
    required String contact,
  }) {
    final options = {
      'key': keyId, // Your public Key ID
      'amount': (amount * 100).toInt(), // Amount in paise
      'name': 'Urmedio',
      'description': 'Order Payment',
      'order_id': orderId, // The ID you got from your backend
      'prefill': {
        'contact': contact,
        'email': email,
      },
      'theme': {'color': '#007BFF'}
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print('Error opening Razorpay: $e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
