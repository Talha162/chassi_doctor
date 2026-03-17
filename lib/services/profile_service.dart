import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // A function to save the user's selected track configuration.
  Future<void> saveTrackConfiguration({
    required String trackType,
    required String surfaceType,
    required String weatherCondition,
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
    };

    final updated = await _supabase
        .from('track_configurations')
        .update(configuration)
        .eq('user_id', userId)
        .select();

    if (updated is List && updated.isNotEmpty) {
      return;
    }

    await _supabase.from('track_configurations').insert(configuration);
  }
}
