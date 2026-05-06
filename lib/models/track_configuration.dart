class TrackConfiguration {
  final String id;
  final String userId;
  final String? trackType;
  final String? circuitName;
  final String? surfaceType;
  final String? weatherCondition;
  final String? enginePosition;
  final String? aerofoils;
  final String? driveType;
  final String? presetId;
  final Map<String, dynamic> extraSetup;
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
    this.driveType,
    this.presetId,
    this.extraSetup = const <String, dynamic>{},
  });

  factory TrackConfiguration.fromJson(Map<String, dynamic> json) {
    final extraSetup = (json['extra_setup'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    return TrackConfiguration(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      trackType: _stringOrNull(json['track_type']),
      circuitName: _stringOrNull(json['circuit_name']),
      surfaceType: _stringOrNull(json['surface_type']),
      weatherCondition: _stringOrNull(json['weather_condition']),
      enginePosition: _stringOrNull(json['engine_position']),
      aerofoils: _aerofoilsLabel(json['aerofoils']),
      driveType: _stringOrNull(extraSetup['drive_type']),
      presetId: _stringOrNull(json['preset_id']),
      extraSetup: extraSetup,
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

  static String? _aerofoilsLabel(dynamic value) {
    if (value == null) return null;
    if (value is bool) {
      return value ? 'Yes' : 'No';
    }
    if (value is String) {
      final trimmed = value.trim().toLowerCase();
      if (trimmed == 'true' || trimmed == 'yes') return 'Yes';
      if (trimmed == 'false' || trimmed == 'no') return 'No';
      return trimmed.isEmpty ? null : value.trim();
    }
    return value.toString();
  }
}
