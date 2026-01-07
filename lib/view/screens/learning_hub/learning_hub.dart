import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/models/course.dart';
import 'package:motorsport/models/course_enrollment.dart';
import 'package:motorsport/models/course_module.dart';
import 'package:motorsport/models/course_progress_summary.dart';
import 'package:motorsport/models/module_progress_summary.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase/supabase_client_service.dart';
import '../courses/course_detail_screen.dart';
import '../courses/courses.dart';
import '../courses/module_video_screen.dart';

class LearningHub extends StatefulWidget {
  const LearningHub({super.key});

  @override
  State<LearningHub> createState() => _LearningHubState();
}

class _LearningHubState extends State<LearningHub> {
  final _service = SupabaseService.instance;

  bool _isLoading = true;
  String? _error;

  /// Enrolled courses for the logged-in user
  List<Course> _enrolledCourses = [];

  /// Overall course progress (by courseId)
  Map<String, CourseProgressSummary> _courseProgress = {};

  /// Modules for each enrolled course (courseId -> List<CourseModule>)
  Map<String, List<CourseModule>> _courseModulesByCourseId = {};

  /// Module progress (by moduleId)
  Map<String, ModuleProgressSummary> _moduleProgressByModuleId = {};

  /// Course selected in the "Modules" section
  String? _selectedCourseId;

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
          _enrolledCourses = [];
          _selectedCourseId = null;
        });
        return;
      }

      // 1) Enrollments
      final List<CourseEnrollment> enrollments =
      await _service.getEnrollmentsForUser(userId);

      if (enrollments.isEmpty) {
        setState(() {
          _enrolledCourses = [];
          _selectedCourseId = null;
        });
        return;
      }

      // 2) Courses for enrollments
      final courseIds = enrollments.map((e) => e.courseId).toList();
      final courses = await _service.getCoursesByIds(courseIds);

      // 3) Course-level progress
      final courseProgressList =
      await _service.getCourseProgressForUser(userId);

      // 4) Module-level progress
      final moduleProgressList =
      await _service.getModuleProgressForUser(userId);

      // 5) Fetch modules for each course
      final Map<String, List<CourseModule>> modulesByCourseId = {};
      for (final course in courses) {
        final modules = await _service.getModulesForCourse(course.id);
        modulesByCourseId[course.id] = modules;
      }

      setState(() {
        _enrolledCourses = courses;

        _courseProgress = {
          for (final p in courseProgressList) p.courseId: p,
        };

        _moduleProgressByModuleId = {
          for (final mp in moduleProgressList) mp.moduleId: mp,
        };

        _courseModulesByCourseId = modulesByCourseId;

        // Default selected course for modules section
        _selectedCourseId = courses.isNotEmpty ? courses.first.id : null;
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
    return Scaffold(
      appBar: simpleAppBar(
        title: 'Motorsport University - Learning Hub',
        haveLeading: false,
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
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: const BouncingScrollPhysics(),
        children: [
          MyText(
            text: 'Learning Hub',
            size: 18,
            paddingBottom: 8,
            weight: FontWeight.bold,
          ),
          MyText(
            text:
            'Your one-stop destination for skill-building, expert resources, and self-paced learning — anytime, anywhere.',
            size: 12,
            paddingBottom: 25,
          ),

          // Hero card
          Container(
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage(Assets.imagesRaceCraftBg),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(12),
              color: kQuaternaryColor,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: 'Elevate Your Race Craft!',
                  size: 18,
                  weight: FontWeight.bold,
                  paddingBottom: 6,
                ),
                MyText(
                  text:
                  'Unlock advanced techniques and optimize your vehicle\'s performance with our premium courses.',
                  size: 12,
                  lineHeight: 1.5,
                  color: kTertiaryColor,
                  paddingBottom: 16,
                ),
                SizedBox(
                  width: 170,
                  child: MyButton(
                    buttonText: 'Explore Courses Now',
                    height: 30,
                    textSize: 12,
                    textColor: kTertiaryColor,
                    bgColor: const Color(0xff636AE8),
                    radius: 8,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const Courses(),
                      ));
                    },
                  ),
                ),
              ],
            ),
          ),

          // My Learning Module (enrolled courses)
          MyText(
            paddingTop: 16,
            text: 'My Learning Module',
            size: 18,
            paddingBottom: 12,
            weight: FontWeight.bold,
          ),
          if (_enrolledCourses.isEmpty)
            MyText(
              text:
              'You are not enrolled in any course yet. Start by exploring the courses.',
              size: 14,
            )
          else
            ListView.builder(
              shrinkWrap: true,
              padding: AppSizes.ZERO,
              physics: const BouncingScrollPhysics(),
              itemCount: _enrolledCourses.length,
              itemBuilder: (context, index) {
                final course = _enrolledCourses[index];
                final progress = _courseProgress[course.id];

                final percent =
                ((progress?.progressPercentage ?? 0) / 100)
                    .clamp(0.0, 1.0);
                final completedText =
                    '${(progress?.progressPercentage ?? 0).toStringAsFixed(0)}% completed';

                return Padding(
                  padding: EdgeInsets.only(
                    bottom:
                    index < _enrolledCourses.length - 1 ? 12 : 0,
                  ),
                  child: _LearningHubTile(
                    title: course.title,
                    duration:
                    _formatDuration(course.durationMinutes),
                    imageUrl: course.thumbnailUrl,
                    percent: percent.toDouble(),
                    completedText: completedText,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CourseDetailScreen(course: course),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

          // Modules of selected course
          const SizedBox(height: 16),
          if (_selectedCourseId != null &&
              _courseModulesByCourseId[_selectedCourseId] != null &&
              _courseModulesByCourseId[_selectedCourseId]!
                  .isNotEmpty)
            _buildModulesSection()
          else
            MyText(
              paddingTop: 8,
              text:
              'No modules available yet. Start a course to see its modules here.',
              size: 14,
            ),
        ],
      ),
    );
  }

  Widget _buildModulesSection() {
    final selectedCourse = _enrolledCourses
        .firstWhere((c) => c.id == _selectedCourseId, orElse: () => _enrolledCourses.first);

    final modules = _courseModulesByCourseId[selectedCourse.id] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + course dropdown
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: MyText(
                paddingTop: 8,
                text: 'Modules in ${selectedCourse.title}',
                size: 16,
                lineHeight: 1.5,
                paddingBottom: 12,
                weight: FontWeight.bold,
              ),
            ),
            DropdownButton<String>(
              value: _selectedCourseId,
              dropdownColor: kPrimaryColor,
              underline: const SizedBox(),
              items: _enrolledCourses
                  .map(
                    (c) => DropdownMenuItem<String>(
                  value: c.id,
                  child: MyText(
                    text: c.title,
                    size: 12,
                  ),
                ),
              )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCourseId = value;
                });
              },
            ),
          ],
        ),

        ListView.builder(
          shrinkWrap: true,
          padding: AppSizes.ZERO,
          physics: const BouncingScrollPhysics(),
          itemCount: modules.length,
          itemBuilder: (context, index) {
            final module = modules[index];
            final mp = _moduleProgressByModuleId[module.id];
            final percent =
            ((mp?.progressPercentage ?? 0) / 100).clamp(0.0, 1.0);
            final completed = (mp?.progressPercentage ?? 0) >= 99.0;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index < modules.length - 1 ? 12 : 0,
              ),
              child: _LectureTile(
                title: module.title,
                duration: 'Module ${module.orderIndex}',
                percent: percent.toDouble(),
                completed: completed,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ModuleVideosScreen(
                        course: selectedCourse,
                        module: module,
                      ),
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
    if (hrs > 0) return '${hrs}hrs ${mins}mins';
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

class _LectureTile extends StatelessWidget {
  final String title;
  final String duration;
  final double percent;
  final bool completed;
  final VoidCallback? onTap;

  const _LectureTile({
    Key? key,
    required this.title,
    required this.duration,
    required this.percent,
    this.completed = false,
    this.onTap,
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
            Column(
              children: [
                Image.asset(
                  Assets.imagesSelected,
                  height: 24,
                  color: completed ? kGreenColor : kSecondaryColor,
                ),
                MyText(text: duration, size: 12, paddingTop: 5),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MyText(
                text: title,
                size: 14,
                paddingRight: 8,
                weight: FontWeight.bold,
              ),
            ),
            SizedBox(
              width: 65,
              child: LinearPercentIndicator(
                lineHeight: 6,
                percent: percent,
                padding: EdgeInsets.zero,
                backgroundColor: kTertiaryColor,
                progressColor: completed ? kGreenColor : kSecondaryColor,
                barRadius: const Radius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
