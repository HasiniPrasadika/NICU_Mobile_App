class NotificationModel {
  final String id;
  final String type;
  final String severity;
  final String title;
  final String message;
  final String time;
  final Map<String, dynamic> data;

  NotificationModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.time,
    required this.data,
  });

  // Convert NotificationModel to Map to store in SharedPreferences
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'severity': severity,
      'title': title,
      'message': message,
      'time': time,
      'data': data,
    };
  }

  // Convert Map to NotificationModel
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'],
      type: map['type'],
      severity: map['severity'],
      title: map['title'],
      message: map['message'],
      time: map['time'],
      data: map['data'],
    );
  }
}
