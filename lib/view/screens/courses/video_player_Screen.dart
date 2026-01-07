import 'dart:async';

import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/models/module_video.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:video_player/video_player.dart';

import '../../../services/supabase/supabase_client_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final ModuleVideo video;
  final String userId;

  const VideoPlayerScreen({
    super.key,
    required this.video,
    required this.userId,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final _service = SupabaseService.instance;

  VideoPlayerController? _controller;
  bool _isInitializing = true;
  bool _isCompletedMarked = false;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final storagePath = widget.video.videoPath;

      // 🔐 Your existing signed URL helper
      final String videoUrl = await _service.getSignedVideoUrl(storagePath);
      debugPrint('SIGNED VIDEO URL => $videoUrl');

      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      await _controller!.initialize();

      // 🔥 Make UI reactive: slider & time will update as video plays
      _controller!.addListener(() {
        if (!mounted) return;
        if (!_controller!.value.isInitialized) return;
        setState(() {});
      });

      _controller!.play();

      // Only for backend progress sync (every 5 seconds)
      _progressTimer = Timer.periodic(
        const Duration(seconds: 5),
            (_) => _syncProgress(),
      );
    } catch (e) {
      debugPrint('Error initializing video: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _syncProgress() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final position = _controller!.value.position;
    final duration = _controller!.value.duration;
    if (duration.inSeconds == 0) return;

    final watchedSeconds = position.inSeconds;
    final totalSeconds = duration.inSeconds;
    final completed = watchedSeconds >= (totalSeconds * 0.95);

    await _service.updateVideoProgress(
      userId: widget.userId,
      videoId: widget.video.id,
      watchedSeconds: watchedSeconds,
      completed: completed,
    );

    if (completed && !_isCompletedMarked) {
      _isCompletedMarked = true;
    }
  }

  /// Smooth relative seek (e.g. -10s / +10s)
  Future<void> _seekRelative(int seconds) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final current = _controller!.value.position;
    final duration = _controller!.value.duration;

    var target = current + Duration(seconds: seconds);

    if (target < Duration.zero) target = Duration.zero;
    if (target > duration) target = duration;

    await _controller!.seekTo(target);
    await _syncProgress();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _syncProgress(); // final sync (fire-and-forget)
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          video.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: kPrimaryColor,
      ),
      body: _isInitializing || _controller == null
          ? const Center(child: CircularProgressIndicator())
          : !_controller!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio == 0
                ? 16 / 9
                : _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
          const SizedBox(height: 12),
          _buildControls(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: MyText(
              text: video.title,
              size: 16,
              weight: FontWeight.bold,
              paddingBottom: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final value = _controller!.value;
    final isPlaying = value.isPlaying;
    final position = value.position;
    final duration = value.duration;

    final totalSeconds =
    duration.inSeconds == 0 ? 1 : duration.inSeconds.toDouble();
    final currentSeconds = position.inSeconds.toDouble();
    final sliderValue = (currentSeconds / totalSeconds).clamp(0.0, 1.0);

    return Column(
      children: [
        // Progress slider
        Slider(
          value: sliderValue,
          onChanged: (v) async {
            final target = Duration(seconds: (v * totalSeconds).toInt());
            await _controller!.seekTo(target);
            await _syncProgress();
          },
        ),

        // Time labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText(
                text: _formatDuration(position),
                size: 12,
                color: Colors.white70,
              ),
              MyText(
                text: _formatDuration(duration),
                size: 12,
                color: Colors.white70,
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Playback controls: back 10s, play/pause, forward 10s
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 32,
              color: kSecondaryColor,
              icon: const Icon(Icons.replay_10),
              onPressed: () => _seekRelative(-10),
            ),
            IconButton(
              iconSize: 40,
              color: kSecondaryColor,
              icon: Icon(
                isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
              ),
              onPressed: () {
                setState(() {
                  if (isPlaying) {
                    _controller!.pause();
                  } else {
                    _controller!.play();
                  }
                });
              },
            ),
            IconButton(
              iconSize: 32,
              color: kSecondaryColor,
              icon: const Icon(Icons.forward_10),
              onPressed: () => _seekRelative(10),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
