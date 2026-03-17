import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/models/course.dart';
import 'package:motorsport/models/course_enrollment.dart';
import 'package:motorsport/models/course_progress_summary.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase/supabase_client_service.dart';
import 'course_detail_screen.dart';

class MyCourses extends StatefulWidget {
  const MyCourses({super.key});

  @override
  State<MyCourses> createState() => _MyCoursesState();
}

class _MyCoursesState extends State<MyCourses> {
  final _service = SupabaseService.instance;

  bool _isLoading = true;
  String? _error;

  List<Course> _courses = [];
  Map<String, CourseProgressSummary> _progress = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _courses = [];
        });
        return;
      }

      final List<CourseEnrollment> enrollments =
      await _service.getEnrollmentsForUser(userId);

      if (enrollments.isEmpty) {
        setState(() {
          _courses = [];
        });
        return;
      }

      final courseIds = enrollments.map((e) => e.courseId).toList();
      final courses = await _service.getCoursesByIds(courseIds);

      final progressList =
      await _service.getCourseProgressForUser(userId);

      setState(() {
        _courses = courses;
        _progress = {
          for (final p in progressList) p.courseId: p,
        };
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: MyText(
          text: 'Error: $_error',
          size: 14,
          color: Colors.red,
        ),
      );
    }

    if (_courses.isEmpty) {
      return ListView(
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: const BouncingScrollPhysics(),
        children:  [
          MyText(
            text: 'My Courses',
            size: 18,
            paddingBottom: 12,
            weight: FontWeight.bold,
          ),
          MyText(
            text: 'You are not enrolled in any course yet.',
            size: 14,
          ),
        ],
      );
    }

    return ListView(
      shrinkWrap: true,
      padding: AppSizes.DEFAULT,
      physics: const BouncingScrollPhysics(),
      children: [
         MyText(
          text: 'My Courses',
          size: 18,
          paddingBottom: 12,
          weight: FontWeight.bold,
        ),
        ListView.builder(
          shrinkWrap: true,
          padding: AppSizes.ZERO,
          physics: const BouncingScrollPhysics(),
          itemCount: _courses.length,
          itemBuilder: (context, index) {
            final course = _courses[index];
            final progress = _progress[course.id];

            final percent =
            ((progress?.progressPercentage ?? 0) / 100).clamp(0.0, 1.0);
            final completedText =
                '${(progress?.progressPercentage ?? 0).toStringAsFixed(0)}% completed';

            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _courses.length - 1 ? 12 : 0,
              ),
              child: _LearningHubTile(
                title: course.title,
                duration: _formatDuration(course.durationMinutes),
                imageUrl: course.thumbnailUrl,
                percent: percent.toDouble(),
                completedText: completedText,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CourseDetailScreen(course: course),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDuration(int? minutes) {
    if (minutes == null || minutes <= 0) return '—';
    final hrs = minutes ~/ 60;
    final mins = minutes % 60;
    if (hrs > 0) {
      return '${hrs}hrs ${mins}mins';
    }
    return '${mins}mins';
  }
}

class _LearningHubTile extends StatelessWidget {
  final String title;
  final String duration;
  final String? imageUrl;
  final double percent;
  final String completedText;
  final VoidCallback onTap;

  const _LearningHubTile({
    Key? key,
    required this.title,
    required this.duration,
    required this.imageUrl,
    required this.percent,
    required this.completedText,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kQuaternaryColor,
          border: Border.all(color: kBorderColor2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                imageUrl!,
                height: 70,
                width: 70,
                fit: BoxFit.cover,
              )
                  : Image.asset(
                Assets.imagesAdvanced,
                height: 70,
                width: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MyText(
                    text: title,
                    size: 14,
                    paddingBottom: 4,
                    weight: FontWeight.bold,
                  ),
                  MyText(text: duration, size: 12, paddingBottom: 6),
                  LinearPercentIndicator(
                    lineHeight: 6,
                    percent: percent,
                    padding: EdgeInsets.zero,
                    backgroundColor: kTertiaryColor,
                    progressColor: kGreenColor,
                    barRadius: const Radius.circular(4),
                  ),
                  MyText(
                    paddingTop: 6,
                    textAlign: TextAlign.end,
                    text: completedText,
                    size: 12,
                    color: kTertiaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
