import 'package:flutter/foundation.dart';
import 'package:motorsport/models/adjustment_recommendation.dart';
import 'package:motorsport/models/chassis_issue_option.dart';
import 'package:motorsport/models/chassis_symptom.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DemoAdminSupabaseHelpers {
  static final SupabaseClient _client = Supabase.instance.client;

  // ═══════════════════ SYMPTOMS ═══════════════════
  static Future<List<ChassisSymptom>> getActiveSymptoms() async {
    final res = await _client
        .from('chassis_symptoms')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (res as List)
        .map((json) => ChassisSymptom.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════ ADJUSTMENT SETS ═══════════════════
  static Future<List<Map<String, dynamic>>> getSetsBySymptom(String symptomId) async {
    final res = await _client
        .from('chassis_adjustment_sets')
        .select()
        .eq('symptom_id', symptomId)
        .order('created_at', ascending: false);

    return (res as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> createAdjustmentSet({
    required String symptomId,
    required String title,
    required bool isActive,
  }) async {
    final res = await _client
        .from('chassis_adjustment_sets')
        .insert({
      'symptom_id': symptomId,
      'title': title,
      'is_active': isActive,
    })
        .select()
        .single();

    return res as Map<String, dynamic>;
  }

  // ═══════════════════ ISSUE OPTIONS ═══════════════════
  static Future<List<ChassisIssueOption>> getIssuesBySymptom(String symptomId) async {
    final res = await _client
        .from('chassis_issue_options')
        .select()
        .eq('symptom_id', symptomId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (res as List)
        .map((json) => ChassisIssueOption.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════ SET-ISSUE LINKING ═══════════════════
  static Future<void> linkIssuesToSet({
    required String setId,
    required List<String> issueIds,
  }) async {
    // Delete existing links first
    await _client
        .from('chassis_adjustment_set_issue_options')
        .delete()
        .eq('set_id', setId);

    // Insert new links
    if (issueIds.isNotEmpty) {
      final rows = issueIds
          .map((issueId) => {
                'set_id': setId,
                'issue_option_id': issueId,
              })
          .toList();

      await _client.from('chassis_adjustment_set_issue_options').insert(rows);
    }
  }

  static Future<List<String>> getLinkedIssueIds(String setId) async {
    final res = await _client
        .from('chassis_adjustment_set_issue_options')
        .select('issue_option_id')
        .eq('set_id', setId);

    return (res as List)
        .map((row) => row['issue_option_id'] as String)
        .toList();
  }

  // ═══════════════════ RECOMMENDATIONS ═══════════════════
  static Future<List<AdjustmentRecommendation>> getAllRecommendations() async {
    final res = await _client
        .from('adjustment_recommendations')
        .select()
        .order('created_at', ascending: false);

    return (res as List)
        .map((json) => AdjustmentRecommendation.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<AdjustmentRecommendation> createRecommendation({
    required String title,
    required String details,
    required String category,
  }) async {
    final res = await _client
        .from('adjustment_recommendations')
        .insert({
      'title': title,
      'details': details,
      'category': category,
    })
        .select()
        .single();

    return AdjustmentRecommendation.fromJson(res as Map<String, dynamic>);
  }

  // ═══════════════════ SET-RECOMMENDATION LINKING ═══════════════════
  static Future<void> attachRecommendationToSet({
    required String setId,
    required String recommendationId,
    required int priority,
  }) async {
    await _client.from('chassis_adjustment_set_recommendations').upsert(
      {
        'set_id': setId,
        'recommendation_id': recommendationId,
        'priority_order': priority,
      },
      onConflict: 'set_id,recommendation_id',
    );
  }

  static Future<List<Map<String, dynamic>>> getRecommendationsForSet(String setId) async {
    final res = await _client
        .from('chassis_adjustment_set_recommendations')
        .select('*, adjustment_recommendations(*)')
        .eq('set_id', setId)
        .order('priority_order', ascending: false);

    return (res as List).cast<Map<String, dynamic>>();
  }

  static Future<void> removeRecommendationFromSet({
    required String setId,
    required String recommendationId,
  }) async {
    await _client
        .from('chassis_adjustment_set_recommendations')
        .delete()
        .eq('set_id', setId)
        .eq('recommendation_id', recommendationId);
  }

  // ═══════════════════ TRACK PRESETS (OPTIONAL) ═══════════════════
  static Future<List<Map<String, dynamic>>> getTrackPresets() async {
    try {
      final res = await _client
          .from('track_config_presets')
          .select()
          .order('created_at', ascending: false);
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      // Table might not exist, return empty list
      return [];
    }
  }

  static Future<void> linkPresetsToSet({
    required String setId,
    required List<String> presetIds,
  }) async {
    try {
      // Delete existing links
      await _client
          .from('chassis_adjustment_set_track_presets')
          .delete()
          .eq('set_id', setId);

      // Insert new links
      if (presetIds.isNotEmpty) {
        final rows = presetIds
            .map((presetId) => {
                  'set_id': setId,
                  'preset_id': presetId,
                })
            .toList();

        await _client.from('chassis_adjustment_set_track_presets').insert(rows);
      }
    } catch (e) {
      // Silently fail if table doesn't exist
      debugPrint('[DEMO_ADMIN] Track presets table error: $e');
    }
  }

  static Future<List<String>> getLinkedPresetIds(String setId) async {
    try {
      final res = await _client
          .from('chassis_adjustment_set_track_presets')
          .select('preset_id')
          .eq('set_id', setId);

      return (res as List)
          .map((row) => row['preset_id'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }
}
