import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // A function to save the user's selected track configuration.
  Future<void> saveTrackConfiguration({
    required String trackType,
    required String surfaceType,
    required String weatherCondition,
    String? circuitName,
    String? enginePosition,
    String? aerofoils,
    String? driveType,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      // This should not happen if the user is logged in, but it's good practice to check.
      throw const AuthException('User is not authenticated');
    }

    final configuration = {
      'user_id': userId,
      'track_type': trackType,
      'surface_type': surfaceType,
      'weather_condition': weatherCondition,
      if (circuitName != null) 'circuit_name': circuitName,
      if (enginePosition != null) 'engine_position': enginePosition,
      if (aerofoils != null) 'aerofoils': aerofoils,
      if (driveType != null) 'extra_setup': {'drive_type': driveType},
    };

    List<dynamic> updated = const [];
    try {
      updated = await _supabase
          .from('track_configurations')
          .update(configuration)
          .eq('user_id', userId)
          .select();
    } on PostgrestException catch (e) {
      final missingExtraColumns =
          (e.message.contains('circuit_name') ||
              e.message.contains('engine_position') ||
              e.message.contains('aerofoils')) &&
          (circuitName != null || enginePosition != null || aerofoils != null);

      if (!missingExtraColumns) rethrow;

      final fallbackConfiguration = {
        'user_id': userId,
        'track_type': trackType,
        'surface_type': surfaceType,
        'weather_condition': weatherCondition,
        if (driveType != null) 'extra_setup': {'drive_type': driveType},
      };

      updated = await _supabase
          .from('track_configurations')
          .update(fallbackConfiguration)
          .eq('user_id', userId)
          .select();
    }

    if (updated.isNotEmpty) {
      return;
    }

    try {
      await _supabase.from('track_configurations').insert(configuration);
    } on PostgrestException catch (e) {
      final missingExtraColumns =
          (e.message.contains('circuit_name') ||
              e.message.contains('engine_position') ||
              e.message.contains('aerofoils')) &&
          (circuitName != null || enginePosition != null || aerofoils != null);

      if (!missingExtraColumns) rethrow;

      await _supabase.from('track_configurations').insert({
        'user_id': userId,
        'track_type': trackType,
        'surface_type': surfaceType,
        'weather_condition': weatherCondition,
        if (driveType != null) 'extra_setup': {'drive_type': driveType},
      });
    }
  }
}
