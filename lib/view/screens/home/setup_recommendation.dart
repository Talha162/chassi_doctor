import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/models/adjustment_recommendation.dart';
import 'package:motorsport/models/chassis_issue_option.dart';
import 'package:motorsport/models/chassis_symptom.dart';
import 'package:motorsport/models/track_configuration.dart';
import 'package:motorsport/services/gemini_service.dart';
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
  final GeminiService _geminiService = GeminiService();

  bool _isLoadingIssues = true;
  bool _isRequesting = false;
  List<ChassisIssueOption> _issues = [];
  Set<String> _selectedIssueIds = {};
  TrackConfiguration? _trackConfiguration;
  List<AdjustmentRecommendation> _recommendations = [];
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
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: kQuaternaryColor,
              title: Text('Add Issue for ${widget.symptom.title}'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Issue title',
                      ),
                      maxLength: 60,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          final description = descriptionController.text.trim();
                          if (title.isEmpty || description.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill in all fields.'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          try {
                            final created = await _supabaseService
                                .createIssueOption(
                                  symptomId: widget.symptom.id,
                                  title: title,
                                  description: description,
                                );
                            if (mounted) {
                              Navigator.pop(context);
                              setState(() {
                                _issues.insert(0, created);
                                _selectedIssueIds.add(created.id);
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to save issue: ${e.toString()}',
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setDialogState(() => isSaving = false);
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
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

    return filtered;
  }

  Future<void> _fetchRecommendations() async {
    final visibleIds = _visibleIssues.map((issue) => issue.id).toSet();
    final selectedIssueIds = _selectedIssueIds
        .where((id) => visibleIds.contains(id))
        .toSet();

    if (selectedIssueIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one issue.')),
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

      // Step A: Fetch candidates from Supabase
      final candidates = await _supabaseService.getRankableRecommendations(
        symptomId: widget.symptom.id,
        issueIds: List<String>.from(selectedIssueIds),
        presetId: _trackConfiguration?.presetId,
        trackConfiguration: _trackConfiguration,
      );

      if (!mounted) return;

      // If no candidates found, show message and return
      if (candidates.isEmpty) {
        debugPrint('[SETUP] ❌ No recommendations found in Supabase!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No preset recommendations found for these selections.',
            ),
          ),
        );
        setState(() => _isRequesting = false);
        return;
      }

      // Step B: Decide ranking strategy
      List<AdjustmentRecommendation> finalRecommendations;

      debugPrint(
        '\n[SETUP] Supabase fetched ${candidates.length} candidate(s).',
      );

      if (candidates.length <= 4) {
        // Use candidates as-is (already sorted by priority)
        debugPrint(
          '[SETUP] ✓ Candidates count (${candidates.length}) <= 4, using directly from Supabase.',
        );
        finalRecommendations = candidates;
      } else {
        // Call Gemini to rank and select top 3-4
        debugPrint(
          '[SETUP] Candidates count (${candidates.length}) > 4, calling Gemini to rank...',
        );
        try {
          finalRecommendations = await _geminiService.rankRecommendations(
            symptom: widget.symptom,
            issues: selectedIssues,
            trackConfiguration: _trackConfiguration,
            candidates: candidates,
            topK: 4,
          );
        } catch (e) {
          // Fallback to top 4 by priority if ranking fails
          debugPrint('[SETUP] ❌ Gemini ranking failed: $e, using fallback.');
          finalRecommendations = candidates.take(4).toList();
        }
      }

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
      setState(() {
        _recommendations = finalRecommendations;
      });
      await _saveSession(selectedIssues, finalRecommendations);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get recommendations: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  Future<void> _saveSession(
    List<ChassisIssueOption> selectedIssues,
    List<AdjustmentRecommendation> recommendations,
  ) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('[SETUP] ⚠️ Cannot save history: user not authenticated');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to save history.')),
        );
      }
      return;
    }

    try {
      debugPrint('[SETUP] 📋 Starting session save for user: $userId');
      var trackConfig = _trackConfiguration;
      if (trackConfig == null) {
        debugPrint(
          '[SETUP] 🔍 Fetching latest track configuration from Supabase...',
        );
        trackConfig = await _supabaseService.getLatestTrackConfigurationForUser(
          userId,
        );
        debugPrint(
          '[SETUP] ✅ Fetched track config: ${trackConfig?.trackType ?? 'N/A'}',
        );
      } else {
        debugPrint(
          '[SETUP] ✅ Using current track config: ${trackConfig.trackType}',
        );
      }

      final trackSnapshot = {
        'track_type': trackConfig?.trackType,
        'circuit_name': trackConfig?.circuitName,
        'surface_type': trackConfig?.surfaceType,
        'weather_condition': trackConfig?.weatherCondition,
        'engine_position': trackConfig?.enginePosition,
        'aerofoils': trackConfig?.aerofoils,
        'drive_type': trackConfig?.driveType,
      };
      final prefs = await SharedPreferences.getInstance();
      final savedCircuitName = prefs.getString(_trackCircuitNameKey)?.trim();
      final savedEnginePosition = prefs.getString(_enginePositionKey)?.trim();
      final savedAerofoils = prefs.getString(_aerofoilsKey)?.trim();
      final savedDriveType = prefs.getString(_driveTypeKey)?.trim();

      if ((trackSnapshot['circuit_name'] == null ||
              trackSnapshot['circuit_name'].toString().isEmpty) &&
          savedCircuitName != null &&
          savedCircuitName.isNotEmpty) {
        trackSnapshot['circuit_name'] = savedCircuitName;
      }
      if ((trackSnapshot['engine_position'] == null ||
              trackSnapshot['engine_position'].toString().isEmpty) &&
          savedEnginePosition != null &&
          savedEnginePosition.isNotEmpty) {
        trackSnapshot['engine_position'] = savedEnginePosition;
      }
      if ((trackSnapshot['aerofoils'] == null ||
              trackSnapshot['aerofoils'].toString().isEmpty) &&
          savedAerofoils != null &&
          savedAerofoils.isNotEmpty) {
        trackSnapshot['aerofoils'] = savedAerofoils;
      }
      if ((trackSnapshot['drive_type'] == null ||
              trackSnapshot['drive_type'].toString().isEmpty) &&
          savedDriveType != null &&
          savedDriveType.isNotEmpty) {
        trackSnapshot['drive_type'] = savedDriveType;
      }

      final symptomSnapshot = {
        'id': widget.symptom.id,
        'title': widget.symptom.title,
        'description': widget.symptom.description,
      };

      final issuesSnapshot = selectedIssues
          .map(
            (issue) => {
              'id': issue.id,
              'title': issue.title,
              'description': issue.description,
            },
          )
          .toList();

      final recommendationsSnapshot = recommendations
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

      debugPrint('[SETUP] 📊 Session data:');
      debugPrint('[SETUP]   - Track: ${trackSnapshot['track_type']}');
      debugPrint('[SETUP]   - Symptom: ${symptomSnapshot['title']}');
      debugPrint('[SETUP]   - Issues: ${issuesSnapshot.length}');
      debugPrint(
        '[SETUP]   - Recommendations: ${recommendationsSnapshot.length}',
      );

      final savedSession = await _supabaseService.createChassisSession(
        userId: userId,
        trackSnapshot: trackSnapshot,
        symptomSnapshot: symptomSnapshot,
        issuesSnapshot: issuesSnapshot,
        recommendations: recommendationsSnapshot,
      );

      debugPrint('[SETUP] ✨ Session saved successfully to chassis_sessions');
      debugPrint('[SETUP] 🔑 New session ID: ${savedSession.id}');
      debugPrint('[SETUP] ⏰ Created at: ${savedSession.createdAt}');
    } catch (e) {
      debugPrint('[SETUP] ❌ Error saving session: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save history: $e')));
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final visibleIssueIds = _visibleIssues.map((issue) => issue.id).toSet();
    final selectedVisibleCount = _selectedIssueIds
        .where((id) => visibleIssueIds.contains(id))
        .length;

    return Scaffold(
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
                  itemBuilder: (context, index) {
                    final issue = _visibleIssues[index];
                    final isSelected = _selectedIssueIds.contains(issue.id);
                    return GestureDetector(
                      onTap: () => _toggleIssue(issue.id),
                      child: Container(
                        width: Get.width,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? kSecondaryColor : kBorderColor2,
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
                                children: [
                                  Image.asset(
                                    _issueImageForTitle(issue.title),
                                    height: 60,
                                  ),
                                ],
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
              itemBuilder: (context, index) {
                final recommendation = _recommendations[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < _recommendations.length - 1 ? 10 : 0,
                  ),
                  child: _AdjustmentTile(
                    title: recommendation.title,
                    subtitle: recommendation.details,
                    trailing: recommendation.category,
                  ),
                );
              },
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
