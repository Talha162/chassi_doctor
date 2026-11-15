import 'package:motorsport/utils/app_error.dart';
import 'package:motorsport/utils/app_snackbar.dart';
import 'package:motorsport/view/widget/report_dialog.dart';
import 'package:motorsport/utils/motion.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/models/adjustment_recommendation.dart';
import 'package:motorsport/controller/settings/saved_setup_history_controller.dart';
import 'package:motorsport/models/chassis_issue_option.dart';
import 'package:motorsport/models/chassis_session.dart';
import 'package:motorsport/view/screens/bottom_nav_bar/bottom_nav_bar.dart';
import 'package:motorsport/view/screens/home/save_session_sheet.dart';
import 'package:motorsport/view/widget/app_dialog.dart';
import 'package:motorsport/config/theme/theme_controller.dart';
import 'package:motorsport/view/screens/geometry/setup_sheets.dart' show formatSetupDate;
import 'package:motorsport/models/chassis_symptom.dart';
import 'package:motorsport/models/track_configuration.dart';
import 'package:motorsport/services/supabase/supabase_client_service.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SetupRecommendation extends StatefulWidget {
  const SetupRecommendation({super.key, required this.symptom});

  final ChassisSymptom symptom;

  @override
  State<SetupRecommendation> createState() => _SetupRecommendationState();
}

class _SetupRecommendationState extends State<SetupRecommendation> {
  static const String _trackCircuitNameKey = 'track_circuit_name';
  static const String _enginePositionKey = 'engine_position';
  static const String _aerofoilsKey = 'aerofoils';
  static const String _driveTypeKey = 'drive_type';

  final SupabaseService _supabaseService = SupabaseService.instance;

  bool _isLoadingIssues = true;
  bool _isRequesting = false;
  List<ChassisIssueOption> _issues = [];
  Set<String> _selectedIssueIds = {};
  TrackConfiguration? _trackConfiguration;
  List<AdjustmentRecommendation> _recommendations = [];
  List<ChassisIssueOption> _lastIssues = [];
  ChassisSession? _savedSession;
  static const Set<String> _stageIssues = {
    'corner entry',
    'mid corner',
    'corner exit',
  };

  @override
  void initState() {
    super.initState();
    _loadIssues();
    _loadTrackConfiguration();
  }

  Future<void> _loadIssues() async {
    try {
      setState(() => _isLoadingIssues = true);
      final issues = await _supabaseService.getIssueOptionsForSymptom(
        widget.symptom.id,
      );
      if (!mounted) return;
      setState(() {
        _issues = issues;
      });
    } catch (e) {
      debugPrint('Failed to load issues in SetupRecommendation: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingIssues = false);
      }
    }
  }

