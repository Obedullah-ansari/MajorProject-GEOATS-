import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'login_page.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _employeeIdController = TextEditingController(); // ⭐ NEW
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isLoading = false;

  // 🔥 SIGNUP FUNCTION
  Future<void> signup() async {
    if (_employeeIdController.text.trim().isEmpty) {
      _showErrorDialog("Please enter Employee ID");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // ⭐ SAVE USER DATA TO FIRESTORE
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': _nameController.text.trim(),
        'employeeId': _employeeIdController.text.trim(), // ⭐ NEW FIELD
        'email': _emailController.text.trim(),
        'uid': userCredential.user!.uid,
        'createdAt': Timestamp.now(),
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HomeScreen(user: userCredential.user)),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog(e.toString());
    }
  }

  // 🔴 ERROR DIALOG
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff000000), Color(0xff5B247A)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 40),
                  Text(
                    'Create an Account',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  SizedBox(height: 40),

                  // NAME
                  _buildTextField(
                    controller: _nameController,
                    hintText: 'Enter your name',
                    icon: Icons.person,
                  ),
                  SizedBox(height: 20),

                  // ⭐ EMPLOYEE ID FIELD
                  _buildTextField(
                    controller: _employeeIdController,
                    hintText: 'Enter your Employee ID',
                    icon: Icons.badge,
                  ),
                  SizedBox(height: 20),

                  // EMAIL
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'Enter your email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 20),

                  // PASSWORD
                  _buildTextField(
                    controller: _passwordController,
                    hintText: 'Enter your password',
                    icon: Icons.lock,
                    obscureText: true,
                  ),
                  SizedBox(height: 40),

                  // SIGNUP BUTTON
                  _buildSignupButton(),

                  SizedBox(height: 20),

                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LoginScreen()),
                      );
                    },
                    child: Text(
                      "Already have an account? Log In",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 CUSTOM TEXT FIELD
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  // 🔹 SIGNUP BUTTON
  Widget _buildSignupButton() {
    return GestureDetector(
      onTap: isLoading ? null : signup,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.white))
            : Text(
                'Sign Up',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}