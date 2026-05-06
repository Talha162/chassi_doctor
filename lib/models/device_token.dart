class DeviceToken {
  final String id;
  final String userId;
  final String token;
  final String? platform;
  final DateTime createdAt;

  DeviceToken({
    required this.id,
    required this.userId,
    required this.token,
    this.platform,
    required this.createdAt,
  });

  factory DeviceToken.fromJson(Map<String, dynamic> json) {
    return DeviceToken(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      token: json['token'] as String,
      platform: json['platform'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
