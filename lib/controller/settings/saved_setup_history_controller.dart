import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:motorsport/models/chassis_session.dart';
import 'package:motorsport/models/history_entry.dart';
import 'package:motorsport/models/track_configuration.dart';
import 'package:motorsport/services/supabase/supabase_client_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavedSetupHistoryController extends GetxController {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final _user = Supabase.instance.client.auth.currentUser;

  var isLoading = true.obs;
  var entries = <HistoryEntry>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchSavedSetups();
  }

  Future<void> fetchSavedSetups() async {
    if (_user == null) {
      // Handle case where user is somehow not logged in
      debugPrint('[HISTORY] ⚠️ User not authenticated');
      isLoading.value = false;
      return;
    }
    try {
      isLoading.value = true;
      debugPrint('[HISTORY] 📋 Fetching history for user: ${_user!.id}');
      final sessions =
          await _supabaseService.getChassisSessionsForUser(_user.id);
      final configs =
          await _supabaseService.getTrackConfigurationsForUser(_user.id);

      debugPrint('[HISTORY] ✅ Found ${sessions.length} recommendation sessions');
      debugPrint('[HISTORY] ✅ Found ${configs.length} track configurations');

      final combined = <HistoryEntry>[
        ...sessions.map((session) {
          debugPrint('[HISTORY] 📌 Session ${session.id}: ${session.symptomSnapshot['title'] ?? 'Unknown'} (${session.recommendations.length} recs)');
          return HistoryEntry(
            id: session.id,
            createdAt: session.createdAt,
            trackSnapshot: session.trackSnapshot,
            symptomSnapshot: session.symptomSnapshot,
            issuesSnapshot: session.issuesSnapshot,
            recommendations: session.recommendations,
            hasSessionData: true,
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
      'surface_type': config.surfaceType,
      'weather_condition': config.weatherCondition,
    };
  }
}
