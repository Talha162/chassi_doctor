class CourseModule {
  final String id;
  final String courseId;
  final String title;
  final int orderIndex;
  final DateTime? createdAt;

  CourseModule({
    required this.id,
    required this.courseId,
    required this.title,
    required this.orderIndex,
    this.createdAt,
  });

  factory CourseModule.fromJson(Map<String, dynamic> json) {
    return CourseModule(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      title: json['title'] as String,
      orderIndex: json['order_index'] as int,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
