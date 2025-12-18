import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/provider.dart';
import '../routes/routes.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // 🔹 Controllers
  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      await _firestore.collection('students').doc(uid).set({
        'name': nameController.text.trim(),
        'surname': surnameController.text.trim(),
        'email': emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      Provider.of<UserProvider>(context, listen: false)
          .setName(nameController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful')),
      );

      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    // Clean up controllers
    nameController.dispose();
    surnameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 188, 213, 252),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Register'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 188, 213, 252),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Image.asset('assets/images/hello.png', height: 250),
              const SizedBox(height: 30),
              const Text('Welcome!', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              const Text(
                'Let\'s help you get started',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),

              // 🔹 Name
              _buildTextField(
                controller: nameController,
                label: 'Name',
                validator: (value) => value!.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 20),

              // 🔹 Surname
              _buildTextField(
                controller: surnameController,
                label: 'Surname',
                validator: (value) =>
                    value!.isEmpty ? 'Enter your surname' : null,
              ),
              const SizedBox(height: 20),

              // 🔹 Email
              _buildTextField(
                controller: emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty || !value.contains('@')
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 20),

              // 🔹 Password
              _buildTextField(
                controller: passwordController,
                label: 'Password',
                obscureText: true,
                validator: (value) => value != null && value.length < 6
                    ? 'Password must be at least 6 characters'
                    : null,
              ),
              const SizedBox(height: 20),

              // 🔹 Confirm Password (fixed)
              _buildTextField(
                controller: confirmPasswordController,
                label: 'Confirm Password',
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  } else if (value != passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // 🔹 Register Button
              isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Register',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(fontSize: 12),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, AppRoutes.login);
                              },
                              child: const Text(
                                'Sign In',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.blue),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Helper widget for styled text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white, fontSize: 20),
        filled: true,
        fillColor: const Color.fromARGB(255, 122, 184, 245),
        enabledBorder: OutlineInputBorder(
          borderSide:
              const BorderSide(color: Color.fromARGB(255, 122, 184, 245)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      validator: validator,
    );
  }
}
