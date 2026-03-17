class CourseProgressSummary {
  final String courseId;
  final String userId;
  final double progressPercentage;

  CourseProgressSummary({
    required this.courseId,
    required this.userId,
    required this.progressPercentage,
  });

  factory CourseProgressSummary.fromJson(Map<String, dynamic> json) {
    return CourseProgressSummary(
      courseId: json['course_id'] as String,
      userId: json['user_id'] as String,
      progressPercentage: (json['progress_percentage'] as num).toDouble(),
    );
  }
}
