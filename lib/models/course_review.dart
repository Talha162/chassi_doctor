class CourseReview {
  final String id;
  final String courseId;
  final String userId;
  final int rating;
  final String? reviewText;
  final DateTime createdAt;

  CourseReview({
    required this.id,
    required this.courseId,
    required this.userId,
    required this.rating,
    required this.createdAt,
    this.reviewText,
  });

  factory CourseReview.fromJson(Map<String, dynamic> json) {
    return CourseReview(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      userId: json['user_id'] as String,
      rating: json['rating'] as int,
      reviewText: json['review_text'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
