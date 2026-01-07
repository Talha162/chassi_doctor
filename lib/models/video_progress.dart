class VideoProgress {
  final String id;
  final String userId;
  final String videoId;
  final int watchedSeconds;
  final bool completed;
  final DateTime updatedAt;

  VideoProgress({
    required this.id,
    required this.userId,
    required this.videoId,
    required this.watchedSeconds,
    required this.completed,
    required this.updatedAt,
  });

  factory VideoProgress.fromJson(Map<String, dynamic> json) {
    return VideoProgress(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      videoId: json['video_id'] as String,
      watchedSeconds: json['watched_seconds'] as int,
      completed: json['completed'] as bool? ?? false,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
