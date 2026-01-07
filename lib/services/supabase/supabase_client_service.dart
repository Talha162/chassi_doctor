import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/app_user.dart';
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

  Future<ChassisSymptom> createChassisSymptom({
    required String title,
    required String description,
  }) async {
    final userId = _client.auth.currentUser?.id;
    final res = await _client
        .from('chassis_symptoms')
        .insert({
      'title': title,
      'description': description,
      'created_by': userId,
    })
        .select()
        .single();

    return ChassisSymptom.fromJson(res as Map<String, dynamic>);
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

  Future<ChassisIssueOption> createIssueOption({
    required String symptomId,
    required String title,
    required String description,
  }) async {
    final userId = _client.auth.currentUser?.id;
    final res = await _client
        .from('chassis_issue_options')
        .insert({
      'symptom_id': symptomId,
      'title': title,
      'description': description,
      'created_by': userId,
    })
        .select()
        .single();

    return ChassisIssueOption.fromJson(res as Map<String, dynamic>);
  }

  Future<ChassisSession> createChassisSession({
    required String userId,
    required Map<String, dynamic> trackSnapshot,
    required Map<String, dynamic> symptomSnapshot,
    required List<Map<String, dynamic>> issuesSnapshot,
    required List<Map<String, dynamic>> recommendations,
  }) async {
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

    return ChassisSession.fromJson(res as Map<String, dynamic>);
  }

  Future<List<ChassisSession>> getChassisSessionsForUser(String userId) async {
    final res = await _client
        .from('chassis_sessions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((json) => ChassisSession.fromJson(json as Map<String, dynamic>))
        .toList();
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
