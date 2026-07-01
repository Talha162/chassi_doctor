import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/app_user.dart';
import '../../models/adjustment_recommendation.dart';
import '../../models/course.dart';
import '../../models/course_enrollment.dart';
import '../../models/course_module.dart';
import '../../models/course_progress_summary.dart';
import '../../models/course_rating_summary.dart';
import '../../models/course_review.dart';
import '../../models/module_progress_summary.dart';
import '../../models/module_video.dart';
import '../../models/chassis_issue_option.dart';
import '../../models/chassis_session.dart';
import '../../models/chassis_symptom.dart';
import '../../models/app_notification.dart';
import '../../models/history_note.dart';
import '../../models/track_configuration.dart';
import '../../models/video_progress.dart';
import '../../models/device_token.dart';
import 'package:path/path.dart' as p; // 👈 ADD THIS




class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  final SupabaseClient _client = Supabase.instance.client;

  // ───────────────── USERS ─────────────────

  Future<AppUser?> getUserById(String userId) async {
    final res = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (res == null) return null;
    return AppUser.fromJson(res as Map<String, dynamic>);
  }

  // ───────────────── COURSES ─────────────────

  Future<List<Course>> getPublishedCourses() async {
    final res = await _client
        .from('courses')
        .select()
        .eq('is_published', true)
        .order('created_at', ascending: false);

    return (res as List)
        .map((json) => Course.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Course?> getCourseById(String courseId) async {
    final res = await _client
        .from('courses')
        .select()
        .eq('id', courseId)
        .maybeSingle();

    if (res == null) return null;
    return Course.fromJson(res as Map<String, dynamic>);
  }

  // ───────────────── RATINGS ─────────────────

  Future<List<CourseRatingSummary>> getCourseRatings() async {
    final res = await _client.from('course_rating_summary').select();

    return (res as List)
        .map((json) =>
        CourseRatingSummary.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CourseRatingSummary?> getCourseRating(String courseId) async {
    final res = await _client
        .from('course_rating_summary')
        .select()
        .eq('course_id', courseId)
        .maybeSingle();

    if (res == null) return null;
    return CourseRatingSummary.fromJson(res as Map<String, dynamic>);
  }

  Future<void> submitCourseReview({
    required String userId,
    required String courseId,
    required int rating,
    String? reviewText,
  }) async {
    await _client.from('course_reviews').upsert({
      'user_id': userId,
      'course_id': courseId,
      'rating': rating,
      'review_text': reviewText,
    }, onConflict: 'course_id,user_id');
  }

  Future<List<CourseReview>> getCourseReviews(String courseId) async {
    final res = await _client
        .from('course_reviews')
        .select()
        .eq('course_id', courseId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((json) => CourseReview.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ───────────────── MODULES & VIDEOS ─────────────────

  Future<List<CourseModule>> getModulesForCourse(String courseId) async {
    final res = await _client
        .from('course_modules')
        .select()
        .eq('course_id', courseId)
        .order('order_index', ascending: true);

    return (res as List)
        .map((json) => CourseModule.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CourseModule?> getModuleById(String moduleId) async {
    final res = await _client
        .from('course_modules')
        .select()
        .eq('id', moduleId)
        .maybeSingle();

    if (res == null) return null;
    return CourseModule.fromJson(res as Map<String, dynamic>);
  }

  Future<List<ModuleVideo>> getVideosForModule(String moduleId) async {
    final res = await _client
        .from('module_videos')
        .select()
        .eq('module_id', moduleId)
        .order('order_index', ascending: true);

    return (res as List)
        .map((json) => ModuleVideo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ───────────────── ENROLLMENTS ─────────────────

  Future<CourseEnrollment> enrollInCourse({
    required String userId,
    required String courseId,
  }) async {
    final res = await _client
        .from('course_enrollments')
        .upsert(
      {
        'user_id': userId,
        'course_id': courseId,
      },
      onConflict: 'user_id,course_id',
    )
        .select()
        .single();

    return CourseEnrollment.fromJson(res as Map<String, dynamic>);
  }

  // ───────────────── PROGRESS ─────────────────

  Future<void> updateVideoProgress({
    required String userId,
    required String videoId,
    required int watchedSeconds,
    required bool completed,
  }) async {
    await _client.from('video_progress').upsert(
      {
        'user_id': userId,
        'video_id': videoId,
        'watched_seconds': watchedSeconds,
        'completed': completed,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,video_id',
    );
  }

  Future<List<CourseProgressSummary>> getCourseProgressForUser(
      String userId) async {
    final res = await _client
        .from('course_progress_summary')
        .select()
        .eq('user_id', userId);

    return (res as List)
        .map((json) =>
        CourseProgressSummary.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<ModuleProgressSummary>> getModuleProgressForUser(
      String userId) async {
    final res = await _client
        .from('module_progress_summary')
        .select()
        .eq('user_id', userId);

    return (res as List)
        .map((json) =>
        ModuleProgressSummary.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ───────────────── TRACK CONFIGS ─────────────────

  Future<List<TrackConfiguration>> getTrackConfigurationsForUser(
      String userId) async {
    final res = await _client
        .from('track_configurations')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((json) =>
        TrackConfiguration.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<TrackConfiguration?> getLatestTrackConfigurationForUser(
      String userId) async {
    final res = await _client
        .from('track_configurations')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (res == null) return null;
    return TrackConfiguration.fromJson(res as Map<String, dynamic>);
  }

  Future<List<ChassisSymptom>> getChassisSymptoms() async {
    final res = await _client
        .from('chassis_symptoms')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (res as List)
        .map((json) => ChassisSymptom.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Submit a user-reported symptom suggestion for admin review.
  /// The row lands in `user_symptom_reports` with status='pending' and does
  /// NOT appear in the live symptom list until an admin approves it.
  Future<void> createSymptomReport({
    required String title,
    required String description,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('You must be signed in to report a symptom.');
    }
    await _client.from('user_symptom_reports').insert({
      'user_id': userId,
      'title': title,
      'description': description,
    });
  }

  Future<List<ChassisIssueOption>> getIssueOptionsForSymptom(
      String symptomId) async {
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

  /// Submit a user-reported issue suggestion (scoped to a symptom) for admin
  /// review. The row lands in `user_issue_reports` with status='pending' and
  /// does NOT appear in the live issue list until an admin approves it.
  Future<void> createIssueReport({
    required String symptomId,
    required String title,
    required String description,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('You must be signed in to report an issue.');
    }
    await _client.from('user_issue_reports').insert({
      'user_id': userId,
      'symptom_id': symptomId,
      'title': title,
      'description': description,
    });
  }

  /// Fetch rankable recommendations from Supabase based on symptom and issues.
  /// Returns a list of AdjustmentRecommendation objects with id and priorityOrder.
  /// Does NOT depend on user_id (global recommendations).
  Future<List<AdjustmentRecommendation>> getRankableRecommendations({
    required String symptomId,
    required List<String> issueIds,
    String? presetId,
    TrackConfiguration? trackConfiguration,
  }) async {
    // Return empty if no issues provided
    if (issueIds.isEmpty) {
      debugPrint('[SUPABASE] No issue IDs provided, returning empty list.');
      return [];
    }

    debugPrint(
      '[SUPABASE] Fetching rankable recommendations: symptomId=$symptomId, issueIds=$issueIds, presetId=$presetId',
    );

    return _getRankableRecommendationsDirectQuery(
      symptomId: symptomId,
      issueIds: issueIds,
      presetId: presetId,
      trackConfiguration: trackConfiguration,
    );
  }

  /// Fallback query method if RPC is not available.
  /// Uses PostgREST filters to simulate the SQL logic.
  Future<List<AdjustmentRecommendation>> _getRankableRecommendationsDirectQuery({
    required String symptomId,
    required List<String> issueIds,
    String? presetId,
    TrackConfiguration? trackConfiguration,
  }) async {
    try {
      debugPrint(
        '[SUPABASE] Using direct query approach for symptomId=$symptomId',
      );

      final fullComboCode = _buildWorkbookComboCode(trackConfiguration);
      debugPrint('[SUPABASE] Full combo code filter: $fullComboCode');

      // Query chassis_adjustment_sets with related data
      final setsRes = await _client
          .from('chassis_adjustment_sets')
          .select()
          .eq('symptom_id', symptomId)
          .eq('is_active', true);

      if (setsRes.isEmpty) {
        debugPrint('[SUPABASE] No adjustment sets found for symptomId=$symptomId');
        return [];
      }

      final sets = setsRes as List;
      final recommendations = <AdjustmentRecommendation>[];
      final recommendationIds = <String>{};

      for (final setData in sets) {
        final setId = setData['id'] as String;
        final setTitle = (setData['title'] as String?) ?? '';

        if (!_matchesWorkbookCombination(setTitle, fullComboCode)) {
          continue;
        }

        // Check if this set has all required issue options
        final issueRes = await _client
            .from('chassis_adjustment_set_issue_options')
            .select('issue_option_id')
            .eq('set_id', setId)
            .inFilter('issue_option_id', issueIds);

        if ((issueRes as List).isEmpty) {
          continue; // Skip sets that don't have matching issues
        }

        // Check preset if provided
        if (presetId != null) {
          final presetRes = await _client
              .from('chassis_adjustment_set_track_presets')
              .select()
              .eq('set_id', setId)
              .eq('preset_id', presetId);

          if ((presetRes as List).isEmpty) {
            continue; // Skip if preset doesn't match
          }
        }

        // Fetch recommendations for this set
        final recRes = await _client
            .from('chassis_adjustment_set_recommendations')
            .select(
              'priority_order, adjustment_recommendations(id, title, details, category)',
            )
            .eq('set_id', setId)
            .order('priority_order', ascending: false);

        for (final recData in recRes as List) {
          final recDetail = recData['adjustment_recommendations'] as Map<String, dynamic>?;
          if (recDetail != null) {
            final recId = recDetail['id'] as String;
            // Avoid duplicates
            if (!recommendationIds.contains(recId)) {
              recommendationIds.add(recId);
              final rec = AdjustmentRecommendation.fromJson({
                ...recDetail,
                'priority_order': recData['priority_order'],
              });
              recommendations.add(rec);
            }
          }
        }
      }

      // Sort by priority_order descending
      recommendations.sort((a, b) {
        final aOrder = a.priorityOrder ?? 0;
        final bOrder = b.priorityOrder ?? 0;
        return bOrder.compareTo(aOrder);
      });

      debugPrint(
        '[SUPABASE] Successfully fetched ${recommendations.length} recommendations via direct query.',
      );
      for (final rec in recommendations) {
        debugPrint(
          '  - [Priority ${rec.priorityOrder}] ${rec.title} (id: ${rec.id})',
        );
      }

      return recommendations;
    } catch (e) {
      debugPrint('[SUPABASE] Direct query failed: $e');
      return [];
    }
  }

  bool _matchesWorkbookCombination(String setTitle, String? fullComboCode) {
    const prefix = 'CFG:';
    if (!setTitle.startsWith(prefix)) {
      return fullComboCode == null;
    }

    if (fullComboCode == null) {
      return false;
    }

    final encoded = setTitle.substring(prefix.length).split('|').first.trim();
    return encoded == fullComboCode;
  }

  String? _buildWorkbookComboCode(TrackConfiguration? config) {
    if (config == null) return null;

    final track = switch ((config.trackType ?? '').trim().toLowerCase()) {
      'oval' => 'Ova',
      'circuit/road course' => 'Cir',
      'circuit' => 'Cir',
      _ => null,
    };

    final surface = switch ((config.surfaceType ?? '').trim().toLowerCase()) {
      'tarmac/paved' => 'Tar',
      'tarmac' => 'Tar',
      'shale/dirt/grass' => 'Dir',
      'dirt' => 'Dir',
      'grass' => 'Dir',
      _ => null,
    };

    final engine = switch ((config.enginePosition ?? '').trim().toLowerCase()) {
      'front' => 'Fro',
      'mid' => 'Mid',
      'rear' => null,
      _ => null,
    };

    final aero = switch ((config.aerofoils ?? '').trim().toLowerCase()) {
      'yes' => 'Aer',
      'true' => 'Aer',
      'no' => 'NoA',
      'false' => 'NoA',
      _ => null,
    };

    final weather = switch ((config.weatherCondition ?? '').trim().toLowerCase()) {
      'dry' => 'Dry',
      'wet' => 'Wet',
      _ => null,
    };

    final drive = switch ((config.driveType ?? '').trim().toUpperCase()) {
      'RWD' => 'RWD',
      'FWD' => 'FWD',
      _ => null,
    };

    if ([track, surface, engine, aero, weather, drive].any((value) => value == null)) {
      return null;
    }

    return '$track\_$surface\_$engine\_$aero\_$weather\_$drive';
  }

  /// Fetches setup advice from `chassis_combination_advice`, matched on the
  /// 6 car/track config columns + the symptom string built from
  /// (selected issue title) + (symptom title).
  ///
  /// Returns rows mapped onto [AdjustmentRecommendation]:
  ///   adjustment   -> title
  ///   reason       -> details
  ///   setup_level  -> category   (Primary | Secondary)
  ///   priority     -> priorityOrder   (H=0, M=1, L=2 — lower = higher priority)
  ///
  /// Sorted by setup_level (Primary first) then priority (H, M, L).
  Future<List<AdjustmentRecommendation>> getCombinationAdvice({
    required String symptomTitle,
    required List<String> issueTitles,
    required TrackConfiguration? trackConfiguration,
  }) async {
    if (trackConfiguration == null) {
      debugPrint('[SUPABASE] No track configuration — cannot match advice.');
      return [];
    }

    final filters = _buildCombinationFilters(trackConfiguration);
    if (filters == null) {
      debugPrint(
        '[SUPABASE] Track configuration has unsupported/missing values '
        '(e.g. Rear engine) — no advice available.',
      );
      return [];
    }

    debugPrint(
      '[SUPABASE] Querying chassis_combination_advice with filters: $filters',
    );

    try {
      final rows = await _client
          .from('chassis_combination_advice')
          .select()
          .eq('track_type', filters['track_type'] as String)
          .eq('surface', filters['surface'] as String)
          .eq('engine_position', filters['engine_position'] as String)
          .eq('has_aero', filters['has_aero'] as bool)
          .eq('weather', filters['weather'] as String)
          .eq('drive_type', filters['drive_type'] as String);

      final allRows = (rows as List).cast<Map<String, dynamic>>();
      debugPrint(
        '[SUPABASE] chassis_combination_advice returned ${allRows.length} '
        'row(s) for this configuration (pre-symptom filter).',
      );

      if (allRows.isEmpty) return [];

      final symptomCandidates = _buildSymptomCandidates(
        symptomTitle: symptomTitle,
        issueTitles: issueTitles,
      );
      debugPrint('[SUPABASE] Symptom candidate strings: $symptomCandidates');

      final matched = allRows.where((row) {
        final s = (row['symptom'] as String?)?.trim().toLowerCase();
        if (s == null || s.isEmpty) return false;
        return symptomCandidates.contains(s);
      }).toList();

      debugPrint(
        '[SUPABASE] ${matched.length} row(s) matched symptom candidates.',
      );

      // Secondary (simpler, quick trackside tweaks) is shown first, then
      // Primary (bigger setup changes). Users try the easy adjustments first.
      const levelOrder = {'secondary': 0, 'primary': 1};
      const priorityOrder = {'h': 0, 'm': 1, 'l': 2};

      final recommendations = matched.map((row) {
        final priorityLetter =
            (row['priority'] as String?)?.trim().toUpperCase() ?? 'M';
        final order = priorityOrder[priorityLetter.toLowerCase()] ?? 1;
        return AdjustmentRecommendation.fromJson({
          'id': row['id'],
          'title': row['adjustment'],
          'details': row['reason'],
          'category': row['setup_level'],
          'priority_order': order,
        });
      }).toList();

      recommendations.sort((a, b) {
        final aLevel =
            levelOrder[(a.category ?? '').trim().toLowerCase()] ?? 99;
        final bLevel =
            levelOrder[(b.category ?? '').trim().toLowerCase()] ?? 99;
        if (aLevel != bLevel) return aLevel.compareTo(bLevel);
        final aPriority = a.priorityOrder ?? 99;
        final bPriority = b.priorityOrder ?? 99;
        return aPriority.compareTo(bPriority);
      });

      for (final rec in recommendations) {
        debugPrint(
          '  - [${rec.category} | P${rec.priorityOrder}] ${rec.title}',
        );
      }
      return recommendations;
    } catch (e) {
      debugPrint('[SUPABASE] chassis_combination_advice query failed: $e');
      return [];
    }
  }

  /// Maps the app's [TrackConfiguration] onto the column values used by
  /// `chassis_combination_advice`. Returns null if any required dimension
  /// is missing or unsupported (e.g. Rear engine, which the spreadsheet
  /// does not cover).
  Map<String, Object>? _buildCombinationFilters(TrackConfiguration config) {
    final track = switch ((config.trackType ?? '').trim().toLowerCase()) {
      'oval' => 'Oval',
      'circuit' || 'circuit/road course' => 'Circuit',
      _ => null,
    };

    final surface = switch ((config.surfaceType ?? '').trim().toLowerCase()) {
      'tarmac' || 'tarmac/paved' => 'Tarmac',
      'dirt' || 'shale/dirt/grass' || 'grass' => 'Dirt',
      _ => null,
    };

    final engine = switch ((config.enginePosition ?? '').trim().toLowerCase()) {
      'front' => 'Front',
      'mid' => 'Mid',
      _ => null, // 'rear' falls through — spreadsheet has no Rear coverage
    };

    final aero = switch ((config.aerofoils ?? '').trim().toLowerCase()) {
      'yes' || 'true' => true,
      'no' || 'false' => false,
      _ => null,
    };

    final weather = switch ((config.weatherCondition ?? '').trim().toLowerCase()) {
      'dry' => 'Dry',
      'wet' => 'Wet',
      _ => null,
    };

    final drive = switch ((config.driveType ?? '').trim().toUpperCase()) {
      'RWD' => 'RWD',
      'FWD' => 'FWD',
      _ => null,
    };

    if (track == null ||
        surface == null ||
        engine == null ||
        aero == null ||
        weather == null ||
        drive == null) {
      return null;
    }

    return {
      'track_type': track,
      'surface': surface,
      'engine_position': engine,
      'has_aero': aero,
      'weather': weather,
      'drive_type': drive,
    };
  }

  /// Builds the lowercase set of symptom strings to match against the
  /// `symptom` column. Covers both observed naming conventions in the
  /// spreadsheet, e.g. "Corner Entry Understeer" AND the shorter
  /// "Entry Understeer" / "Exit Oversteer" forms.
  Set<String> _buildSymptomCandidates({
    required String symptomTitle,
    required List<String> issueTitles,
  }) {
    final candidates = <String>{};
    final symptom = symptomTitle.trim();
    if (symptom.isEmpty) return candidates;

    candidates.add(symptom.toLowerCase());

    for (final raw in issueTitles) {
      final issue = raw.trim();
      if (issue.isEmpty) continue;
      candidates.add('$issue $symptom'.toLowerCase());
      final withoutCorner = issue
          .replaceAll(RegExp(r'\bcorner\b', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (withoutCorner.isNotEmpty && withoutCorner != issue) {
        candidates.add('$withoutCorner $symptom'.toLowerCase());
      }
    }
    return candidates;
  }

  Future<ChassisSession> createChassisSession({
    required String userId,
    required Map<String, dynamic> trackSnapshot,
    required Map<String, dynamic> symptomSnapshot,
    required List<Map<String, dynamic>> issuesSnapshot,
    required List<Map<String, dynamic>> recommendations,
  }) async {
    try {
      debugPrint('[SUPABASE] 💾 Creating new chassis session...');
      debugPrint('[SUPABASE] Data: userId=$userId, track=${trackSnapshot['track_type']}, symptom=${symptomSnapshot['title']}, issues=${issuesSnapshot.length}, recs=${recommendations.length}');
      
      final res = await _client
          .from('chassis_sessions')
          .insert({
        'user_id': userId,
        'track_snapshot': trackSnapshot,
        'symptom_snapshot': symptomSnapshot,
        'issues_snapshot': issuesSnapshot,
        'recommendations': recommendations,
      })
          .select()
          .single();

      final session = ChassisSession.fromJson(res as Map<String, dynamic>);
      debugPrint('[SUPABASE] ✅ Session created with ID: ${session.id}');
      debugPrint('[SUPABASE] Created at: ${session.createdAt}');
      
      return session;
    } catch (e) {
      debugPrint('[SUPABASE] ❌ Error creating session: $e');
      rethrow;
    }
  }

  Future<List<ChassisSession>> getChassisSessionsForUser(String userId) async {
    try {
      debugPrint('[SUPABASE] 📖 Fetching sessions for user: $userId');
      
      final res = await _client
          .from('chassis_sessions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      debugPrint('[SUPABASE] ✅ Query returned: ${(res as List).length} sessions');
      
      if ((res as List).isEmpty) {
        debugPrint('[SUPABASE] ℹ️  No sessions found for this user');
        return [];
      }

      final sessions = (res as List)
          .map((json) => ChassisSession.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('[SUPABASE] 📋 Sessions list:');
      for (var i = 0; i < sessions.length; i++) {
        debugPrint('[SUPABASE]   ${i + 1}. ID: ${sessions[i].id}, Created: ${sessions[i].createdAt}, Symptom: ${sessions[i].symptomSnapshot['title'] ?? 'Unknown'}');
      }

      return sessions;
    } catch (e) {
      debugPrint('[SUPABASE] ❌ Error fetching sessions: $e');
      return [];
    }
  }

  Future<List<AppNotification>> getNotificationsForUser(String userId) async {
    final res = await _client
        .from('user_notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _client
        .from('user_notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllNotificationsRead(String userId) async {
    await _client
        .from('user_notifications')
        .update({'is_read': true})
        .eq('user_id', userId);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _client
        .from('user_notifications')
        .delete()
        .eq('id', notificationId);
  }

  Future<void> clearNotificationsForUser(String userId) async {
    await _client
        .from('user_notifications')
        .delete()
        .eq('user_id', userId);
  }

  Future<HistoryNote?> getHistoryNote({
    required String userId,
    required String sourceType,
    required String sourceId,
  }) async {
    final res = await _client
        .from('history_notes')
        .select()
        .eq('user_id', userId)
        .eq('source_type', sourceType)
        .eq('source_id', sourceId)
        .maybeSingle();

    if (res == null) return null;
    return HistoryNote.fromJson(res as Map<String, dynamic>);
  }

  Future<void> upsertHistoryNote({
    required String userId,
    required String sourceType,
    required String sourceId,
    required String note,
  }) async {
    await _client.from('history_notes').upsert(
      {
        'user_id': userId,
        'source_type': sourceType,
        'source_id': sourceId,
        'note': note,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,source_type,source_id',
    );
  }

  Future<void> deleteHistoryNote({
    required String userId,
    required String sourceType,
    required String sourceId,
  }) async {
    await _client
        .from('history_notes')
        .delete()
        .eq('user_id', userId)
        .eq('source_type', sourceType)
        .eq('source_id', sourceId);
  }


  // ───────────────── ENROLLMENTS (EXTRA HELPERS) ─────────────────

  Future<List<CourseEnrollment>> getEnrollmentsForUser(String userId) async {
    final res = await _client
        .from('course_enrollments')
        .select()
        .eq('user_id', userId);

    return (res as List)
        .map((json) => CourseEnrollment.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Course>> getCoursesByIds(List<String> courseIds) async {
    if (courseIds.isEmpty) return [];
    final res = await _client
        .from('courses')
        .select()
        .inFilter('id', courseIds); // ✅ use inFilter instead of in_()

    return (res as List)
        .map((json) => Course.fromJson(json as Map<String, dynamic>))
        .toList();
  }


// ───────────────── VIDEO PROGRESS (LIST) ─────────────────

  Future<List<VideoProgress>> getVideoProgressForUser(String userId) async {
    final res = await _client
        .from('video_progress')
        .select()
        .eq('user_id', userId);

    return (res as List)
        .map((json) => VideoProgress.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<String> getSignedVideoUrl(String storagePath,
      {Duration expiresIn = const Duration(hours: 1)}) async {
    final signedUrl = await _client.storage
        .from('course-videos') // TODO: your exact bucket name
        .createSignedUrl(storagePath, expiresIn.inSeconds);
    return signedUrl;
  }

  // ───────────────── USER PROFILE HELPERS ─────────────────

  Future<AppUser?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return getUserById(user.id);
  }

  // ───────────────── DEVICE TOKENS ─────────────────

  Future<void> upsertDeviceToken({
    required String userId,
    required String token,
    String? platform,
  }) async {
    await _client.from('device_tokens').upsert({
      'user_id': userId,
      'token': token,
      'platform': platform,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'token');
  }

  Future<void> deleteDeviceToken({required String token}) async {
    await _client.from('device_tokens').delete().eq('token', token);
  }

  Future<List<DeviceToken>> getDeviceTokensForUser(String userId) async {
    final res = await _client.from('device_tokens').select().eq('user_id', userId);
    return (res as List)
        .map((json) => DeviceToken.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<AppUser> updateUserProfile({
    required String userId,
    String? fullName,
    String? email,
    String? phone,
    String? location,
    DateTime? dateOfBirth,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{};

    if (fullName != null) data['full_name'] = fullName;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    if (location != null) data['location'] = location;
    if (dateOfBirth != null) {
      // store as ISO or just date depending on your column type
      data['date_of_birth'] = dateOfBirth.toIso8601String();
    }
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;

    if (data.isEmpty) {
      // nothing to update – just return current profile
      final current = await getUserById(userId);
      if (current == null) {
        throw Exception('User not found');
      }
      return current;
    }

    final res = await _client
        .from('users')
        .update(data)
        .eq('id', userId)
        .select()
        .single();

    return AppUser.fromJson(res as Map<String, dynamic>);
  }

  Future<String> uploadProfileImage({
    required String userId,
    required File file,
  }) async {
    // ❗ Use the SAME bucket you’re using for thumbnails / videos
    const bucketName = 'user-avatars'; // <-- replace with your bucket name

    final ext = p.extension(file.path); // .jpg, .png, etc.
    final filePath =
        'avatars/$userId-${DateTime.now().millisecondsSinceEpoch}$ext';

    await _client.storage.from(bucketName).upload(
      filePath,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    final publicUrl =
    _client.storage.from(bucketName).getPublicUrl(filePath);

    return publicUrl;
  }


}
