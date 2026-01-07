class CourseRatingSummary {
  final String courseId;
  final int totalReviews;
  final double avgRating;

  CourseRatingSummary({
    required this.courseId,
    required this.totalReviews,
    required this.avgRating,
  });

  factory CourseRatingSummary.fromJson(Map<String, dynamic> json) {
    return CourseRatingSummary(
      courseId: json['course_id'] as String,
      totalReviews: json['total_reviews'] as int,
      avgRating: (json['avg_rating'] as num).toDouble(),
    );
  }
}
