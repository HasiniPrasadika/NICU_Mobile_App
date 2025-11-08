import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:nicu_app/live_camera_page.dart';
import 'package:nicu_app/login_page.dart';
import 'package:nicu_app/notifications_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  List<String> notifications = [];
  Map<String, dynamic> vitalSigns = {};
  bool isJaundiceDetected = false;
  bool isCryDetected = true;

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    fetchData();
    startDataPolling();
  }

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void startDataPolling() {
    Future.delayed(const Duration(seconds: 10), () {
      fetchData();
      startDataPolling();
    });
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'baby_monitor_channel',
      'Baby Monitor Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> fetchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('YOUR_API_BASE_URL/dashboard-data'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          vitalSigns = data['vitalSigns'];
          isJaundiceDetected = data['jaundiceStatus'];
          isCryDetected = data['cryStatus'];
        });

        if (data['notifications'] != null) {
          for (var notification in data['notifications']) {
            if (!notifications.contains(notification)) {
              notifications.add(notification);
              showNotification('Baby Monitor Alert', notification);
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  List<Map<String, dynamic>> formattedNotifications = [
    {
      "type": "jaundice",
      "category": "Jaundice",
      "title": "Jaundice Detection Alert",
      "message": "Jaundice detected with 82% confidence",
      "risk": "Medium",
      "time": "9m ago",
    },
    {
      "type": "jaundice",
      "category": "Jaundice",
      "title": "Jaundice Detection Alert",
      "message": "Jaundice detected with 69% confidence",
      "risk": "Low",
      "time": "19m ago",
    },
    {
      "type": "cry",
      "category": "Cry",
      "title": "Cry Detected",
      "message": "High-intensity cry detected for more than 10 seconds",
      "risk": "Medium",
      "time": "32m ago",
    },
    {
      "type": "cry",
      "category": "Cry",
      "title": "Cry Detected",
      "message": "Normal cry detected. Baby might need attention.",
      "risk": "Low",
      "time": "1h ago",
    },
    {
      "type": "nte",
      "category": "NTE",
      "title": "Temperature Alert",
      "message": "Body temperature dropped to 36.1°C",
      "risk": "High",
      "time": "1h 12m ago",
    },
    {
      "type": "nte",
      "category": "NTE",
      "title": "Heart Rate Warning",
      "message": "Heart rate reached 162 bpm",
      "risk": "Medium",
      "time": "2h ago",
    },
    {
      "type": "nte",
      "category": "NTE",
      "title": "SpO₂ Alert",
      "message": "Oxygen saturation fell to 88%",
      "risk": "High",
      "time": "2h 33m ago",
    },
    {
      "type": "other",
      "category": "General",
      "title": "New Baby Registered",
      "message": "Baby INC003 added to the monitoring system",
      "risk": "Low",
      "time": "3h ago",
    },
    {
      "type": "other",
      "category": "General",
      "title": "System Check Completed",
      "message": "All sensors calibrated and active",
      "risk": "Low",
      "time": "5h ago",
    },
    {
      "type": "cry",
      "category": "Cry",
      "title": "Cry Spike",
      "message": "Sudden cry spike detected at 11:29 AM",
      "risk": "Medium",
      "time": "6h ago",
    },
    {
      "type": "jaundice",
      "category": "Jaundice",
      "title": "Jaundice Detection Alert",
      "message": "Jaundice detected with 91% confidence",
      "risk": "High",
      "time": "6h 45m ago",
    },
    {
      "type": "nte",
      "category": "NTE",
      "title": "Humidity Alert",
      "message": "Humidity dropped to 49%",
      "risk": "Low",
      "time": "8h ago",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1B18), // dark teal/green background
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppBar(
                backgroundColor: const Color(0xFF0B1B18),
                elevation: 0,
                centerTitle: false,
                title: Row(
                  children: [
                    // left logo box (use your asset or an Icon fallback)

                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B686),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, Hasini',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'NICU MONITORING UNIT',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: PopupMenuButton<String>(
                          color:
                              const Color(0xFF0B1B18), // popup background color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                                color: Color(0xFF00B686), width: 1.5),
                          ),
                          onSelected: (value) async {
                            if (value == 'logout') {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.clear();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginPage()),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem<String>(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout, color: Colors.white70),
                                  SizedBox(width: 8),
                                  Text(
                                    'Logout',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          child: const CircleAvatar(
                            radius: 22,
                            backgroundColor: Color(0xFF00B686),
                            child:
                                Icon(Icons.person_outline, color: Colors.white),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: fetchData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with label + icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Monitoring Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        // Camera icon button
                        _buildIconButton(
                          icon: Icons.camera_alt_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LiveCameraPage()),
                            );
                          },
                        ),

                        const SizedBox(width: 12),
                        // Notification icon button with badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _buildIconButton(
                              icon: Icons.notifications_none_rounded,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NotificationsPage(
                                      notifications: formattedNotifications,
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (formattedNotifications.isNotEmpty)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                      minWidth: 12, minHeight: 12),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

// Title below icons

                const Text(
                  'Live Vital Signs',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.1,
                  children: [
                    _buildVitalCard(
                        'SpO₂',
                        '${vitalSigns['oxygenLevel'] ?? '96'} %',
                        const Color(0xFFB45309),
                        Icons.favorite_rounded),
                    _buildVitalCard(
                        'Heart Rate',
                        '${vitalSigns['heartRate'] ?? '63'} bpm',
                        const Color(0xFFB30000),
                        Icons.favorite_rounded),
                    _buildVitalCard(
                        'Skin Temperature',
                        '${vitalSigns['temperature'] ?? '36.7'} °C',
                        const Color.fromARGB(255, 94, 3, 65),
                        Icons.bar_chart_rounded),
                    _buildVitalCard(
                        'Humidity',
                        '${vitalSigns['humidity'] ?? '61'} %',
                        const Color(0xFF00997A),
                        Icons.cloud),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  'Detection Status',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatusCard('Jaundice Detection', isJaundiceDetected),
                const SizedBox(height: 8),
                _buildStatusCard('Cry Detection', isCryDetected),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF112C27),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF00B686).withOpacity(0.4), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: const Color(0xFF57B798),
          size: 26,
        ),
      ),
    );
  }

  Widget _buildVitalCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.8),
            const Color(0xFF0B1B18),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // top row with icon + status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF193C34),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'NORMAL',
                  style: TextStyle(
                    color: Color(0xFF57B798),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Title
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 8),

          // Value
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String type, bool status) {
    bool isJaundice = type == 'Jaundice Detection';
    String moduleType =
        isJaundice ? 'IMAGING ANALYTICS MODULE' : 'VOICE ANALYTICS MODULE';
    Color borderColor = status
        ? (isJaundice ? Colors.redAccent : Colors.greenAccent)
        : const Color(0xFF00B686);

    String headline = isJaundice
        ? (status ? 'Jaundice detected' : 'No jaundice detected')
        : (status ? 'Baby crying' : 'Baby is calm');

    String subtext = isJaundice
        ? (status
            ? 'Probability at 82.3% indicates high risk.'
            : 'Monitoring shows no signs of jaundice.')
        : (status
            ? 'Crying detected above normal sound threshold.'
            : 'Sound levels within the expected range.');

    Color headlineColor = status
        ? (isJaundice ? Colors.redAccent : Colors.yellowAccent)
        : Colors.white;

    Color backgroundColor = const Color(0xFF112C27);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withOpacity(0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: title and monitoring status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    moduleType,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.greenAccent, width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                    SizedBox(width: 6),
                    Text(
                      'Monitoring active',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Status Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: status
                  ? (isJaundice
                      ? Colors.red.shade900.withOpacity(0.8)
                      : Colors.teal.shade800)
                  : Colors.teal.shade900.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  status
                      ? (isJaundice
                          ? Icons.error_outline
                          : Icons.mood_bad_outlined)
                      : Icons.sentiment_satisfied_alt_outlined,
                  color: headlineColor,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: TextStyle(
                          color: headlineColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtext,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
