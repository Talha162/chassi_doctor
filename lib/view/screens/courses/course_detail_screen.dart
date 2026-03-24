import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/models/course.dart';
import 'package:motorsport/models/course_module.dart';
import 'package:motorsport/models/module_progress_summary.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase/supabase_client_service.dart';
import '../../widget/course_review_dialog.dart';
import 'module_video_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  final bool initiallyEnrolled;

  const CourseDetailScreen({
    super.key,
    required this.course,
    this.initiallyEnrolled = false,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final _service = SupabaseService.instance;

  bool _isLoading = true;
  bool _isPurchasing = false;
  bool _isEnrolled = false;
  String? _error;

  List<CourseModule> _modules = [];
  Map<String, ModuleProgressSummary> _moduleProgress = {};

  @override
  void initState() {
    super.initState();
    _isEnrolled = widget.initiallyEnrolled;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userId = Supabase.instance.client.auth.currentUser?.id;
      final modules = await _service.getModulesForCourse(widget.course.id);

      Map<String, ModuleProgressSummary> progressMap = {};
      var enrolled = _isEnrolled;

      if (userId != null) {
        final enrollments = await _service.getEnrollmentsForUser(userId);
        enrolled = enrollments.any((e) => e.courseId == widget.course.id);
        final allModuleProgress = await _service.getModuleProgressForUser(
          userId,
        );
        final moduleIds = modules.map((m) => m.id).toSet();

        progressMap = {
          for (final p in allModuleProgress.where(
            (p) => moduleIds.contains(p.moduleId),
          ))
            p.moduleId: p,
        };
      }

      setState(() {
        _modules = modules;
        _moduleProgress = progressMap;
        _isEnrolled = enrolled;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unlockCourse() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to unlock this course.')),
      );
      return;
    }

    try {
      setState(() => _isPurchasing = true);
      await _service.enrollInCourse(userId: userId, courseId: widget.course.id);
      if (!mounted) return;
      setState(() => _isEnrolled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course unlocked successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to unlock course: $e')));
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  // ✅ REVIEW BUTTON HANDLER
  void _openReviewDialog() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || !_isEnrolled) return;

    showDialog(
      context: context,
      builder: (_) => CourseReviewDialog(
        courseId: widget.course.id,
        userId: userId,
        onSuccess: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Review submitted successfully')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          course.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: kPrimaryColor,

        actions: [
          IconButton(
            icon: const Icon(Icons.rate_review),
            onPressed: _isEnrolled ? _openReviewDialog : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: MyText(
                text: 'Error: $_error',
                size: 14,
                color: Colors.red,
              ),
            )
          : ListView(
              padding: AppSizes.DEFAULT,
              physics: const BouncingScrollPhysics(),
              children: [
                MyText(
                  text: course.title,
                  size: 18,
                  weight: FontWeight.bold,
                  paddingBottom: 8,
                ),
                if (course.description != null)
                  MyText(
                    text: course.description!,
                    size: 12,
                    lineHeight: 1.5,
                    color: kTertiaryColor.withValues(alpha: 0.9),
                    paddingBottom: 8,
                  ),
                _PurchaseStatusCard(
                  title: _isEnrolled ? 'Purchased Course' : 'Before Purchase',
                  body: _isEnrolled
                      ? (course.postPurchaseText?.trim().isNotEmpty ?? false)
                            ? course.postPurchaseText!.trim()
                            : 'You have unlocked this course. Videos and any supporting text shown below are now available to this user.'
                      : (course.prePurchaseText?.trim().isNotEmpty ?? false)
                      ? course.prePurchaseText!.trim()
                      : 'This course is part of Motorsport University. Unlock it to access the full video lessons and any post-purchase supporting content.',
                  accentColor: _isEnrolled ? kGreenColor : kSecondaryColor,
                ),
                const SizedBox(height: 12),
                if (!_isEnrolled)
                  MyButton(
                    buttonText: _isPurchasing
                        ? 'Unlocking...'
                        : 'Unlock Course',
                    onTap: _isPurchasing ? null : _unlockCourse,
                  ),

                const SizedBox(height: 16),

                MyText(
                  text: 'Modules',
                  size: 16,
                  weight: FontWeight.bold,
                  paddingBottom: 12,
                ),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _modules.length,
                  itemBuilder: (context, index) {
                    final module = _modules[index];
                    final progress = _moduleProgress[module.id];
                    final progressText = progress == null
                        ? 'Locked until unlocked'
                        : '${progress.progressPercentage.toStringAsFixed(0)}% completed';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kQuaternaryColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kBorderColor2),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: MyText(
                                text: module.title,
                                size: 14,
                                weight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (_isEnrolled)
                              MyText(
                                text: progressText,
                                size: 11,
                                color: kTertiaryColor.withValues(alpha: 0.8),
                              ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 92,
                              child: MyButton(
                                buttonText: _isEnrolled ? 'View' : 'Locked',
                                height: 36,
                                textSize: 12,
                                radius: 50,
                                onTap: !_isEnrolled
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ModuleVideosScreen(
                                              course: course,
                                              module: module,
                                            ),
                                          ),
                                        );
                                      },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _PurchaseStatusCard extends StatelessWidget {
  const _PurchaseStatusCard({
    required this.title,
    required this.body,
    required this.accentColor,
  });

  final String title;
  final String body;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kQuaternaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            text: title,
            size: 14,
            weight: FontWeight.bold,
            color: accentColor,
            paddingBottom: 6,
          ),
          MyText(
            text: body,
            size: 12,
            lineHeight: 1.5,
            color: kTertiaryColor.withValues(alpha: 0.9),
          ),
        ],
      ),
    );
  }
}
