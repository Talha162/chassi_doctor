class CourseLesson {
  final String id;
  final String? courseId;
  final String title;
  final String videoPath;
  final int orderIndex;
  final int? durationSeconds;
  final DateTime? createdAt;

  CourseLesson({
    required this.id,
    required this.title,
    required this.videoPath,
    required this.orderIndex,
    this.courseId,
    this.durationSeconds,
    this.createdAt,
  });

  factory CourseLesson.fromJson(Map<String, dynamic> json) {
    return CourseLesson(
      id: json['id'] as String,
      courseId: json['course_id'] as String?,
      title: json['title'] as String,
      videoPath: json['video_path'] as String,
      orderIndex: json['order_index'] as int,
      durationSeconds: json['duration_seconds'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
