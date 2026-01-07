import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/models/course.dart';
import 'package:motorsport/models/course_module.dart';
import 'package:motorsport/models/module_video.dart';
import 'package:motorsport/models/video_progress.dart';
import 'package:motorsport/view/screens/courses/video_player_Screen.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase/supabase_client_service.dart';

class ModuleVideosScreen extends StatefulWidget {
  final Course course;
  final CourseModule module;

  const ModuleVideosScreen({
    super.key,
    required this.course,
    required this.module,
  });

  @override
  State<ModuleVideosScreen> createState() => _ModuleVideosScreenState();
}

class _ModuleVideosScreenState extends State<ModuleVideosScreen> {
  final _service = SupabaseService.instance;

  bool _isLoading = true;
  String? _error;

  List<ModuleVideo> _videos = [];
  Map<String, VideoProgress> _videoProgress = {};

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

      final videos =
      await _service.getVideosForModule(widget.module.id);

      Map<String, VideoProgress> progressMap = {};
      if (userId != null) {
        final allVideoProgress =
        await _service.getVideoProgressForUser(userId);
        final videoIds = videos.map((v) => v.id).toSet();
        progressMap = {
          for (final p in allVideoProgress.where(
                (p) => videoIds.contains(p.videoId),
          ))
            p.videoId: p,
        };
      }

      setState(() {
        _videos = videos;
        _videoProgress = progressMap;
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
    final module = widget.module;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          module.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: kPrimaryColor,
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
            text: widget.course.title,
            size: 14,
            paddingBottom: 4,
            color: kTertiaryColor.withOpacity(0.8),
          ),
          MyText(
            text: module.title,
            size: 16,
            weight: FontWeight.bold,
            paddingBottom: 16,
          ),
          if (_videos.isEmpty)
             MyText(
              text: 'No videos added yet.',
              size: 14,
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                final video = _videos[index];
                final progress = _videoProgress[video.id];

                final durationMinutes =
                    (video.durationSeconds ?? 0) ~/ 60;

                final watchedSeconds =
                    progress?.watchedSeconds ?? 0;
                final totalSeconds =
                    video.durationSeconds ?? 1;
                final percent =
                (watchedSeconds / totalSeconds)
                    .clamp(0.0, 1.0);
                final completed = progress?.completed ?? false;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom:
                    index < _videos.length - 1 ? 10 : 0,
                  ),
                  child: InkWell(
                    onTap: () {
                      final userId = Supabase
                          .instance
                          .client
                          .auth
                          .currentUser
                          ?.id;
                      if (userId == null) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Please login to track progress'),
                          ),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerScreen(
                            video: video,
                            userId: userId,
                          ),
                        ),
                      ).then((_) {
                        // Refresh progress when coming back
                        _loadData();
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kQuaternaryColor,
                        borderRadius: BorderRadius.circular(10),
                        border:
                        Border.all(color: kBorderColor2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              color: kSecondaryColor
                                  .withOpacity(0.2),
                              borderRadius:
                              BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: kSecondaryColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                MyText(
                                  text: video.title,
                                  size: 14,
                                  weight: FontWeight.w600,
                                  paddingBottom: 4,
                                ),
                                MyText(
                                  text:
                                  '${durationMinutes} min',
                                  size: 12,
                                  color: kTertiaryColor
                                      .withOpacity(0.8),
                                  paddingBottom: 6,
                                ),
                                LinearPercentIndicator(
                                  lineHeight: 6,
                                  percent: percent,
                                  padding: EdgeInsets.zero,
                                  backgroundColor:
                                  kTertiaryColor,
                                  progressColor: kGreenColor,
                                  barRadius:
                                  const Radius.circular(4),
                                ),
                                const SizedBox(height: 4),
                                MyText(
                                  text: completed
                                      ? 'Completed'
                                      : 'Tap to continue',
                                  size: 11,
                                  color: completed
                                      ? kGreenColor
                                      : kTertiaryColor
                                      .withOpacity(0.9),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
