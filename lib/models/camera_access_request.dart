class CameraAccessRequest {
  final int parentId;
  final String parentName;
  final String phone;
  final String babyId;
  String status;
  final bool pendingRequest;
  final DateTime? requestedAt;
  final DateTime updatedAt;
  final DateTime parentCreatedAt;

  CameraAccessRequest({
    required this.parentId,
    required this.parentName,
    required this.phone,
    required this.babyId,
    required this.status,
    required this.pendingRequest,
    this.requestedAt,
    required this.updatedAt,
    required this.parentCreatedAt,
  });

  factory CameraAccessRequest.fromJson(Map<String, dynamic> json) {
    return CameraAccessRequest(
      parentId: json['parentId'], // ✅ int
      parentName: json['parentName'] ?? '',
      phone: json['phone'] ?? '',
      babyId: json['babyId'].toString(), // ✅ convert int/string safely
      status: json['status'] ?? 'revoked',
      pendingRequest: json['pendingRequest'] ?? false,
      requestedAt: json['requestedAt'] != null
          ? DateTime.parse(json['requestedAt'])
          : null, // ✅ null-safe
      updatedAt: DateTime.parse(json['updatedAt']),
      parentCreatedAt: DateTime.parse(json['parentCreatedAt']),
    );
  }
}
