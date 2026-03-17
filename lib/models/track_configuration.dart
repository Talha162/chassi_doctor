class TrackConfiguration {
  final String id;
  final String userId;
  final String? trackType;
  final String? surfaceType;
  final String? weatherCondition;
  final String? presetId;
  final DateTime createdAt;

  TrackConfiguration({
    required this.id,
    required this.userId,
    required this.createdAt,
    this.trackType,
    this.surfaceType,
    this.weatherCondition,
    this.presetId,
  });

  factory TrackConfiguration.fromJson(Map<String, dynamic> json) {
    return TrackConfiguration(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      trackType: json['track_type'] as String?,
      surfaceType: json['surface_type'] as String?,
      weatherCondition: json['weather_condition'] as String?,
      presetId: json['preset_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
