import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/models/course.dart';
import 'package:motorsport/models/course_progress_summary.dart';
import 'package:motorsport/models/course_rating_summary.dart';
import 'package:motorsport/models/course_enrollment.dart';
import 'package:motorsport/view/screens/courses/course_detail_screen.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase/supabase_client_service.dart';

class AllCourses extends StatefulWidget {
  const AllCourses({super.key});

  @override
  State<AllCourses> createState() => _AllCoursesState();
}

class _AllCoursesState extends State<AllCourses> {
  final _service = SupabaseService.instance;

  final List<String> _filters = [
    'All',
    'Tire Management',
    'Advanced Braking',
    'Arts & Humanities',
  ];

  int _selectedFilterIndex = 0;
  bool _isLoading = true;
  String? _error;

  List<Course> _courses = [];
  Map<String, CourseRatingSummary> _ratings = {};
  Map<String, CourseProgressSummary> _progress = {};

  /// ✅ Which courses the current user is enrolled in
  Set<String> _enrolledCourseIds = {};

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

      // All published courses
      final courses = await _service.getPublishedCourses();

      // Rating summaries
      final ratingsList = await _service.getCourseRatings();

      // Progress + enrollments
      List<CourseProgressSummary> progressList = [];
      List<CourseEnrollment> enrollments = [];

      if (userId != null) {
        progressList = await _service.getCourseProgressForUser(userId);
        enrollments = await _service.getEnrollmentsForUser(userId);
      }

      setState(() {
        _courses = courses;

        _ratings = {
          for (final r in ratingsList) r.courseId: r,
        };

        _progress = {
          for (final p in progressList) p.courseId: p,
        };

        _enrolledCourseIds = {
          for (final e in enrollments) e.courseId,
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

  List<Course> get _filteredCourses {
    if (_selectedFilterIndex == 0) return _courses; // "All"

    final filter = _filters[_selectedFilterIndex].toLowerCase();
    return _courses.where((c) {
      final category = (c.category ?? '').toLowerCase();
      final title = c.title.toLowerCase();
      return category.contains(filter) || title.contains(filter);
    }).toList();
  }

  Future<void> _handleGetCourseTap(Course course) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to get the course')),
      );
      return;
    }

    try {
      // ✅ Enroll in this course (upsert, safe if already enrolled)
      await _service.enrollInCourse(
        userId: userId,
        courseId: course.id,
      );

      // ✅ Update local state so button disappears immediately
      setState(() {
        _enrolledCourseIds.add(course.id);
      });

      // ✅ Navigate to course detail
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CourseDetailScreen(course: course),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to enroll: $e')),
      );
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

    final visibleCourses = _filteredCourses;

    return ListView(
      shrinkWrap: true,
      padding: AppSizes.VERTICAL,
      physics: const BouncingScrollPhysics(),
      children: [
        MyText(
          paddingLeft: 20,
          text: 'All Available courses',
          size: 18,
          paddingBottom: 12,
          weight: FontWeight.bold,
        ),
        SizedBox(
          height: 30,
          child: ListView.separated(
            separatorBuilder: (context, index) => const SizedBox(width: 6),
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            physics: const BouncingScrollPhysics(),
            padding: AppSizes.HORIZONTAL,
            itemBuilder: (context, index) {
              final isSelected = _selectedFilterIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilterIndex = index;
                  });
                },
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? kSecondaryColor : kQuaternaryColor,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Center(
                    child: MyText(
                      text: _filters[index],
                      size: 13,
                      color: isSelected ? kPrimaryColor : kTertiaryColor,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (visibleCourses.isEmpty)
          Padding(
            padding: AppSizes.HORIZONTAL,
            child: MyText(
              text: 'No courses found.',
              size: 14,
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            padding: AppSizes.HORIZONTAL,
            physics: const BouncingScrollPhysics(),
            itemCount: visibleCourses.length,
            itemBuilder: (context, index) {
              final course = visibleCourses[index];
              final rating = _ratings[course.id];
              final progress = _progress[course.id];

              final percent =
              ((progress?.progressPercentage ?? 0) / 100).clamp(0.0, 1.0);
              final completedText =
                  '${(progress?.progressPercentage ?? 0).toStringAsFixed(0)}% completed';

              final isEnrolled = _enrolledCourseIds.contains(course.id);

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < visibleCourses.length - 1 ? 12 : 0,
                ),
                child: _LearningHubTile(
                  title: course.title,
                  duration: _formatDuration(course.durationMinutes),
                  imageUrl: course.thumbnailUrl,
                  percent: percent.toDouble(),
                  completedText: completedText,
                  rating: rating?.avgRating,
                  totalReviews: rating?.totalReviews,
                  isEnrolled: isEnrolled,
                  onTapPrimary: () {
                    if (isEnrolled) {
                      // Already enrolled → just open details
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseDetailScreen(course: course),
                        ),
                      );
                    } else {
                      // Not enrolled → enroll + open details
                      _handleGetCourseTap(course);
                    }
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
  final String? imageUrl; // from Supabase
  final double percent;
  final String completedText;
  final double? rating;
  final int? totalReviews;
  final bool isEnrolled;
  final VoidCallback onTapPrimary;

  const _LearningHubTile({
    Key? key,
    required this.title,
    required this.duration,
    required this.imageUrl,
    required this.percent,
    required this.completedText,
    required this.onTapPrimary,
    required this.isEnrolled,
    this.rating,
    this.totalReviews,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayRating = rating?.toStringAsFixed(1) ?? '--';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: kQuaternaryColor,
        border: Border.all(color: kBorderColor2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(imageUrl!, height: 120, fit: BoxFit.cover)
                : Image.asset(
              Assets.imagesAdvanced, // fallback asset
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          MyText(
            paddingTop: 6,
            text: title,
            size: 14,
            paddingBottom: 4,
            weight: FontWeight.bold,
          ),
          MyText(
            text: duration,
            size: 12,
            lineHeight: 1.5,
            color: kTertiaryColor.withValues(alpha: 0.8),
            paddingBottom: 6,
          ),
          Row(
            children: [
              Image.asset(Assets.imagesStar, height: 14),
              const SizedBox(width: 4),
              MyText(
                text: displayRating,
                size: 12,
                weight: FontWeight.w500,
              ),
              if (totalReviews != null) ...[
                const SizedBox(width: 4),
                MyText(
                  text: '(${totalReviews.toString()})',
                  size: 11,
                  color: kTertiaryColor.withOpacity(0.7),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (percent > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearPercentIndicator(
                  lineHeight: 6,
                  percent: percent,
                  padding: EdgeInsets.zero,
                  backgroundColor: kTertiaryColor,
                  progressColor: kGreenColor,
                  barRadius: const Radius.circular(4),
                ),
                MyText(
                  paddingTop: 4,
                  textAlign: TextAlign.end,
                  text: completedText,
                  size: 11,
                  color: kTertiaryColor,
                ),
              ],
            ),
          const SizedBox(height: 8),
          MyButton(
            height: 30,
            textSize: 12,
            radius: 50.0,
            buttonText: isEnrolled ? 'View course' : 'Get the course',
            onTap: onTapPrimary,
          ),
        ],
      ),
    );
  }
}
