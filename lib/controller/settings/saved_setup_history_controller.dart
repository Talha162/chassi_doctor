import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:motorsport/models/history_entry.dart';
import 'package:motorsport/models/track_configuration.dart';
import 'package:motorsport/services/supabase/supabase_client_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavedSetupHistoryController extends GetxController {
  final SupabaseService _supabaseService = SupabaseService.instance;
  // Read the signed-in user at fetch time, not once at construction: this
  // controller can outlive a logout, and a cached user would show the
  // previous account's history (or none) to the next person who logs in.
  User? get _user => Supabase.instance.client.auth.currentUser;

  var isLoading = true.obs;
  var entries = <HistoryEntry>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchSavedSetups();
  }

  Future<void> fetchSavedSetups() async {
    final user = _user;
    if (user == null) {
      entries.clear();
      // Handle case where user is somehow not logged in
      debugPrint('[HISTORY] ⚠️ User not authenticated');
      isLoading.value = false;
      return;
    }
    try {
      // Skeletons only on the first load; pull-to-refresh keeps the list.
      isLoading.value = entries.isEmpty;
      debugPrint('[HISTORY] 📋 Fetching history for user: ${user.id}');
      final sessions = await _supabaseService.getChassisSessionsForUser(
        user.id,
      );
      final configs = await _supabaseService.getTrackConfigurationsForUser(
        user.id,
      );

      debugPrint(
        '[HISTORY] ✅ Found ${sessions.length} recommendation sessions',
      );
      debugPrint('[HISTORY] ✅ Found ${configs.length} track configurations');

      final combined = <HistoryEntry>[
        ...sessions.map((session) {
          debugPrint(
            '[HISTORY] 📌 Session ${session.id}: ${session.symptomSnapshot['title'] ?? 'Unknown'} (${session.recommendations.length} recs)',
          );
          return HistoryEntry(
            id: session.id,
            createdAt: session.createdAt,
            trackSnapshot: session.trackSnapshot,
            symptomSnapshot: session.symptomSnapshot,
            issuesSnapshot: session.issuesSnapshot,
            recommendations: session.recommendations,
            hasSessionData: true,
            sessionName: session.sessionName,
            eventDate: session.eventDate,
          );
        }),
        ...configs.map((config) {
          debugPrint('[HISTORY] 🏁 Track: ${config.trackType}');
          return HistoryEntry(
            id: 'track-${config.id}',
            createdAt: config.createdAt,
            trackSnapshot: _trackSnapshotFromConfig(config),
            symptomSnapshot: const <String, dynamic>{},
            issuesSnapshot: const <dynamic>[],
            recommendations: const <dynamic>[],
            hasSessionData: false,
          );
        }),
      ];

      combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      entries.assignAll(combined);
      debugPrint('[HISTORY] ✨ History loaded: ${entries.length} total items');
    } catch (e) {
      // You could show a snackbar or dialog here
      debugPrint('[HISTORY] ❌ Error fetching saved setups: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic> _trackSnapshotFromConfig(TrackConfiguration config) {
    return {
      'track_type': config.trackType,
      'circuit_name': config.circuitName,
      'surface_type': config.surfaceType,
      'weather_condition': config.weatherCondition,
      'engine_position': config.enginePosition,
      'aerofoils': config.aerofoils,
    };
  }
}
