import 'package:abc_app/checkuser.dart'; // <-- IMPORT CHECKUSER
import 'package:abc_app/loginpage.dart';
import 'package:abc_app/uihelper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PharmacySignup extends StatefulWidget {
  const PharmacySignup({super.key});

  @override
  State<PharmacySignup> createState() => _PharmacySignupState();
}

class _PharmacySignupState extends State<PharmacySignup> {
  // Controllers for all fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pharmaIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
  TextEditingController();

  bool _agreeToTerms = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  Future<void> signUpPharmacy() async {
    // Validate all fields
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        nameController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        pharmaIdController.text.isEmpty) {
      Uihelper.CustomAlertBox(context, "Please fill all fields");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      Uihelper.CustomAlertBox(context, "Passwords do not match");
      return;
    }

    if (!_agreeToTerms) {
      Uihelper.CustomAlertBox(context, "Please agree to the Terms & Conditions");
      return;
    }

    // --- Start Firebase Logic ---
    try {
      // 1. Create user in Auth
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // 2. Save extra data to Firestore
      if (userCredential.user != null) {
        String uid = userCredential.user!.uid;
        await FirebaseFirestore.instance.collection("users").doc(uid).set({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'pharmaId': pharmaIdController.text.trim(),
          'role': 'pharmacy', // <-- This is the important part
          'uid': uid,
          // Add other pharmacy-specific fields here
          'pharmacyName': nameController.text.trim(), // Default pharmacy name
          'profileImageUrl': '',
          'pharmacyAddress': '',
        });

        // 3. ***** THIS IS THE FIX *****
        // Navigate to Checkuser() to handle role-based redirection.
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Checkuser()),
                (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (ex) {
      Uihelper.CustomAlertBox(context, ex.code.toString());
    }
    // --- End Firebase Logic ---
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    pharmaIdController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg1.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Back Button
          // Positioned(
          //  top: 40.0,
          //  left: 10.0,
          //  child: IconButton(
          //   icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          //   onPressed: () => Navigator.of(context).pop(),
          //  ),
          // ),

          // Main Content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 120),
                    // Title
                    const Text(
                      "Create\nPharmacy Account",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1), // Dark blue
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Name Field
                    TextField(
                      controller: nameController,
                      decoration: _buildInputDecoration("Pharmacy Name"),
                    ),
                    const SizedBox(height: 18),

                    // Email Field
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _buildInputDecoration("Email"),
                    ),
                    const SizedBox(height: 18),

                    // Pharma Id Field
                    TextField(
                      controller: pharmaIdController,
                      decoration: _buildInputDecoration("Pharma License ID"),
                    ),
                    const SizedBox(height: 18),

                    // Password Field
                    TextField(
                      controller: passwordController,
                      obscureText: !_passwordVisible,
                      decoration: _buildInputDecoration(
                        "Password",
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Confirm Password Field
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: !_confirmPasswordVisible,
                      decoration: _buildInputDecoration(
                        "Confirm Password",
                        suffixIcon: IconButton(
                          icon: Icon(
                            _confirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _confirmPasswordVisible =
                              !_confirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Terms & Conditions Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _agreeToTerms,
                          onChanged: (bool? value) {
                            setState(() {
                              _agreeToTerms = value ?? false;
                            });
                          },
                        ),
                        const Text("Agree Terms & Conditions"),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Sign Up Button Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          "Sign Up",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: signUpPharmacy, // Call the new function
                          child: Image.asset(
                            'assets/images/circle.png',
                            height: 60,
                            width: 60,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Login Link
                    // Responsive "Already have an account? sign in"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Flexible(
                          child: Text(
                            "already have an account ? ",
                            style: TextStyle(fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Loginpage()),
                            );
                          },
                          child: const Text(
                            "sign in",
                            style: TextStyle(
                              color: Color(0xFF1E88E5),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40), // Bottom padding
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method
  InputDecoration _buildInputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      contentPadding:
      const EdgeInsets.symmetric(vertical: 18.0, horizontal: 25.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2.0),
      ),
      suffixIcon: suffixIcon,
    );
  }
}