import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _showOverlay = true;
  bool _wasLandscape = false;
  Timer? _overlayTimer;

  static const _portrait = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ];
  static const _landscape = [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  @override
  void initState() {
    super.initState();
    // The rest of the app is portrait; lessons can turn sideways for full screen.
    SystemChrome.setPreferredOrientations([..._portrait, ..._landscape]);
    _initPlayer();
  }

  /// Full-screen button: turn to landscape (or back), then let the phone rotate freely again.
  Future<void> _toggleFullScreen(bool landscape) async {
    await SystemChrome.setPreferredOrientations(
      landscape ? _portrait : _landscape,
    );
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      SystemChrome.setPreferredOrientations([..._portrait, ..._landscape]);
    }
  }

  void _pokeOverlaySoon() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) _pokeOverlay();
  });

  void _pokeOverlay() {
    _overlayTimer?.cancel();
    setState(() => _showOverlay = true);
    if (_controller?.value.isPlaying ?? false) {
      _overlayTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showOverlay = false);
      });
    }
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
    _overlayTimer?.cancel();
    SystemChrome.setPreferredOrientations(_portrait);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _progressTimer?.cancel();
    _syncProgress(); // final sync (fire-and-forget)
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final ready =
        !_isInitializing &&
        _controller != null &&
        _controller!.value.isInitialized;

    if (landscape != _wasLandscape) {
      // Only when the phone turns: the player rebuilds many times a second.
      _wasLandscape = landscape;
      SystemChrome.setEnabledSystemUIMode(
        landscape ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      );
      if (landscape) _pokeOverlaySoon();
    }
    if (landscape && ready) return _buildFullScreen();

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
          : ListView(
              children: [
                AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio == 0
                      ? 16 / 9
                      : _controller!.value.aspectRatio,
                  child: Stack(
                    children: [
                      Positioned.fill(child: VideoPlayer(_controller!)),
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: _RoundIcon(
                          icon: Icons.fullscreen_rounded,
                          tooltip: 'Full screen',
                          onTap: () => _toggleFullScreen(false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildControls(),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        text: video.title,
                        size: 16,
                        weight: FontWeight.bold,
                        paddingBottom: 4,
                      ),
                      _SupportingContentCard(
                        supportingText:
                            video.supportingText?.trim().isNotEmpty ?? false
                            ? video.supportingText!.trim()
                            : 'This space is reserved for post-purchase support content such as written guidance, notes, or reference material below the lesson video.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// Sideways: the video fills the screen, with controls that fade after a few seconds.
  Widget _buildFullScreen() {
    final value = _controller!.value;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_showOverlay) {
            _overlayTimer?.cancel();
            setState(() => _showOverlay = false);
          } else {
            _pokeOverlay();
          }
        },
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: value.aspectRatio == 0
                    ? 16 / 9
                    : value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
            IgnorePointer(
              ignoring: !_showOverlay,
              child: AnimatedOpacity(
                opacity: _showOverlay ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x99000000),
                        Color(0x00000000),
                        Color(0xB3000000),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _RoundIcon(
                              icon: Icons.fullscreen_exit_rounded,
                              tooltip: 'Exit full screen',
                              onTap: () => _toggleFullScreen(true),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.video.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        _buildControls(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    final value = _controller!.value;
    final isPlaying = value.isPlaying;
    final position = value.position;
    final duration = value.duration;

    final totalSeconds = duration.inSeconds == 0
        ? 1
        : duration.inSeconds.toDouble();
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
                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              ),
              onPressed: () {
                setState(() {
                  if (isPlaying) {
                    _controller!.pause();
                  } else {
                    _controller!.play();
                  }
                });
                _pokeOverlay();
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

class _SupportingContentCard extends StatelessWidget {
  const _SupportingContentCard({required this.supportingText});

  final String supportingText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kQuaternaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            text: 'Supporting Content',
            size: 14,
            weight: FontWeight.bold,
            paddingBottom: 6,
          ),
          MyText(
            text: supportingText,
            size: 12,
            lineHeight: 1.5,
            color: kTertiaryColor.withValues(alpha: 0.9),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0x80000000),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}
