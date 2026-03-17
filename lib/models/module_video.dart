class ModuleVideo {
  final String id;
  final String moduleId;
  final String title;
  final String videoPath;
  final int? durationSeconds;
  final int orderIndex;
  final DateTime? createdAt;

  ModuleVideo({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.videoPath,
    required this.orderIndex,
    this.durationSeconds,
    this.createdAt,
  });

  factory ModuleVideo.fromJson(Map<String, dynamic> json) {
    return ModuleVideo(
      id: json['id'] as String,
      moduleId: json['module_id'] as String,
      title: json['title'] as String,
      videoPath: json['video_path'] as String,
      durationSeconds: json['duration_seconds'] as int?,
      orderIndex: json['order_index'] as int,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
