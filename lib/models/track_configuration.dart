class TrackConfiguration {
  final String id;
  final String userId;
  final String? trackType;
  final String? circuitName;
  final String? surfaceType;
  final String? weatherCondition;
  final String? enginePosition;
  final String? aerofoils;
  final String? presetId;
  final DateTime createdAt;

  TrackConfiguration({
    required this.id,
    required this.userId,
    required this.createdAt,
    this.trackType,
    this.circuitName,
    this.surfaceType,
    this.weatherCondition,
    this.enginePosition,
    this.aerofoils,
    this.presetId,
  });

  factory TrackConfiguration.fromJson(Map<String, dynamic> json) {
    return TrackConfiguration(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      trackType: _stringOrNull(json['track_type']),
      circuitName: _stringOrNull(json['circuit_name']),
      surfaceType: _stringOrNull(json['surface_type']),
      weatherCondition: _stringOrNull(json['weather_condition']),
      enginePosition: _stringOrNull(json['engine_position']),
      aerofoils: _stringOrNull(json['aerofoils']),
      presetId: _stringOrNull(json['preset_id']),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return value.toString();
  }
}
