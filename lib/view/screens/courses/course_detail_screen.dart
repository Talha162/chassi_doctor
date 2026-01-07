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

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final _service = SupabaseService.instance;

  bool _isLoading = true;
  String? _error;

  List<CourseModule> _modules = [];
  Map<String, ModuleProgressSummary> _moduleProgress = {};

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
      final modules =
      await _service.getModulesForCourse(widget.course.id);

      Map<String, ModuleProgressSummary> progressMap = {};

      if (userId != null) {
        final allModuleProgress =
        await _service.getModuleProgressForUser(userId);
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
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ REVIEW BUTTON HANDLER
  void _openReviewDialog() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

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

        // ✅ REVIEW BUTTON IN APP BAR
        actions: [
          IconButton(
            icon: const Icon(Icons.rate_review),
            onPressed: _openReviewDialog,
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
          ),
          if (course.description != null)
            MyText(
              text: course.description!,
              size: 12,
              lineHeight: 1.5,
              color: kTertiaryColor.withOpacity(0.9),
              paddingBottom: 8,
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
                      MyButton(
                        buttonText: 'View',
                        height: 30,
                        textSize: 12,
                        radius: 50,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ModuleVideosScreen(
                                    course: course,
                                    module: module,
                                  ),
                            ),
                          );
                        },
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
