import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final Color primaryGreen = const Color(0xFF00BFA6);
  final Color darkBg = const Color(0xFF052E2A);
  final Color panelBg = const Color(0xFF0C3C35);

  Future<void> _tempLogin() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DashboardPage()),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await http.post(
          Uri.parse('https://thingsboard.cloud/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': _emailController.text,
            'password': _passwordController.text,
          }),
        );

        if (response.statusCode == 200) {
          final token = json.decode(response.body)['token'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid credentials')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection error')),
        );
      }

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1B18),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: panelBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF00BFA6), // same green as your theme
                    width: 2.0, // thickness of border
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Hospital Logo
                    Image.asset(
                      'assets/images/logo.png',
                      height: 70,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'NATIONAL HOSPITAL GALLE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'NICU MONITORING UNIT',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'AUTHORISED STAFF',
                        style:
                            TextStyle(color: Colors.greenAccent, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 40),

                    const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Email or phone',
                              labelStyle:
                                  const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.black12,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primaryGreen),
                              ),
                            ),
                            validator: (value) => value!.isEmpty
                                ? 'Please enter your email'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle:
                                  const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.black12,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primaryGreen),
                              ),
                            ),
                            validator: (value) => value!.isEmpty
                                ? 'Please enter your password'
                                : null,
                          ),
                          const SizedBox(height: 28),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _tempLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'SIGN IN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
