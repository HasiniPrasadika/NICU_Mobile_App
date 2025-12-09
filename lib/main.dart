import 'package:flutter/material.dart';
import 'package:nicu_app/splash_screen.dart'; // Import the splash screen
import 'package:nicu_app/login_page.dart';
import 'package:nicu_app/dashboard_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00BFA6)),
        useMaterial3: true,
      ),
      home: const SplashScreen(), // Set SplashScreen as the first screen
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  // Navigate after a delay to allow splash screen to show
  Future<void> _navigateToNextScreen() async {
    // Wait for a few seconds to show the splash screen
    await Future.delayed(const Duration(seconds: 3));

    // Check for token after the splash screen
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Navigate to the appropriate screen based on token presence
    if (token != null && token.isNotEmpty) {
      // If token exists, navigate to the Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    } else {
      // If no token found, navigate to the LoginPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show the splash screen with the logo and text
    return Scaffold(
      backgroundColor: const Color(0xFF0B1B18),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
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
