import 'dart:async';
import 'package:flutter/material.dart';
 // Import your AuthChecker

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Show logo or animation in the center of the screen
    return Scaffold(
      backgroundColor: const Color(0xFF0B1B18), // Dark background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png', // Replace with your logo path
              height: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              'NATIONAL HOSPITAL GALLE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'NICU MONITORING UNIT',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
