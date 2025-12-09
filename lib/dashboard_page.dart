import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:nicu_app/camera_access_manager_sheet.dart';
import 'package:nicu_app/chat_page.dart';
import 'package:nicu_app/live_camera_page.dart';
import 'package:nicu_app/login_page.dart';
import 'package:nicu_app/models/camera_access_request.dart';
import 'package:nicu_app/notifications_page.dart'; // Import NotificationsPage
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:web_socket_channel/web_socket_channel.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  List<Map<String, dynamic>> notifications = [];
  Map<String, dynamic> vitalSigns = {};
  String isJaundiceDetected = '--';
  String jaundiceProbability = '--';
  String isCryDetected = '--';
  String cryProbability = '--';
  String username = '--';
  Timer? _notificationTimer;
  Set<int> seenNotificationIds = {};
  DateTime? _lastTelemetryTime;
  Timer? _timeUpdateTimer;

  WebSocketChannel? channel;

  final String thingsBoardWebSocketUrl =
      'wss://34-49-101-188.nip.io/api/ws'; // Correct WebSocket URL
  final String deviceId =
      '0e066cf0-c31f-11f0-8a67-c384f4f53a9d'; // Your device ID

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('en_custom', CustomTimeAgoMessages());
    _checkToken();
    _getUserInforemation();
    fetchInitialTelemetry();
    startWebSocketConnection();
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  String _mapSeverityToRisk(String severity) {
    switch (severity) {
      case 'critical':
        return 'High';
      case 'warning':
        return 'Medium';
      default:
        return 'Low';
    }
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      // fetchData();
    }
  }

  Future<void> _getUserInforemation() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      final response = await http.get(
        Uri.parse('https://34-49-101-188.nip.io/api/auth/user'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        print('User Information: ${userData["firstName"]}');
        setState(() {
          username = userData['firstName'] ?? 'User';
        });
      } else {
        print(
            'Failed to fetch user information. Status code: ${response.statusCode}');
      }
    }
  }

  Future<void> fetchInitialTelemetry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final deviceResponse = await http.get(
        Uri.parse(
            'https://34-49-101-188.nip.io/api/tenant/devices?deviceName=INC-001'),
        headers: {'Authorization': 'Bearer $token'},
      );
      print('device response: ${deviceResponse.body}');
      if (deviceResponse.statusCode == 200) {
        final deviceData = json.decode(deviceResponse.body);

        // Fetch telemetry data using deviceId
        final telemetryResponse = await http.get(
          Uri.parse(
              'https://34-49-101-188.nip.io/api/plugins/telemetry/DEVICE/$deviceId/values/timeseries?keys=spo2,heart_rate,skin_temp,humidity,air_temp,jaundice_detected,jaundice_probability,cry_detected,nte_critical_count'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (telemetryResponse.statusCode == 200) {
          final telemetryData = json.decode(telemetryResponse.body);
          print('telemetry data: $telemetryData');

          String jaundiceProbabilityy = '';
          String isJaundiceDetectedt = '';
          String isCryDetectedt = '';

          // Ensure we extract values correctly by checking the first element of the list
          bool jaundiceDetected =
              (telemetryData['jaundice_detected']?.first['value'] == 'true');

          // Convert jaundice_probability to double if it's a string
          double jaundiceProbabilityValue = double.tryParse(
                  telemetryData['jaundice_probability']
                          ?.first['value']
                          .toString() ??
                      '0') ??
              0.0;
          bool cryDetected =
              (telemetryData['cry_detected']?.first['value'] == 'true');

          // Set status based on the values
          if (jaundiceDetected) {
            if (jaundiceProbabilityValue > 70) {
              jaundiceProbabilityy =
                  'Probability at $jaundiceProbabilityValue% indicates high risk.';
              isJaundiceDetectedt = 'Jaundice detected';
            } else {
              jaundiceProbabilityy =
                  'Signal detected but below the high-risk threshold.';
              isJaundiceDetectedt = 'Possible jaundice';
            }
          } else {
            jaundiceProbabilityy =
                'Skin tone appears within the expected range.';
            isJaundiceDetectedt = 'No jaundice detected';
          }

          if (cryDetected) {
            isCryDetectedt = 'Cry detected';
          } else {
            isCryDetectedt = 'Baby is Calm';
          }

          setState(() {
            // vitalSigns = telemetryData;
            jaundiceProbability = jaundiceProbabilityy; // Store the result
            isJaundiceDetected = isJaundiceDetectedt; // Store the result
            isCryDetected = isCryDetectedt;
          });
        }
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Future<void> startWebSocketConnection() async {
    // Ensure the WebSocket URL is correct
    String wsUrl = 'wss://34-49-101-188.nip.io/api/ws';
    channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    if (channel == null) {
      print('WebSocket connection failed');
      return;
    } else {
      print('WebSocket connected to $wsUrl');
    }

    // Define your JWT token
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(
        'token'); // You should retrieve this token from SharedPreferences or your login mechanism
    // Replace with your actual device ID

    void reconnectWebSocket() async {
      await Future.delayed(const Duration(seconds: 2));
      await startWebSocketConnection();
    }

    channel!.stream.listen(
      (data) {
        try {
          final decodedData = json.decode(data);

          if (!decodedData.containsKey('data')) return;

          final tsData = decodedData['data'];
          _lastTelemetryTime = DateTime.now();
          print('🔄 Telemetry update received at $_lastTelemetryTime: $tsData');

          setState(() {
            if (tsData['spo2'] != null) {
              var val = tsData['spo2'][0][1];
              vitalSigns['spo2'] = [
                {'value': _parseNumeric(val)}
              ];
            }
            if (tsData['heart_rate'] != null) {
              var val = tsData['heart_rate'][0][1];
              vitalSigns['heart_rate'] = [
                {'value': _parseNumeric(val)}
              ];
            }
            if (tsData['skin_temp'] != null) {
              var val = tsData['skin_temp'][0][1];
              vitalSigns['skin_temp'] = [
                {'value': _parseNumeric(val)}
              ];
            }
            if (tsData['humidity'] != null) {
              var val = tsData['humidity'][0][1];
              vitalSigns['humidity'] = [
                {'value': _parseNumeric(val)}
              ];
            }
            if (tsData['air_temp'] != null) {
              var val = tsData['air_temp'][0][1];
              vitalSigns['air_temp'] = [
                {'value': _parseNumeric(val)}
              ];
            }
          });

          _checkForCryNotification(tsData);
          _checkForJaundiceNotification(tsData);
          _checkForNteNotification(tsData);
        } catch (e, s) {
          debugPrint('⚠️ Telemetry parse error: $e');
          debugPrintStack(stackTrace: s);
        }
      },
      onError: (e) {
        debugPrint('❌ WebSocket error: $e');
        reconnectWebSocket();
      },
      onDone: () {
        debugPrint('🔌 WebSocket closed — reconnecting');
        reconnectWebSocket();
      },
    );

    // Send authentication command to ThingsBoard WebSocket
    final authCommand = {
      "authCmd": {
        "cmdId": 0,
        "token": token,
      },
      "cmds": [
        {
          "entityType": "DEVICE",
          "entityId": deviceId, // Your device ID
          "scope": "LATEST_TELEMETRY", // Telemetry scope
          "cmdId": 10, // Command ID (arbitrary)
          "type": "TIMESERIES",
        }
      ],
    };

    // Send the authentication command to initiate the WebSocket connection
    channel!.sink.add(json.encode(authCommand));
    print('Authentication command sent');
  }

  dynamic _parseNumeric(dynamic val) {
    if (val is num) return val;
    if (val is String) {
      final parsed = double.tryParse(val);
      if (parsed != null) return parsed;
    }
    return '--'; // fallback display string
  }

  void _checkForCryNotification(Map<String, dynamic> tsData) {
    final cryList = tsData['cry_detected'];

    if (cryList == null || cryList.isEmpty) return;

    final cryValue = cryList[0][1];

    if (cryValue == true || cryValue == 'true') {
      showNotification('Cry Detected', 'The baby is crying');

      _saveNotification({
        'type': 'cry',
        'risk': 'Medium',
        'severity': 'warning',
        'title': 'Cry Detected',
        'message': 'The baby is crying',
        'time': DateTime.now().toString(),
      });
    }
  }

  void _checkForJaundiceNotification(Map<String, dynamic> tsData) {
    final list = tsData['jaundice_detected'];
    if (list == null || list.isEmpty) return;

    final val = list[0][1];
    if (val == true || val == 'true') {
      String message = 'Jaundice detected, please monitor the baby closely';
      showNotification(
        'Jaundice Detected',
        message,
      );
      // Save notification in SharedPreferences
      _saveNotification({
        'type': 'jaundice',
        'risk': 'High',
        'severity': 'critical',
        'title': 'Jaundice Detected',
        'message': message,
        'time': DateTime.now().toString(),
      });
    }
  }

  void _checkForNteNotification(Map<String, dynamic> tsData) {
    print('nte data: ${tsData['nte_critical_count']}');
    final list = tsData['nte_critical_count'];
    if (list == null || list.isEmpty) return;

    final count = int.tryParse(list[0][1].toString()) ?? 0;

    if (count > 0) {
      String message =
          'Critical temperature readings detected. Immediate action required.';
      showNotification(
        'NTE Alert',
        message,
      );
      _saveNotification({
        'type': 'nte',
        'risk': 'High',
        'severity': 'critical',
        'title': 'NTE Alert',
        'message': message,
        'time': DateTime.now().toString(),
      });
    }
  }

  Future<void> _saveNotification(Map<String, dynamic> notification) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifications = prefs.getStringList('notifications') ?? [];
    notifications.insert(
        0, json.encode(notification)); // Insert at the start of the list
    await prefs.setStringList('notifications', notifications);
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

// Function to send the subscription command after successful authentication
  void sendSubscriptionCommand() {
    final subscriptionCommand = {
      "tsSubCmds": [
        {
          "entityType": "DEVICE",
          "entityId": deviceId, // Your device ID
          "scope": "LATEST_TELEMETRY", // Telemetry scope
          "cmdId": 1, // Command ID (arbitrary)
          "type": "TIMESERIES"
        }
      ],
      "historyCmds": [], // No historical data
      "attrSubCmds": [] // No attributes
    };

    // Send the subscription command to start receiving telemetry data
    channel!.sink.add(json.encode(subscriptionCommand));
    print('Subscription command sent');
  }

  Future<CameraAccessRequest> _toggleCameraAccess(
    CameraAccessRequest req, String newStatus) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  if (token == null || token.isEmpty) {
    throw Exception('User not authenticated');
  }

  final url = Uri.parse(
      'https://incubator-dashboard-571778410429.us-central1.run.app/api/parent/clinician/camera-access/${req.parentId}');

  final response = await http.patch(
    url,
    headers: {
      'X-API-Key': 'clinician-api-key-12345',
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'babyId': req.babyId,
      'status': newStatus,
      'parentName': req.parentName,
    }),
  );

  if (response.statusCode != 200) {
    // Try to parse the error message
    final payload = json.decode(response.body);
    throw Exception(payload['error'] ?? 'Failed to update camera access');
  }

  final payload = json.decode(response.body);
  final entry = payload['entry'] ?? {};

  return CameraAccessRequest(
    parentId: entry['parentId'] ?? req.parentId,
    babyId: entry['babyId']?.toString() ?? req.babyId,
    parentName: entry['parentName'] ?? req.parentName,
    phone: req.phone, // Phone is not updated by backend
    status: entry['status'] ?? newStatus,
    pendingRequest: entry['pendingRequest'] ?? false,
    requestedAt: entry['requestedAt'] != null
        ? DateTime.parse(entry['requestedAt'])
        : null,
    updatedAt: entry['updatedAt'] != null
        ? DateTime.parse(entry['updatedAt'])
        : DateTime.now(),
    parentCreatedAt: req.parentCreatedAt,
  );
}


  Future<List<CameraAccessRequest>> _fetchCameraRequests() async {
    final res = await http.get(
      Uri.parse(
        'https://incubator-dashboard-571778410429.us-central1.run.app/api/parent/clinician/camera-access/requests',
      ),
      headers: {
        'X-API-Key': 'clinician-api-key-12345',
        'Content-Type': 'application/json',
      },
    );

    print('Camera Requests Response: ${res.body}');

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch camera requests');
    }

    final decoded = json.decode(res.body);

    if (decoded is Map && decoded['entries'] is List) {
      return (decoded['entries'] as List)
          .map((e) => CameraAccessRequest.fromJson(e))
          .toList();
    }

    throw Exception('Unexpected camera request response format');
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    _timeUpdateTimer?.cancel(); // ✅ VERY important
    channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1B18),
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
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $username',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
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
                              _logout();
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
          onRefresh: () async {
            await fetchInitialTelemetry();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Section Header
                Row(
                  children: [
                    const Text(
                      'Monitoring Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),

                    /// Notifications
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationsPage()),
                        );
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _iconContainer(Icons.notifications),
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /// Action buttons row
                Row(
                  children: [
                    _actionButton(
                      icon: Icons.camera_alt,
                      label: 'Live Camera',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LiveCameraPage()),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    _actionButton(
                      icon: Icons.lock_person_rounded,
                      label: 'Camera Access',
                      onTap: () async {
                        final requests = await _fetchCameraRequests();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => CameraAccessManagerSheet(
                            requests: requests,
                            onToggle: _toggleCameraAccess,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        color: Colors.white60, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _lastTelemetryTime == null
                          ? 'Waiting for live data…'
                          : 'Last updated ${formatTimeAgo(_lastTelemetryTime!)}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

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
                        '${vitalSigns['spo2']?.first['value'] ?? '--'} %',
                        const Color(0xFFB45309),
                        Icons.favorite_rounded,
                        false,
                        '--'),
                    _buildVitalCard(
                        'Heart Rate',
                        '${vitalSigns['heart_rate']?.first['value'] ?? '--'} bpm',
                        const Color(0xFFB30000),
                        Icons.favorite_rounded,
                        false,
                        '--'),
                    _buildVitalCard(
                        'Skin Temperature',
                        '${vitalSigns['skin_temp']?.first['value'] ?? '--'} °C',
                        const Color.fromARGB(255, 94, 3, 65),
                        Icons.bar_chart_rounded,
                        true,
                        '${vitalSigns['air_temp']?.first['value'] ?? '--'} °C'),
                    _buildVitalCard(
                        'Humidity',
                        '${vitalSigns['humidity']?.first['value'] ?? '--'} %',
                        const Color(0xFF00997A),
                        Icons.cloud,
                        false,
                        '--'),
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
                _buildJaundiceStatusCard('Jaundice Detection',
                    isJaundiceDetected, jaundiceProbability),
                const SizedBox(height: 8),
                _buildCryStatusCard('Cry Detection', isCryDetected),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Navigate to the chat page when FAB is pressed
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatPage()),
            );
          },
          backgroundColor: const Color(0xFF00B686),
          child: const Icon(Icons.chat),
        ),
      ),
    );
  }

  Widget _iconContainer(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF112C27),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF112C27),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFF00B686), size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVitalCard(String title, String value, Color color, IconData icon,
      bool istemp, String alt) {
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
          istemp
              ? const Row(
                  children: [
                    Text(
                      'Skin Temp',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 24),
                    Text(
                      'Air Temp',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              : Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
          const SizedBox(height: 8),
          istemp
              ? Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 22),
                    Text(
                      alt,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                )
              : Text(
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

  Widget _buildJaundiceStatusCard(String type, String status, String detail) {
    Color borderColor;
    Color statusColor;

    if (status.contains('Jaundice detected')) {
      borderColor = Colors.redAccent;
      statusColor = Colors.redAccent;
    } else if (status.contains('Possible jaundice')) {
      borderColor = Colors.amber;
      statusColor = Colors.amber;
    } else {
      borderColor = Colors.greenAccent;
      statusColor = Colors.greenAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            borderColor.withOpacity(0.2),
            Colors.transparent,
          ],
        ),
        color: const Color(0xFF112C27),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  status.contains('Jaundice detected')
                      ? Icons.warning_amber_outlined
                      : Icons.circle,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                type,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            detail,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),
          Divider(
            color: statusColor,
            thickness: 2.0,
            height: 10,
          ),
          const SizedBox(height: 8),
          // const Row(
          //   children: [
          //     Icon(
          //       Icons.access_time,
          //       color: Colors.white70,
          //       size: 16,
          //     ),
          //     SizedBox(width: 6),
          //     // Text(
          //     //   'Last updated: ${DateTime.now().toString().substring(0, 19)}', // Example timestamp
          //     //   style: const TextStyle(
          //     //     color: Colors.white60,
          //     //     fontSize: 12,
          //     //   ),
          //     // ),
          //   ],
          // ),
        ],
      ),
    );
  }

  String formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    final formatted = timeago.format(
      time,
      locale: 'en_custom',
    );

    // If it says "just now", don't append 'ago'
    if (formatted == 'just now') return formatted;
    return formatted; // otherwise it will include 'ago' automatically
  }
}

