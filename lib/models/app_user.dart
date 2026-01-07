class AppUser {
  final String id;
  final String? email;
  final String? fullName;
  final String role;
  final String status;
  final int purchasedCourses;
  final int chassisUses;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  // NEW (optional) profile fields:
  final String? avatarUrl;
  final String? phone;
  final String? location;
  final DateTime? dateOfBirth;

  AppUser({
    required this.id,
    required this.role,
    required this.status,
    required this.purchasedCourses,
    required this.chassisUses,
    required this.createdAt,
    this.email,
    this.fullName,
    this.lastLoginAt,
    this.avatarUrl,
    this.phone,
    this.location,
    this.dateOfBirth,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      role: json['role'] as String,
      status: json['status'] as String,
      purchasedCourses: json['purchased_courses'] as int,
      chassisUses: json['chassis_uses'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      location: json['location'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
    );
  }
}
