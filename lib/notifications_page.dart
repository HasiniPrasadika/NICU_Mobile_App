import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsPage extends StatefulWidget {

  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  // Add this to hold the notifications
  List<Map<String, dynamic>> notifications = [];

  // Load notifications
  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notificationList = prefs.getStringList('notifications') ?? [];
    setState(() {
      // Decode the JSON strings and cast them to List<Map<String, dynamic>>
      notifications = notificationList
          .map((item) => Map<String, dynamic>.from(json.decode(item)))
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications(); // Load notifications when the page is opened
    tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1B18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1B18),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: tabController,
          labelColor: const Color(0xFF00B686),
          unselectedLabelColor: Colors.white60,
          indicatorColor: const Color(0xFF00B686),
          tabs: const [
            Tab(text: "All"),
            Tab(text: "NTE"),
            Tab(text: "Cry"),
            Tab(text: "Jaundice"),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _list(notifications),
          _list(_filter("nte")),
          _list(_filter("cry")),
          _list(_filter("jaundice")),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filter(String type) {
    return notifications.where((n) => n["type"] == type).toList();
  }

  Widget _list(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          "No notifications",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, i) {
        return _buildNotificationCard(data[i]);
      },
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    final Color bgColor = item["risk"] == "High"
        ? Colors.red.withOpacity(0.8)
        : item["risk"] == "Medium"
            ? Colors.orange.withOpacity(0.8)
            : Colors.blue.withOpacity(0.8);

    final IconData icon = item["risk"] == "High"
        ? Icons.warning_amber_outlined
        : item["risk"] == "Medium"
            ? Icons.error_outline
            : Icons.info_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF112C27),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: bgColor, width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                item["category"]?.toUpperCase() ?? "",
                style: const TextStyle(
                  color: Colors.white54,
                  letterSpacing: 1.1,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item["title"],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "${item["message"]}",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            "Risk: ${item["risk"]}",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            item["time"] ?? "",
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

