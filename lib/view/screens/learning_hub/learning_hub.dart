import 'package:motorsport/utils/motion.dart';
import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/models/course.dart';
import 'package:motorsport/models/course_module.dart';
import 'package:motorsport/models/course_progress_summary.dart';
import 'package:motorsport/models/module_progress_summary.dart';
import 'package:motorsport/services/subscription_service.dart';
import 'package:motorsport/view/screens/bottom_nav_bar/bottom_nav_bar.dart';
import 'package:motorsport/view/widget/modern_ui.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase/supabase_client_service.dart';
import '../courses/course_detail_screen.dart';
import '../courses/courses.dart';
import '../courses/module_video_screen.dart';
import '../subscriptions/paywall_screen.dart';

class LearningHub extends StatefulWidget {
  const LearningHub({
    super.key,
    this.showBottomNav = false,
    this.showBackButton = true,
  });

  final bool showBottomNav;
  final bool showBackButton;

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

  Future<void> _refresh() async {
    await SubscriptionService.instance.refresh();
    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        // Skeletons only on the first load; refreshes keep the page visible.
        _isLoading = _enrolledCourses.isEmpty && _error == null;
        _error = null;
      });

      final userId = Supabase.instance.client.auth.currentUser?.id;
      final hasSubscription =
          SubscriptionService.instance.hasActiveSubscription;
      if (userId == null || !hasSubscription) {
        setState(() {
          _enrolledCourses = [];
          _selectedCourseId = null;
        });
        return;
      }

      final courses = await _service.getPublishedCourses();
      if (courses.isEmpty) {
        setState(() {
          _enrolledCourses = [];
          _selectedCourseId = null;
        });
        return;
      }

      // 3) Course-level progress
      final courseProgressList = await _service.getCourseProgressForUser(
        userId,
      );

      // 4) Module-level progress
      final moduleProgressList = await _service.getModuleProgressForUser(
        userId,
      );

      // 5) Fetch modules for each course
      final Map<String, List<CourseModule>> modulesByCourseId = {};
      for (final course in courses) {
        final modules = await _service.getModulesForCourse(course.id);
        modulesByCourseId[course.id] = modules;
      }

      setState(() {
        _enrolledCourses = courses;

        _courseProgress = {for (final p in courseProgressList) p.courseId: p};

        _moduleProgressByModuleId = {
          for (final mp in moduleProgressList) mp.moduleId: mp,
        };

        _courseModulesByCourseId = modulesByCourseId;

        // Default selected course for modules section
        _selectedCourseId = courses.isNotEmpty ? courses.first.id : null;
      });
    } catch (e) {
      debugPrint('Failed to load Learning Hub: $e');
      if (mounted) {
        setState(() {
          _error = 'Learning Hub could not be loaded. Please try again.';
        });
      }
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
    return AppPageScaffold(
      title: 'Motorsport University',
      showBack: widget.showBackButton,
      bottomNavigationBar: widget.showBottomNav
          ? const ChildScreenBottomNav(selectedIndex: 1)
          : null,
      body: _isLoading
          ? const SkeletonCardList(count: 3, thumbSize: 72, header: true)
          : _error != null
          ? AppRefresh(
              onRefresh: _refresh,
              child: ScrollableEmptyState(
                child: EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Couldn\'t load your courses',
                  message: _error,
                  actionText: 'Try again',
                  onAction: _loadData,
                ),
              ),
            )
          : AppRefresh(
              onRefresh: _refresh,
              child: ListView(
                padding: AppSizes.DEFAULT,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  const SizedBox(height: 14),
                  MyText(
                    text:
                        'Your dedicated learning space for courses, supporting content, and self-paced motorsport education.',
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
                          text: 'Learn Inside Motorsport University',
                          size: 18,
                          weight: FontWeight.bold,
                          paddingBottom: 6,
                        ),
                        MyText(
                          text:
                              SubscriptionService.instance.hasActiveSubscription
                              ? 'Your All Access subscription is active, so every current course and module is ready to use here.'
                              : 'Start a 3-day free trial to unlock every current course, video lesson, and supporting learning material.',
                          size: 12,
                          lineHeight: 1.5,
                          color: kTertiaryColor,
                          paddingBottom: 16,
                        ),
                        SizedBox(
                          width: 170,
                          child: MyButton(
                            buttonText:
                                SubscriptionService
                                    .instance
                                    .hasActiveSubscription
                                ? 'Explore Courses'
                                : 'Start Free Trial',
                            height: 30,
                            textSize: 12,
                            textColor: kTertiaryColor,
                            bgColor: const Color(0xff636AE8),
                            radius: 8,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SubscriptionService
                                          .instance
                                          .hasActiveSubscription
                                      ? const Courses(showBackButton: true)
                                      : const PaywallScreen(
                                          sourceLabel: 'Learning Hub Hero',
                                        ),
                                ),
                              ).then((_) => _loadData());
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // My Learning Module (enrolled courses)
                  MyText(
                    paddingTop: 16,
                    text: 'My Courses',
                    size: 18,
                    paddingBottom: 12,
                    weight: FontWeight.bold,
                  ),
                  if (_enrolledCourses.isEmpty)
                    EmptyState(
                      compact: true,
                      icon: Icons.lock_open_rounded,
                      title: 'Unlock every course',
                      message:
                          'Start your All Access subscription to see your courses and progress here.',
                      actionText: 'See Subscription Plans',
                      onAction: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaywallScreen(
                              sourceLabel: 'Learning Hub',
                            ),
                          ),
                        ).then((_) => _loadData());
                      },
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      padding: AppSizes.ZERO,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _enrolledCourses.length,
                      itemBuilder: (context, index) => FadeInUp(
                        delay: staggerDelay(index),
                        child: Builder(
                          builder: (context) {
                            final course = _enrolledCourses[index];
                            final progress = _courseProgress[course.id];

                            final percent =
                                ((progress?.progressPercentage ?? 0) / 100)
                                    .clamp(0.0, 1.0);
                            final completedText =
                                '${(progress?.progressPercentage ?? 0).toStringAsFixed(0)}% completed';

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index < _enrolledCourses.length - 1
                                    ? 12
                                    : 0,
                              ),
                              child: _LearningHubTile(
                                title: course.title,
                                duration: _formatDuration(
                                  course.durationMinutes,
                                ),
                                imageUrl: course.thumbnailUrl,
                                percent: percent.toDouble(),
                                completedText: completedText,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CourseDetailScreen(
                                        course: course,
                                        initiallyEnrolled: true,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // Modules of selected course
                  const SizedBox(height: 16),
                  if (_selectedCourseId != null &&
                      _courseModulesByCourseId[_selectedCourseId] != null &&
                      _courseModulesByCourseId[_selectedCourseId]!.isNotEmpty)
                    _buildModulesSection()
                  else if (_enrolledCourses.isNotEmpty)
                    const EmptyState(
                      compact: true,
                      icon: Icons.video_library_outlined,
                      title: 'No modules yet',
                      message: 'Modules for this course will appear here.',
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildModulesSection() {
    final selectedCourse = _enrolledCourses.firstWhere(
      (c) => c.id == _selectedCourseId,
      orElse: () => _enrolledCourses.first,
    );

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
            if (_enrolledCourses.length > 1)
              _CoursePickerButton(
                onTap: () async {
                  final picked = await showOptionSheet<Course>(
                    context,
                    title: 'Choose a course',
                    options: _enrolledCourses,
                    selected: selectedCourse,
                    labelOf: (c) => c.title,
                    subtitleOf: (c) {
                      final p = _courseProgress[c.id]?.progressPercentage ?? 0;
                      return '${p.toStringAsFixed(0)}% completed';
                    },
                  );
                  if (picked != null && mounted) {
                    setState(() => _selectedCourseId = picked.id);
                  }
                },
              ),
          ],
        ),

        ListView.builder(
          shrinkWrap: true,
          padding: AppSizes.ZERO,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: modules.length,
          itemBuilder: (context, index) => FadeInUp(
            delay: staggerDelay(index),
            child: Builder(
              builder: (context) {
                final module = modules[index];
                final mp = _moduleProgressByModuleId[module.id];
                final percent = ((mp?.progressPercentage ?? 0) / 100).clamp(
                  0.0,
                  1.0,
                );
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
          ),
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

/// "Change course" pill that opens the course picker sheet.
class _CoursePickerButton extends StatelessWidget {
  const _CoursePickerButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: Material(
        color: kQuaternaryColor,
        shape: StadiumBorder(
          side: BorderSide(color: kSecondaryColor.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MyText(
                  text: 'Change',
                  size: 12,
                  weight: FontWeight.w600,
                  color: kSecondaryColor,
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.unfold_more_rounded,
                  size: 16,
                  color: kSecondaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