  Future<void> _loadTrackConfiguration() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final latest = await _supabaseService.getLatestTrackConfigurationForUser(
        userId,
      );
      final prefs = await SharedPreferences.getInstance();
      final merged = latest == null
          ? null
          : TrackConfiguration(
              id: latest.id,
              userId: latest.userId,
              createdAt: latest.createdAt,
              trackType: latest.trackType,
              circuitName:
                  latest.circuitName ??
                  prefs.getString(_trackCircuitNameKey)?.trim(),
              surfaceType: latest.surfaceType,
              weatherCondition: latest.weatherCondition,
              enginePosition:
                  latest.enginePosition ??
                  prefs.getString(_enginePositionKey)?.trim(),
              aerofoils:
                  latest.aerofoils ?? prefs.getString(_aerofoilsKey)?.trim(),
              driveType:
                  latest.driveType ?? prefs.getString(_driveTypeKey)?.trim(),
              presetId: latest.presetId,
              extraSetup: latest.extraSetup,
            );
      if (!mounted) return;
      setState(() {
        _trackConfiguration = merged;
      });
    } catch (e) {
      debugPrint('Failed to load track configuration: $e');
    }
  }

  Future<void> _showAddIssueDialog() async {
    final sent = await showReportDialog(
      context: context,
      heading: 'Report a New Issue for ${widget.symptom.title}',
      titleLabel: 'Issue',
      titleHint: 'e.g. Only on the brakes into the hairpin',
      descriptionHint: 'Describe what you are experiencing',
      onSubmit: (title, description) => _supabaseService.createIssueReport(
        symptomId: widget.symptom.id,
        title: title,
        description: description,
      ),
    );
    if (sent == true) {
      showSuccessSnackbar(
        "Thanks! We'll review your issue and add it to the app.",
        title: 'Report sent',
      );
    }
  }

  void _toggleIssue(String issueId) {
    setState(() {
      if (_selectedIssueIds.contains(issueId)) {
        _selectedIssueIds.remove(issueId);
      } else {
        _selectedIssueIds.add(issueId);
      }
    });
  }

  List<ChassisIssueOption> get _visibleIssues {
    final symptom = widget.symptom.title.trim().toLowerCase();
    if (symptom != 'understeer' && symptom != 'oversteer') {
      return _issues;
    }

    final filtered = _issues.where((issue) {
      final normalized = issue.title.trim().toLowerCase();
      return _stageIssues.contains(normalized);
    }).toList();

    // Show stages in the order a driver goes through a corner:
    // Entry → Mid → Exit (the DB returns them newest-first).
    const stageOrder = ['corner entry', 'mid corner', 'corner exit'];
    filtered.sort(
      (a, b) => stageOrder
          .indexOf(a.title.trim().toLowerCase())
          .compareTo(stageOrder.indexOf(b.title.trim().toLowerCase())),
    );

    return filtered;
  }

  Future<void> _fetchRecommendations() async {
    final visibleIds = _visibleIssues.map((issue) => issue.id).toSet();
    final selectedIssueIds = _selectedIssueIds
        .where((id) => visibleIds.contains(id))
        .toSet();

    if (selectedIssueIds.isEmpty) {
      showInfoSnackbar(
        'Select where in the corner you feel it: entry, mid or exit.',
        title: 'Pick at least one',
      );
      return;
    }

    setState(() => _isRequesting = true);
    try {
      final selectedIssues = _issues
          .where((issue) => selectedIssueIds.contains(issue.id))
          .toList();

      debugPrint(
        '\n═══════════════════════════════════════════════════════════',
      );
      debugPrint(
        '[SETUP] Fetching recommendations for symptom: ${widget.symptom.title}',
      );
      debugPrint('[SETUP] Selected ${selectedIssues.length} issues:');
      for (final issue in selectedIssues) {
        debugPrint('  - ${issue.title}');
      }
      if (_trackConfiguration != null) {
        debugPrint(
          '[SETUP] Track config: ${_trackConfiguration!.trackType}/${_trackConfiguration!.surfaceType}/${_trackConfiguration!.weatherCondition}',
        );
        if (_trackConfiguration!.presetId != null) {
          debugPrint('[SETUP] Preset ID: ${_trackConfiguration!.presetId}');
        }
      }
      debugPrint(
        '═══════════════════════════════════════════════════════════\n',
      );

      final candidates = await _supabaseService.getCombinationAdvice(
        symptomTitle: widget.symptom.title,
        issueTitles: selectedIssues.map((i) => i.title).toList(),
        trackConfiguration: _trackConfiguration,
      );

      if (!mounted) return;

      if (candidates.isEmpty) {
        debugPrint('[SETUP] ❌ No advice found in chassis_combination_advice.');
        final engine = (_trackConfiguration?.enginePosition ?? '')
            .trim()
            .toLowerCase();
        if (_trackConfiguration == null) {
          showInfoSnackbar(
            'Set up your car and track first so we can match advice to it.',
            title: 'Car setup needed',
          );
        } else if (engine == 'rear') {
          showInfoSnackbar(
            "We don't have advice for rear-engine cars yet. It's coming soon.",
            title: 'No advice yet',
          );
        } else {
          showInfoSnackbar(
            "We don't have advice for this exact car and track combination yet.",
            title: 'No advice yet',
          );
        }
        setState(() => _isRequesting = false);
        return;
      }

      debugPrint(
        '\n[SETUP] Loaded ${candidates.length} advice row(s) from chassis_combination_advice.',
      );

      final finalRecommendations = candidates;

      if (!mounted) return;

      debugPrint('\n[SETUP] ═════ FINAL RECOMMENDATIONS (from Supabase) ═════');
      for (int i = 0; i < finalRecommendations.length; i++) {
        final rec = finalRecommendations[i];
        debugPrint('  ${i + 1}. ${rec.title}');
        debugPrint('     Details: ${rec.details}');
        debugPrint('     Category: ${rec.category ?? 'N/A'}');
        debugPrint('     ID: ${rec.id}');
      }
      debugPrint(
        '═════════════════════════════════════════════════════════════\n',
      );

      // Step C: Update UI and save session
      // Nothing is saved yet: the driver chooses "Save to session" below.
      setState(() {
        _recommendations = finalRecommendations;
        _lastIssues = selectedIssues;
        _savedSession = null;
      });
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(
          friendlyError(e),
          title: "Couldn't load recommendations",
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  /// Builds the session snapshot from what's on screen and saves it with the
  /// name, track, date and notes from the "Save to session" sheet.
  Future<ChassisSession> _createSession(SessionDetails details) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Your session has expired. Please log in again.');
    }

    final trackConfig = _trackConfiguration ??
        await _supabaseService.getLatestTrackConfigurationForUser(userId);
    final prefs = await SharedPreferences.getInstance();
    String? orSaved(String? value, String key) {
      if (value != null && value.trim().isNotEmpty) return value;
      final saved = prefs.getString(key)?.trim();
      return (saved == null || saved.isEmpty) ? value : saved;
    }

    final trackSnapshot = <String, dynamic>{
      'track_type': trackConfig?.trackType,
      'circuit_name': details.trackName.isNotEmpty
          ? details.trackName
          : orSaved(trackConfig?.circuitName, _trackCircuitNameKey),
      'surface_type': trackConfig?.surfaceType,
      'weather_condition': trackConfig?.weatherCondition,
      'engine_position': orSaved(trackConfig?.enginePosition, _enginePositionKey),
      'aerofoils': orSaved(trackConfig?.aerofoils, _aerofoilsKey),
      'drive_type': orSaved(trackConfig?.driveType, _driveTypeKey),
    };

    final symptomSnapshot = {
      'id': widget.symptom.id,
      'title': widget.symptom.title,
      'description': widget.symptom.description,
    };

    final issuesSnapshot = _lastIssues
        .map(
          (issue) => {
            'id': issue.id,
            'title': issue.title,
            'description': issue.description,
          },
        )
        .toList();

    final recommendationsSnapshot = _recommendations
        .map(
          (rec) => {
            'title': rec.title,
            'details': rec.details,
            'category': rec.category,
            'id': rec.id,
            'priority_order': rec.priorityOrder,
          },
        )
        .toList();

    final session = await _supabaseService.createChassisSession(
      userId: userId,
      trackSnapshot: trackSnapshot,
      symptomSnapshot: symptomSnapshot,
      issuesSnapshot: issuesSnapshot,
      recommendations: recommendationsSnapshot,
      sessionName: details.name,
      eventDate: details.eventDate,
    );

    if (details.notes.isNotEmpty) {
      try {
        await _supabaseService.upsertHistoryNote(
          userId: userId,
          sourceType: 'session',
          sourceId: session.id,
          note: details.notes,
        );
      } catch (e) {
        // The session itself is saved; the note can be added from History.
        debugPrint('[SETUP] Note not saved: $e');
      }
    }
    debugPrint('[SETUP] Session saved: ${session.id} (${details.name})');
    return session;
  }

  Future<void> _openSaveSheet() async {
    if (_recommendations.isEmpty || _savedSession != null) return;
    if (Supabase.instance.client.auth.currentUser == null) {
      showInfoSnackbar('Log in to save this session to your history.');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    // Only prefill a real track name, not the track type ("Circuit/Road Course").
    final trackType = _trackConfiguration?.trackType?.trim().toLowerCase();
    String? usable(String? v) {
      final t = v?.trim();
      if (t == null || t.isEmpty || t.toLowerCase() == trackType) return null;
      return t;
    }
    final initialTrack = usable(_trackConfiguration?.circuitName) ??
        usable(prefs.getString(_trackCircuitNameKey));
    const stageOrder = ['corner entry', 'mid corner', 'corner exit'];
    int rank(ChassisIssueOption i) {
      final r = stageOrder.indexOf(i.title.trim().toLowerCase());
      return r < 0 ? stageOrder.length : r;
    }
    final stages = ([..._lastIssues]..sort((a, b) => rank(a).compareTo(rank(b))))
        .map((i) => i.title)
        .join(', ');
    final count = _recommendations.length;
    final summary = [
      widget.symptom.title,
      if (stages.isNotEmpty) stages,
      '$count adjustment${count == 1 ? '' : 's'}',
    ].join(' · ');

    final saved = await showSaveSessionSheet(
      context,
      initialTrack: initialTrack,
      summary: summary,
      onSave: _createSession,
    );
    if (saved == null || !mounted) return;
    setState(() => _savedSession = saved);
    if (Get.isRegistered<SavedSetupHistoryController>()) {
      Get.find<SavedSetupHistoryController>().fetchSavedSetups();
    }
    showSuccessSnackbar(
      'Find it any time in the History tab.',
      title: 'Saved “${saved.sessionName ?? 'session'}”',
    );
  }

  bool get _hasUnsavedResults =>
      _recommendations.isNotEmpty && _savedSession == null;

  Future<void> _confirmLeave() async {
    var leave = false;
    var save = false;
    await showAppDialog(
      title: 'Save this session?',
      message:
          "These recommendations aren't saved yet. Save them to History so "
          'you can look back at what you changed.',
      icon: Icons.bookmark_add_outlined,
      primaryLabel: 'Save to session',
      onPrimary: () => save = true,
      secondaryLabel: 'Leave without saving',
      onSecondary: () => leave = true,
      barrierDismissible: true,
    );
    if (!mounted) return;
    if (leave) {
      setState(() => _recommendations = []);
      Navigator.of(context).pop();
    } else if (save) {
      _openSaveSheet();
    }
  }

  void _goToHistory() => Get.offAll(() => const BottomNavBar(initialIndex: 2));

  void _goHome() => Get.offAll(() => const BottomNavBar());

  String _issueImageForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'understeer':
        return Assets.imagesUndersteer;
      case 'oversteer':
        return Assets.imagesOverSteer;
      case 'poor braking':
        return Assets.imagesPoorBraking;
      case 'instability':
        return Assets.imagesInstability;
      case 'uneven tire wear':
        return Assets.imagesUnevenTyre;
      case 'rough ride':
        return Assets.imagesRoughRide;
      case 'lack of grip':
        return Assets.imagesLack;
      case 'slow turn-in':
        return Assets.imagesSlowTurnIn;
      case 'poor traction':
        return Assets.imagesPoorTraction;
      case 'braking instability':
        return Assets.imagesBrakingInstability;
      default:
        return Assets.imagesSymptons;
    }
  }

  IconData? _stageIconForTitle(String title) {
    switch (title.trim().toLowerCase()) {
      case 'corner entry':
        return Icons.login_rounded;
      case 'mid corner':
        return Icons.rotate_right_rounded;
      case 'corner exit':
        return Icons.logout_rounded;
      default:
        return null;
    }
  }

  Widget _issueVisual(ChassisIssueOption issue) {
    final stageIcon = _stageIconForTitle(issue.title);
    if (stageIcon != null) {
      return Icon(stageIcon, size: 54, color: kSecondaryColor);
    }

    final fallback = Image.asset(_issueImageForTitle(issue.title), height: 60);
    if (issue.imageUrl == null || issue.imageUrl!.trim().isEmpty) {
      return fallback;
    }

    return Image.network(
      issue.imageUrl!,
      height: 60,
      errorBuilder: (_, __, ___) => fallback,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return fallback;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleIssueIds = _visibleIssues.map((issue) => issue.id).toSet();
    final selectedVisibleCount = _selectedIssueIds
        .where((id) => visibleIssueIds.contains(id))
        .length;

    return PopScope(
      canPop: !_hasUnsavedResults,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
      appBar: simpleAppBar(title: 'Chassis Doctor'),
      body: ListView(
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: BouncingScrollPhysics(),
        children: [
          Center(
            child: CircleAvatar(
              radius: 30,
              backgroundColor: kBorderColor2,
              child: ClipOval(
                child: Image.asset(Assets.mainlogo, fit: BoxFit.contain),
              ),
            ),
          ),
          SizedBox(height: 12),
          MyText(
            text: widget.symptom.title,
            size: 18,
            paddingBottom: 8,
            weight: FontWeight.bold,
          ),
          MyText(
            text: widget.symptom.description.isEmpty
                ? "Select the issues that best describe what's happening."
                : widget.symptom.description,
            size: 12,
            paddingBottom: 25,
          ),
          if (_isLoadingIssues)
            Center(child: CircularProgressIndicator(color: kSecondaryColor))
          else if (_visibleIssues.isEmpty)
            MyText(
              text:
                  'No corner-stage options found. Please use: Corner Entry, Mid Corner, Corner Exit.',
              size: 12,
              color: kSecondaryColor,
              paddingBottom: 12,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.symptom.title.trim().toLowerCase() == 'understeer')
                  MyText(
                    text:
                        'Understeer stage: choose from Corner Entry, Mid Corner, or Corner Exit.',
                    size: 12,
                    color: kSecondaryColor,
                    paddingBottom: 8,
                  ),
                MyText(
                  text: 'Selected: $selectedVisibleCount',
                  size: 12,
                  color: kSecondaryColor,
                  paddingBottom: 10,
                ),
                GridView.builder(
                  shrinkWrap: true,
                  padding: AppSizes.ZERO,
                  physics: BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 130,
                  ),
                  itemCount: _visibleIssues.length,
                  itemBuilder: (context, index) => FadeInUp(
                    delay: staggerDelay(index),
                    child: Builder(
                      builder: (context) {
                        final issue = _visibleIssues[index];
                        final isSelected = _selectedIssueIds.contains(issue.id);
                        return GestureDetector(
                          onTap: () => _toggleIssue(issue.id),
                          child: Container(
                            width: Get.width,
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? kSecondaryColor
                                    : kBorderColor2,
                                width: isSelected ? 2 : 1,
                              ),
                              color: kQuaternaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 60,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [_issueVisual(issue)],
                                  ),
                                ),
                                MyText(
                                  paddingTop: 10,
                                  text: issue.title,
                                  size: 14,
                                  weight: FontWeight.w600,
                                  maxLines: 1,
                                  textOverflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          SizedBox(height: 20),
          OutlinedButton(
            onPressed: _showAddIssueDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: kSecondaryColor,
              side: BorderSide(color: kSecondaryColor),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Report New Issue'),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isRequesting ? null : _fetchRecommendations,
            style: ElevatedButton.styleFrom(
              backgroundColor: kSecondaryColor,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isRequesting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Recommend Adjustments'),
          ),
          SizedBox(height: 20),
          MyText(
            text: 'Recommended Adjustment',
            size: 18,
            paddingBottom: 8,
            weight: FontWeight.bold,
          ),
          if (_recommendations.isEmpty)
            MyText(
              text:
                  'Tap "Recommend Adjustments" to get suggestions based on your selected issues and track setup.',
              size: 12,
              color: kSecondaryColor,
              paddingBottom: 8,
            )
          else
            ListView.builder(
              shrinkWrap: true,
              padding: AppSizes.ZERO,
              physics: BouncingScrollPhysics(),
              itemCount: _recommendations.length,
              itemBuilder: (context, index) => FadeInUp(
                delay: staggerDelay(index),
                child: Builder(
                  builder: (context) {
                    final recommendation = _recommendations[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < _recommendations.length - 1 ? 10 : 0,
                      ),
                      child: _AdjustmentTile(
                        title: recommendation.title,
                        subtitle: recommendation.details,
                        trailing:
                            (recommendation.category == null ||
                                recommendation.category!.trim().isEmpty)
                            ? null
                            : '${recommendation.category!.trim()} Setup',
                      ),
                    );
                  },
                ),
              ),
            ),
          if (_recommendations.isNotEmpty) ...[
            const SizedBox(height: 18),
            FadeInUp(
              delay: staggerDelay(_recommendations.length),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.97, end: 1.0).animate(animation),
                    child: child,
                  ),
                ),
                child: _savedSession == null
                    ? _SaveSessionPanel(
                        key: const ValueKey('save'),
                        onSave: _openSaveSheet,
                      )
                    : _SavedSessionPanel(
                        key: ValueKey(_savedSession!.id),
                        session: _savedSession!,
                        onViewHistory: _goToHistory,
                        onDone: _goHome,
                      ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    ),
    );
  }
}

/// Shown under the recommendations until they're saved.
class _SaveSessionPanel extends StatelessWidget {
  const _SaveSessionPanel({super.key, required this.onSave});

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final gold = kSecondaryColor;
    final isDark = ThemeController.instance.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withValues(alpha: 0.45)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gold.withValues(alpha: 0.14), gold.withValues(alpha: 0.04)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.bookmark_add_rounded, color: gold, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: MyText(
                  text: 'Keep a record of this',
                  size: 15,
                  weight: FontWeight.bold,
                ),
              ),
            ],
          ),
          MyText(
            paddingTop: 6,
            paddingBottom: 14,
            text:
                'Save these recommendations with the session name, track, date '
                'and your notes. They go into History.',
            size: 12.5,
            color: kTertiaryColor.withValues(alpha: 0.8),
          ),
          PressScale(
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_alt_rounded, size: 20),
              label: const Text(
                'Save to session',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: isDark ? Colors.black : kPrimaryColor,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Replaces the save panel once saved, with somewhere to go next.
class _SavedSessionPanel extends StatelessWidget {
  const _SavedSessionPanel({
    super.key,
    required this.session,
    required this.onViewHistory,
    required this.onDone,
  });

  final ChassisSession session;
  final VoidCallback onViewHistory;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final gold = kSecondaryColor;
    const green = Color(0xff3DD68C);
    final isDark = ThemeController.instance.isDarkMode;
    final track = session.trackSnapshot['circuit_name']?.toString().trim();
    final subtitle = [
      if (track != null && track.isNotEmpty) track,
      if (session.eventDate != null) formatSetupDate(session.eventDate!),
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kQuaternaryColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: green.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const PopIn(
                child: Icon(Icons.check_circle_rounded, color: green, size: 26),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText(
                      text: 'Saved “${session.sessionName ?? 'Session'}”',
                      size: 15,
                      weight: FontWeight.bold,
                      maxLines: 1,
                      textOverflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty)
                      MyText(
                        paddingTop: 2,
                        text: subtitle,
                        size: 12.5,
                        color: kTertiaryColor.withValues(alpha: 0.75),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: PressScale(
                  child: OutlinedButton(
                    onPressed: onDone,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: gold,
                      side: BorderSide(color: gold.withValues(alpha: 0.8)),
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(23),
                      ),
                    ),
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PressScale(
                  child: ElevatedButton(
                    onPressed: onViewHistory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: isDark ? Colors.black : kPrimaryColor,
                      elevation: 0,
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(23),
                      ),
                    ),
                    child: const Text(
                      'View in History',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdjustmentTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? trailing;

  const _AdjustmentTile({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kQuaternaryColor,
        border: Border.all(color: kBorderColor2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset(Assets.imagesSelected, height: 24),
              SizedBox(width: 8),
              Expanded(
                child: MyText(text: title, size: 14, weight: FontWeight.bold),
              ),
              if (trailing != null && trailing!.trim().isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Color(0xffE8618C).withAlpha(51),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: MyText(
                    text: trailing!,
                    size: 11,
                    color: Color(0xffE8618C),
                  ),
                ),
            ],
          ),
          MyText(paddingTop: 8, text: subtitle, size: 14),
        ],
      ),
    );
  }
}
