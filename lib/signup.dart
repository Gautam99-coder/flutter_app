import 'package:abc_app/loginpage.dart';
import 'package:abc_app/pharmacy_signup.dart';
import 'package:abc_app/screens/patient/patient_homepage.dart';
import 'package:abc_app/services/google_signin_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:abc_app/uihelper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _agreeToTerms = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  // Modified signUp to include Firestore
  Future<void> signUp(
      String email, String password, String confirmPassword, String name) async {
    if (email.isEmpty ||
        password.isEmpty ||
        name.isEmpty ||
        confirmPassword.isEmpty) {
      Uihelper.CustomAlertBox(context, "Please fill all fields");
      return;
    }
    if (password != confirmPassword) {
      Uihelper.CustomAlertBox(context, "Passwords do not match");
      return;
    }
    if (!_agreeToTerms) {
      Uihelper.CustomAlertBox(context, "Please agree to the Terms & Conditions");
      return;
    }

    try {
      // 1. Create User in Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Save extra data to Firestore
      if (userCredential.user != null) {
        String uid = userCredential.user!.uid;
        await FirebaseFirestore.instance.collection("users").doc(uid).set({
          'name': name,
          'email': email,
          'role': 'patient', // <-- This is the important part
          'uid': uid,
          'profileImageUrl': '', // <-- ADD THIS
          'bio': '',             // <-- ADD THIS
          'location': '',
        });

        // 3. Navigate to Patient Home Page
        // ignore: use_build_context_synchronously
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  PatientHomePage()),
        );
      }
    } on FirebaseAuthException catch (ex) {
      Uihelper.CustomAlertBox(context, ex.code.toString());
    }
  }

  // Modified Google Sign-In to include Firestore
  Future<void> signUpWithGoogle() async {
    try {
      User? user = await SimpleGoogleAuth.signInWithGoogle();

      if (user != null) {
        // Check if user already exists in Firestore (first-time login)
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          // If it's a new user, save their data
          await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .set({
            'name': user.displayName ?? 'Google User',
            'email': user.email,
            'role': 'patient', // Default role for Google Sign-in
            'uid': user.uid,
            'profileImageUrl': '', // <-- ADD THIS
            'bio': '',             // <-- ADD THIS
            'location': '',
          });
        }

        // Navigate to Patient Home Page
        // ignore: use_build_context_synchronously
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  PatientHomePage()),
        );
      } else {
        Uihelper.CustomAlertBox(context, "Google Sign-In was cancelled");
      }
    } catch (e) {
      Uihelper.CustomAlertBox(context, "Google Sign-In failed: ${e.toString()}");
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg1.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Positioned(
          //   top: 40.0,
          //   left: 10.0,
          //   child: IconButton(
          //     icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          //     onPressed: () => Navigator.of(context).pop(),
          //   ),
          // ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 120),
                    const Text(
                      "Create\nAccount",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1), // Dark blue
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- Form Fields ---
                    TextField(
                      controller: nameController,
                      decoration: _buildInputDecoration("Name"),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _buildInputDecoration("Email"),
                    ),
                    const SizedBox(height: 18),
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
                              _confirmPasswordVisible = !_confirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),

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

                    // *** NEW PHARMACY LINK ***
                    Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 10),
                        ),
                        const Text(
                          "if want to signup as ",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to Pharmacy Signup
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                    const PharmacySignup()));
                          },
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: const Text(
                            "Pharmacy",
                            style: TextStyle(
                              color: Color(0xFF1E88E5), // Blue
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

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
                          onTap: () {
                            signUp(
                              emailController.text.trim(),
                              passwordController.text.trim(),
                              confirmPasswordController.text.trim(),
                              nameController.text.trim(),
                            );
                          },
                          child: Image.asset(
                            'assets/images/circle.png',
                            height: 60,
                            width: 60,
                          ),
                        ),
                      ],
                    ),

                    // --- "Or" Divider & Google ---
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text("Or"),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: signUpWithGoogle,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 50),
                        child: Container(
                          child: Image.asset(
                            'assets/images/googleup.png',
                            height: 50, // Adjust height as needed
                          ),
                        ),
                      ),
                    ),

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
    MaterialPageRoute(builder: (context) => const Loginpage()),
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
