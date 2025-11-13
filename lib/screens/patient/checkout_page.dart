// screens/patient/checkout_page.dart
import 'package:abc_app/models/address_model.dart';
import 'package:abc_app/models/cart_item_model.dart';
import 'package:abc_app/models/order_model.dart';
import 'package:abc_app/models/payment_model.dart';
import 'package:abc_app/screens/patient/order_confirmation_page.dart';
import 'package:abc_app/screens/patient/saved_addresses_page.dart';
import 'package:abc_app/services/firestore_service.dart';
// import 'package:abc_app/services/location_service.dart'; // REMOVED
// import 'package:abc_app/screens/patient/pharmacy_location_page.dart'; // REMOVED
import 'package:abc_app/screens/map/map_page.dart'; // ADDED
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../services/Razorpay_service.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItemModel> cartItems;
  final double subtotal;
  final double shipping;
  final double total;

  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.subtotal,
    required this.shipping,
    required this.total,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final RazorpayService _razorpayService = RazorpayService();

  // Payment and order variables
  String? _selectedAddressId;
  List<AddressModel> _availableAddresses = [];
  String _selectedPaymentMethod = 'Razorpay';
  bool _isLoading = false;
  String? _razorpayOrderId;

  // Location variables
  LatLng? _selectedUserLocation;
  String _selectedLocationType = 'saved_address'; // or 'current_location'

  // Controllers
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _razorpayService.initialize();
    _setupRazorpayCallbacks();
  }

  void _setupRazorpayCallbacks() {
    _razorpayService.onSuccess = _handlePaymentSuccess;
    _razorpayService.onFailure = _handlePaymentFailure;
    _razorpayService.onExternalWallet = _handleExternalWallet;
  }

  // ---------------- LOCATION SELECTION (MODIFIED) ----------------

  Future<void> _selectCurrentLocation() async {
    try {
      // MODIFIED: No longer need LocationService or to get pharmacies here.
      // The new MapPage handles all of that. We just push it in
      // selection mode and wait for the user to pick a LatLng.

      final selectedLocation = await Navigator.push<LatLng>(
        context,
        MaterialPageRoute(
          builder: (context) => const MapPage(
            isSelectingLocation: true,
          ),
        ),
      );

      if (selectedLocation != null) {
        setState(() {
          _selectedUserLocation = selectedLocation;
          _selectedLocationType = 'current_location';
        });

        _fillAddressFromLocation(selectedLocation);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open map: $e')),
      );
    }
  }

  Future<void> _fillAddressFromLocation(LatLng location) async {
    _addressController.text =
    'Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}';
  }

  // ---------------- PAYMENT HANDLING (Unchanged) ----------------

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      AddressModel? selectedAddress;

      if (_selectedLocationType == 'saved_address') {
        selectedAddress = _availableAddresses
            .firstWhere((a) => a.id == _selectedAddressId, orElse: () => AddressModel.empty());
      } else if (_selectedLocationType == 'current_location' && _selectedUserLocation != null) {
        selectedAddress = AddressModel(
          id: 'current_location',
          title: 'Current Location',
          addressLine1: _addressController.text,
          addressLine2: '',
          city: '',
          stateRegion: '',
          postalCode: '',
          country: 'India',
          isDefault: false,
          userId: user.uid,
        );
      }

      if (selectedAddress == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid address.')),
        );
        return;
      }

      final payment = PaymentModel(
        orderId: _razorpayOrderId ?? response.orderId ?? '',
        userId: user.uid,
        paymentMethod: 'Razorpay',
        status: 'Success',
        amount: widget.total,
        razorpayPaymentId: response.paymentId,
        razorpayOrderId: response.orderId,
        razorpaySignature: response.signature,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      await _firestoreService.createPayment(payment);
      await _placeOrderAfterPayment(selectedAddress, user.uid);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment processing failed: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}')),
    );
  }

  Future<void> _processPayment() async {
    if (_selectedLocationType == 'current_location' && _selectedUserLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your current location')),
      );
      return;
    }

    if (_selectedLocationType == 'saved_address' &&
        (_selectedAddressId == null || _selectedAddressId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shipping address')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      if (_selectedPaymentMethod == 'Cash on Delivery') {
        AddressModel address;
        if (_selectedLocationType == 'saved_address') {
          address = _availableAddresses
              .firstWhere((a) => a.id == _selectedAddressId, orElse: () => AddressModel.empty());
        } else {
          address = AddressModel(
            id: 'current_location',
            title: 'Current Location',
            addressLine1: _addressController.text,
            addressLine2: '',
            city: '',
            stateRegion: '',
            postalCode: '',
            country: 'India',
            isDefault: false,
            userId: user.uid,
          );
        }

        await _placeOrderAfterPayment(address, user.uid);
      } else {
        await _initiateRazorpayPayment(user.uid);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    }
  }

  Future<void> _initiateRazorpayPayment(String userId) async {
    try {
      final orderResponse = await _razorpayService.createRazorpayOrder(widget.total);
      final razorpayId = orderResponse?['id'];

      if (razorpayId is String && razorpayId.isNotEmpty) {
        _razorpayOrderId = razorpayId;

        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        final userData = userDoc.data() as Map<String, dynamic>?;

        _razorpayService.openCheckout(
          amount: widget.total,
          orderId: razorpayId,
          name: userData?['name'] ?? 'Customer',
          email: userData?['email'] ?? '',
          contact: userData?['phoneNumber'] ?? '9999999999',
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize Razorpay: $e')),
      );
    }
  }

  Future<void> _placeOrderAfterPayment(AddressModel address, String userId) async {
    try {
      final pharmacyId = widget.cartItems.first.pharmacyId;
      final pharmacyName = widget.cartItems.first.pharmacyName;

      final order = OrderModel(
        userId: userId,
        pharmacyId: pharmacyId,
        pharmacyName: pharmacyName,
        items: widget.cartItems,
        shippingAddress: address,
        subtotal: widget.subtotal,
        shipping: widget.shipping,
        total: widget.total,
        paymentMethod: _selectedPaymentMethod,
        status: _selectedPaymentMethod == 'Cash on Delivery' ? 'Pending' : 'Confirmed',
        createdAt: Timestamp.now(),
      );

      await _firestoreService.placeOrder(order);

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderConfirmationPage(order: order)),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    }
  }

  // ---------------- UI SECTION (Unchanged) ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Delivery Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildLocationSelector(),
                  const SizedBox(height: 24),
                  const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _buildPaymentMethodOption('Razorpay'),
                  _buildPaymentMethodOption('Cash on Delivery'),
                  const SizedBox(height: 24),
                  const Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _buildSummaryRow('Subtotal', widget.subtotal),
                  _buildSummaryRow('Shipping', widget.shipping),
                  const Divider(),
                  _buildSummaryRow('Total', widget.total, isTotal: true),
                ],
              ),
            ),
          ),
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('Use Saved Address'),
          value: 'saved_address',
          groupValue: _selectedLocationType,
          onChanged: (v) => setState(() => _selectedLocationType = v!),
        ),
        if (_selectedLocationType == 'saved_address') _buildSavedAddressesDropdown(),
        RadioListTile<String>(
          title: const Text('Use Current Location'),
          value: 'current_location',
          groupValue: _selectedLocationType,
          onChanged: (v) {
            setState(() => _selectedLocationType = v!);
            _selectCurrentLocation(); // This now calls the modified function
          },
        ),
        if (_selectedLocationType == 'current_location' && _selectedUserLocation != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              _addressController.text,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
      ],
    );
  }

  Widget _buildSavedAddressesDropdown() {
    return StreamBuilder<List<AddressModel>>(
      stream: _firestoreService.getAddresses(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        _availableAddresses = snapshot.data!;
        if (_availableAddresses.isEmpty) {
          return const Center(
            child: Text('No saved addresses. Please add one.'),
          );
        }
        return DropdownButtonFormField<String>(
          value: _selectedAddressId,
          hint: const Text('Select Address'),
          items: _availableAddresses
              .map((a) => DropdownMenuItem(value: a.id, child: Text(a.title)))
              .toList(),
          onChanged: (v) => setState(() => _selectedAddressId = v),
        );
      },
    );
  }

  Widget _buildPaymentMethodOption(String title) {
    return RadioListTile<String>(
      title: Text(title),
      value: title,
      groupValue: _selectedPaymentMethod,
      onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
    );
  }

  Widget _buildSummaryRow(String title, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text('₹${value.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Colors.green, // Use a consistent color
          foregroundColor: Colors.white,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(_selectedPaymentMethod == 'Cash on Delivery'
            ? 'Place Order (COD)'
            : 'Continue to Payment'),
      ),
    );
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    _addressController.dispose();
    super.dispose();
  }
}