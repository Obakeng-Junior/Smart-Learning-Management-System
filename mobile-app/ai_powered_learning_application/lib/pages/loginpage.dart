import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/provider.dart';
import 'homepage.dart';
import 'registrationpage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;
  bool _obscurePassword = true;

  String? emailError;
  String? passwordError;

  // Colors
  final Color _primaryBlue = const Color(0xFF1A73E8);
  final Color _backgroundBlue = const Color(0xFFF8FBFF);
  final Color _lightBlue = const Color(0xFFE8F0FE);
  final Color _textBlue = const Color(0xFF1976D2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundBlue,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_primaryBlue, _backgroundBlue],
                stops: const [0.0, 0.6],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const SizedBox(height: 16),
                const Text(
                  'Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 40),

                // Welcome section
                Center(
                  child: Column(
                    children: const [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white24,
                        child:
                            Icon(Icons.school, size: 50, color: Colors.white),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Welcome Back!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sign in to continue your learning journey',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Login Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryBlue.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email
                        TextFormField(
                          controller: emailController,
                          decoration: _inputDecoration(
                            'Email Address',
                            Icons.email_outlined,
                          ).copyWith(errorText: emailError),
                          validator: (value) =>
                              value == null || !value.contains('@')
                                  ? 'Enter a valid email'
                                  : null,
                        ),

                        const SizedBox(height: 20),

                        // Password
                        TextFormField(
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          decoration: _inputDecoration(
                            'Password',
                            Icons.lock_outline,
                          ).copyWith(
                            errorText: passwordError,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _resetPassword,
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(color: _primaryBlue),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Signup
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account? "),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegistrationPage(),
                                  ),
                                );
                              },
                              child: Text(
                                'Sign up',
                                style: TextStyle(
                                  color: _primaryBlue,
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

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _textBlue),
      filled: true,
      fillColor: _lightBlue,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await Provider.of<UserProvider>(context, listen: false).fetchUserName();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentHomePage(
            studentId: FirebaseAuth.instance.currentUser!.uid,
          ),
        ),
      );
    } catch (_) {
      setState(() {
        emailError = 'Email or password is incorrect';
        passwordError = 'Email or password is incorrect';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!emailController.text.contains('@')) return;
    await _auth.sendPasswordResetEmail(
      email: emailController.text.trim(),
    );
  }
}