class CustomTimeAgoMessages implements timeago.LookupMessages {
  @override
  String prefixAgo() => '';
  @override
  String prefixFromNow() => '';
  @override
  String suffixAgo() => '';
  @override
  String suffixFromNow() => 'from now';
  @override
  String wordSeparator() => ' ';

  @override
  String lessThanOneMinute(int seconds) {
    if (seconds < 5) return 'just now'; // no 'ago'
    return '$seconds seconds ago';
  }

  @override
  String aboutAMinute(int minutes) => '1 minute';
  @override
  String oneMinute(int minutes) => '1 minute';
  @override
  String minutes(int minutes) => '$minutes minutes';
  @override
  String aboutAnHour(int minutes) => 'about 1 hour';
  @override
  String oneHour(int minutes) => '1 hour';
  @override
  String hours(int hours) => '$hours hours';
  @override
  String aDay(int hours) => '1 day';
  @override
  String aboutADay(int hours) => 'about 1 day';
  @override
  String oneDay(int hours) => '1 day';
  @override
  String days(int days) => '$days days';
  @override
  String aboutAMonth(int days) => 'about 1 month';
  @override
  String oneMonth(int days) => '1 month';
  @override
  String months(int months) => '$months months';
  @override
  String aboutAYear(int year) => 'about 1 year';
  @override
  String oneYear(int years) => '1 year';
  @override
  String years(int years) => '$years years';
}

