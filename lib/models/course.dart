class Course {
  final String id;
  final String title;
  final String? category;
  final String? description;
  final String? level;
  final int? durationMinutes;
  final String? thumbnailUrl;
  final bool isPublished;
  final DateTime? createdAt;

  Course({
    required this.id,
    required this.title,
    required this.isPublished,
    this.category,
    this.description,
    this.level,
    this.durationMinutes,
    this.thumbnailUrl,
    this.createdAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String?,
      description: json['description'] as String?,
      level: json['level'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      isPublished: json['is_published'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
