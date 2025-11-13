import 'package:abc_app/checkuser.dart'; // <-- IMPORT CHECKUSER
import 'package:abc_app/forgetpassword.dart';
import 'package:abc_app/services/google_signin_helper.dart';
import 'package:abc_app/signup.dart';
import 'package:abc_app/uihelper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Removed unused imports like Firestore, PatientHomePage, etc.

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _passwordVisible = false;
  bool _rememberMe = false;

  // --- THIS IS THE CORRECT NAVIGATION LOGIC ---
  void _navigateAfterLogin() {
    // This forces the app to re-run the logic in Checkuser > RoleBasedRedirector,
    // which will correctly load the correct BottomNavbar for either role.
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Checkuser()),
            (route) => false, // This removes the login page from the stack
      );
    }
  }
  // --- END OF FIX ---

  // Updated login function
  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      Uihelper.CustomAlertBox(context, "Enter required fields");
      return;
    }

    try {
      // 1. Sign in with Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Navigate correctly
      if (userCredential.user != null) {
        _navigateAfterLogin(); // <-- USE THE CORRECT NAVIGATION
      }
    } on FirebaseAuthException catch (ex) {
      Uihelper.CustomAlertBox(context, ex.code.toString());
    }
  }

  // Updated Google login function
  Future<void> loginWithGoogle() async {
    try {
      User? user = await SimpleGoogleAuth.signInWithGoogle();

      if (user != null) {
        // Navigate correctly
        _navigateAfterLogin(); // <-- USE THE CORRECT NAVIGATION
      } else {
        Uihelper.CustomAlertBox(context, "Google Sign-In was cancelled");
      }
    } catch (e) {
      Uihelper.CustomAlertBox(
          context, "Google Sign-In failed: ${e.toString()}");
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg1.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. Back Button
          // Positioned(
          //   top: 40.0, // Adjust for status bar
          //   left: 10.0,
          //   child: IconButton(
          //     icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          //     onPressed: () => Navigator.of(context).pop(),
          //   ),
          // ),

          // 3. Main Content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Spacing from top
                    const SizedBox(height: 120),

                    // Title
                    const Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1), // Dark blue
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Email Field
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _buildInputDecoration("Email"),
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
                    const SizedBox(height: 5),

                    // Remember Me and Forget Password Row
                    // Responsive Remember Me + Reset Password
                    Row(
                      children: [
                        // Remember Me (Left)
                        Expanded(
                          child: Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                              ),
                              const Flexible(
                                child: Text(
                                  "Remember Me",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Reset Password (Right) - uses intrinsic width
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Forgetpassword()),
                            );
                          },
                          child: const Text(
                            "reset password",
                            style: TextStyle(
                              color: Color(0xFF1E88E5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Sign In Button Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          "Sign In",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            login(emailController.text.trim(),
                                passwordController.text.trim());
                          },
                          child: Image.asset(
                            'assets/images/circle.png',
                            height: 60,
                            width: 60,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // "Or" Divider
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
                    const SizedBox(height: 15),

                    // Google Sign-In Button
                    GestureDetector(
                      onTap: loginWithGoogle,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 50),
                        child: Container(
                          child: Image.asset(
                            'assets/images/googleup.png',
                            height: 50,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Responsive Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Flexible(
                          child: Text(
                            "Don't have an account ? ",
                            style: TextStyle(fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Signup()),
                            );
                          },
                          child: const Text(
                            "sign up",
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