Widget _buildCryStatusCard(String type, String status) {
  Color borderColor;
  Color statusColor;

  // Set color based on the cry detection status
  if (status == 'Cry detected') {
    borderColor = Colors.redAccent;
    statusColor = Colors.redAccent;
  } else if (status == 'Baby is Calm') {
    borderColor = Colors.greenAccent;
    statusColor = Colors.greenAccent;
  } else {
    borderColor = Colors.blueAccent; // Default color if status is not set
    statusColor = Colors.blueAccent;
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          borderColor.withOpacity(0.2),
          Colors.transparent,
        ],
      ),
      color: const Color(0xFF112C27),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderColor, width: 2.0),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                status == 'Cry detected'
                    ? Icons.warning_amber_outlined
                    : Icons.circle,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              type,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          status,
          style: TextStyle(
            color: statusColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Please monitor the baby closely.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 10),
        Divider(
          color: statusColor,
          thickness: 2.0,
          height: 10,
        ),
        const SizedBox(height: 8),
        // const Row(
        //   children: [
        //     Icon(
        //       Icons.access_time,
        //       color: Colors.white70,
        //       size: 16,
        //     ),
        //     SizedBox(width: 6),
        //     // Text(
        //     //   'Last updated: ${DateTime.now().toString().substring(0, 19)}', // Example timestamp
        //     //   style: const TextStyle(
        //     //     color: Colors.white60,
        //     //     fontSize: 12,
        //     //   ),
        //     // ),
        //   ],
        // ),
      ],
    ),
  );
}
