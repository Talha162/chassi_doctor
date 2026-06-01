import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/models/adjustment_recommendation.dart';
import 'package:motorsport/models/chassis_issue_option.dart';
import 'package:motorsport/models/chassis_symptom.dart';
import 'package:motorsport/view/screens/demo_admin/demo_admin_supabase_helpers.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';

class DemoAdminRecommendationsScreen extends StatefulWidget {
  const DemoAdminRecommendationsScreen({super.key});

  @override
  State<DemoAdminRecommendationsScreen> createState() =>
      _DemoAdminRecommendationsScreenState();
}

class _DemoAdminRecommendationsScreenState
    extends State<DemoAdminRecommendationsScreen> {
  // Section 1: Symptom Selection
  List<ChassisSymptom> _symptoms = [];
  ChassisSymptom? _selectedSymptom;
  bool _loadingSymptoms = false;

  // Section 2: Adjustment Set
  List<Map<String, dynamic>> _sets = [];
  Map<String, dynamic>? _selectedSet;
  bool _loadingSets = false;
  final _setTitleController = TextEditingController();
  bool _setIsActive = true;
  bool _creatingSet = false;
  bool _showCreateSetForm = false;

  // Section 3: Issue Options
  List<ChassisIssueOption> _issues = [];
  Set<String> _selectedIssueIds = {};
  bool _loadingIssues = false;
  bool _savingIssueLinks = false;

  // Section 4: Recommendations
  List<AdjustmentRecommendation> _allRecommendations = [];
  AdjustmentRecommendation? _selectedRecommendation;
  bool _loadingRecommendations = false;

  final _recTitleController = TextEditingController();
  final _recDetailsController = TextEditingController();
  String _recCategory = 'Other';
  bool _creatingRecommendation = false;
  bool _showCreateRecForm = false;

  // Section 5: Attach Recommendation
  final _priorityController = TextEditingController(text: '100');
  bool _attachingRecommendation = false;
  List<Map<String, dynamic>> _attachedRecommendations = [];
  bool _loadingAttached = false;

  // Section 6: Track Presets
  List<Map<String, dynamic>> _presets = [];
  Set<String> _selectedPresetIds = {};
  bool _loadingPresets = false;
  bool _savingPresets = false;

  @override
  void initState() {
    super.initState();
    _loadSymptoms();
  }

  @override
  void dispose() {
    _setTitleController.dispose();
    _recTitleController.dispose();
    _recDetailsController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  // ═══════════════════ SYMPTOM LOADING ═══════════════════
  Future<void> _loadSymptoms() async {
    setState(() => _loadingSymptoms = true);
    try {
      final symptoms = await DemoAdminSupabaseHelpers.getActiveSymptoms();
      if (mounted) {
        setState(() {
          _symptoms = symptoms;
        });
        debugPrint('[DEMO_ADMIN] Loaded ${symptoms.length} symptoms');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load symptoms: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingSymptoms = false);
    }
  }

  Future<void> _onSymptomSelected(ChassisSymptom symptom) async {
    setState(() {
      _selectedSymptom = symptom;
      _selectedSet = null;
      _selectedIssueIds.clear();
      _selectedPresetIds.clear();
    });
    await Future.wait([
      _loadSets(),
      _loadIssues(),
      _loadPresets(),
    ]);
  }

  // ═══════════════════ SET MANAGEMENT ═══════════════════
  Future<void> _loadSets() async {
    if (_selectedSymptom == null) return;
    setState(() => _loadingSets = true);
    try {
      final sets = await DemoAdminSupabaseHelpers.getSetsBySymptom(
        _selectedSymptom!.id,
      );
      if (mounted) {
        setState(() {
          _sets = sets;
        });
        debugPrint('[DEMO_ADMIN] Loaded ${sets.length} sets');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load sets: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingSets = false);
    }
  }

  Future<void> _createSet() async {
    final title = _setTitleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a set title')),
      );
      return;
    }

    if (_selectedSymptom == null) return;

    setState(() => _creatingSet = true);
    try {
      await DemoAdminSupabaseHelpers.createAdjustmentSet(
        symptomId: _selectedSymptom!.id,
        title: title,
        isActive: _setIsActive,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Set created successfully!')),
        );
        _setTitleController.clear();
        _setIsActive = true;
        setState(() => _showCreateSetForm = false);
        await _loadSets();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create set: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _creatingSet = false);
    }
  }

  Future<void> _onSetSelected(Map<String, dynamic> set) async {
    setState(() {
      _selectedSet = set;
      _selectedIssueIds.clear();
      _attachedRecommendations.clear();
    });
    await Future.wait([
      _loadLinkedIssues(),
      _loadAttachedRecommendations(),
      _loadLinkedPresets(),
    ]);
  }

  // ═══════════════════ ISSUE LOADING & LINKING ═══════════════════
  Future<void> _loadIssues() async {
    if (_selectedSymptom == null) return;
    setState(() => _loadingIssues = true);
    try {
      final issues = await DemoAdminSupabaseHelpers.getIssuesBySymptom(
        _selectedSymptom!.id,
      );
      if (mounted) {
        setState(() {
          _issues = issues;
        });
        debugPrint('[DEMO_ADMIN] Loaded ${issues.length} issues');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load issues: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingIssues = false);
    }
  }

  Future<void> _loadLinkedIssues() async {
    if (_selectedSet == null) return;
    try {
      final linkedIds = await DemoAdminSupabaseHelpers.getLinkedIssueIds(
        _selectedSet!['id'] as String,
      );
      if (mounted) {
        setState(() {
          _selectedIssueIds = linkedIds.toSet();
        });
      }
    } catch (e) {
      debugPrint('[DEMO_ADMIN] Error loading linked issues: $e');
    }
  }

  Future<void> _saveIssueLinks() async {
    if (_selectedSet == null) return;

    setState(() => _savingIssueLinks = true);
    try {
      await DemoAdminSupabaseHelpers.linkIssuesToSet(
        setId: _selectedSet!['id'] as String,
        issueIds: _selectedIssueIds.toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Issue links saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save links: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingIssueLinks = false);
    }
  }

  // ═══════════════════ RECOMMENDATION MANAGEMENT ═══════════════════
  Future<void> _loadRecommendations() async {
    setState(() => _loadingRecommendations = true);
    try {
      final recs = await DemoAdminSupabaseHelpers.getAllRecommendations();
      if (mounted) {
        setState(() {
          _allRecommendations = recs;
        });
        debugPrint('[DEMO_ADMIN] Loaded ${recs.length} recommendations');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load recommendations: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingRecommendations = false);
    }
  }

  Future<void> _createRecommendation() async {
    final title = _recTitleController.text.trim();
    final details = _recDetailsController.text.trim();

    if (title.isEmpty || details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _creatingRecommendation = true);
    try {
      await DemoAdminSupabaseHelpers.createRecommendation(
        title: title,
        details: details,
        category: _recCategory,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recommendation created!')),
        );
        _recTitleController.clear();
        _recDetailsController.clear();
        _recCategory = 'Other';
        setState(() => _showCreateRecForm = false);
        await _loadRecommendations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _creatingRecommendation = false);
    }
  }

  // ═══════════════════ ATTACH RECOMMENDATION ═══════════════════
  Future<void> _loadAttachedRecommendations() async {
    if (_selectedSet == null) return;
    setState(() => _loadingAttached = true);
    try {
      final attached = await DemoAdminSupabaseHelpers.getRecommendationsForSet(
        _selectedSet!['id'] as String,
      );
      if (mounted) {
        setState(() {
          _attachedRecommendations = attached;
        });
      }
    } catch (e) {
      debugPrint('[DEMO_ADMIN] Error loading attached recs: $e');
    } finally {
      if (mounted) setState(() => _loadingAttached = false);
    }
  }

  Future<void> _attachRecommendation() async {
    if (_selectedSet == null || _selectedRecommendation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a recommendation')),
      );
      return;
    }

    final priorityText = _priorityController.text.trim();
    if (priorityText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a priority')),
      );
      return;
    }

    final priority = int.tryParse(priorityText) ?? 100;

    setState(() => _attachingRecommendation = true);
    try {
      await DemoAdminSupabaseHelpers.attachRecommendationToSet(
        setId: _selectedSet!['id'] as String,
        recommendationId: _selectedRecommendation!.id ?? '',
        priority: priority,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recommendation attached!')),
        );
        _selectedRecommendation = null;
        _priorityController.text = '100';
        await _loadAttachedRecommendations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to attach: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _attachingRecommendation = false);
    }
  }

  //nisudnfirbfgibvdf
  Future<void> _detachRecommendation(String recId) async {
    if (_selectedSet == null) return;

    try {
      await DemoAdminSupabaseHelpers.removeRecommendationFromSet(
        setId: _selectedSet!['id'] as String,
        recommendationId: recId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recommendation removed!')),
        );
        await _loadAttachedRecommendations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: $e')),
        );
      }
    }
  }

  // ═══════════════════ TRACK PRESETS ═══════════════════
  Future<void> _loadPresets() async {
    setState(() => _loadingPresets = true);
    try {
      final presets = await DemoAdminSupabaseHelpers.getTrackPresets();
      if (mounted) {
        setState(() {
          _presets = presets;
        });
      }
    } catch (e) {
      debugPrint('[DEMO_ADMIN] Error loading presets: $e');
    } finally {
      if (mounted) setState(() => _loadingPresets = false);
    }
  }

  Future<void> _loadLinkedPresets() async {
    if (_selectedSet == null) return;
    try {
      final linkedIds = await DemoAdminSupabaseHelpers.getLinkedPresetIds(
        _selectedSet!['id'] as String,
      );
      if (mounted) {
        setState(() {
          _selectedPresetIds = linkedIds.toSet();
        });
      }
    } catch (e) {
      debugPrint('[DEMO_ADMIN] Error loading linked presets: $e');
    }
  }

  String _presetLabel(Map<String, dynamic> preset) {
    final name = (preset['name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    final parts = <String>[
      (preset['track_type'] as String?)?.trim() ?? '',
      (preset['surface_type'] as String?)?.trim() ?? '',
      (preset['weather_condition'] as String?)?.trim() ?? '',
    ].where((p) => p.isNotEmpty).toList();
    return parts.isEmpty ? 'Preset' : parts.join(' / ');
  }

  Future<void> _savePresets() async {
    if (_selectedSet == null) return;

    setState(() => _savingPresets = true);
    try {
      await DemoAdminSupabaseHelpers.linkPresetsToSet(
        setId: _selectedSet!['id'] as String,
        presetIds: _selectedPresetIds.toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Presets linked!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to link presets: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingPresets = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: 'Demo Admin - Recommendations'),
      body: _loadingSymptoms
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppSizes.DEFAULT,
              children: [
                // ═══════════════════ SECTION 1: SYMPTOM SELECTION ═══════════════════
                MyText(
                  text: 'Section 1: Select Symptom',
                  size: 16,
                  weight: FontWeight.bold,
                  paddingBottom: 12,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: kBorderColor2),
                    borderRadius: BorderRadius.circular(8),
                    color: kQuaternaryColor,
                  ),
                  child: DropdownButton<ChassisSymptom>(
                    isExpanded: true,
                    underline: const SizedBox(),
                    value: _selectedSymptom,
                    hint: const Text('Select a symptom...'),
                    items: _symptoms
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.title),
                          ),
                        )
                        .toList(),
                    onChanged: (symptom) {
                      if (symptom != null) {
                        _onSymptomSelected(symptom);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // ═══════════════════ SECTION 2: ADJUSTMENT SET ═══════════════════
                if (_selectedSymptom != null) ...[
                  MyText(
                    text: 'Section 2: Adjustment Set',
                    size: 16,
                    weight: FontWeight.bold,
                    paddingBottom: 12,
                  ),
                  if (_loadingSets)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: kBorderColor2),
                        borderRadius: BorderRadius.circular(8),
                        color: kQuaternaryColor,
                      ),
                      child: DropdownButton<Map<String, dynamic>>(
                        isExpanded: true,
                        underline: const SizedBox(),
                        value: _selectedSet,
                        hint: const Text('Select or create a set...'),
                        items: _sets
                            .map(
                              (set) => DropdownMenuItem(
                                value: set,
                                child: Text(set['title'] as String),
                              ),
                            )
                            .toList(),
                        onChanged: (set) {
                          if (set != null) {
                            _onSetSelected(set);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _showCreateSetForm = !_showCreateSetForm);
                      },
                      icon: Icon(_showCreateSetForm ? Icons.expand_less : Icons.add),
                      label: Text(
                        _showCreateSetForm ? 'Cancel' : 'Create New Set',
                      ),
                    ),
                    if (_showCreateSetForm) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _setTitleController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Set Title',
                          labelStyle: const TextStyle(color: Colors.black54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: _setIsActive,
                            onChanged: (val) {
                              setState(() => _setIsActive = val ?? true);
                            },
                          ),
                          const Text('Is Active'),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _creatingSet ? null : _createSet,
                        child: _creatingSet
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Create'),
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),
                ],

                // ═══════════════════ SECTION 3: LINK ISSUES ═══════════════════
                if (_selectedSet != null && _issues.isNotEmpty) ...[
                  MyText(
                    text: 'Section 3: Link Issue Options',
                    size: 16,
                    weight: FontWeight.bold,
                    paddingBottom: 12,
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _issues
                        .map(
                          (issue) => FilterChip(
                            selected: _selectedIssueIds.contains(issue.id),
                            label: Text(issue.title),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedIssueIds.add(issue.id);
                                } else {
                                  _selectedIssueIds.remove(issue.id);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _savingIssueLinks ? null : _saveIssueLinks,
                    child: _savingIssueLinks
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Issue Links'),
                  ),
                  const SizedBox(height: 24),
                ],

                // ═══════════════════ SECTION 4: RECOMMENDATIONS ═══════════════════
                if (_selectedSet != null) ...[
                  MyText(
                    text: 'Section 4: Manage Recommendations',
                    size: 16,
                    weight: FontWeight.bold,
                    paddingBottom: 12,
                  ),
                  if (_loadingRecommendations)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    // A) Pick existing
                    MyText(
                      text: 'A) Pick Existing',
                      size: 14,
                      weight: FontWeight.w600,
                      paddingBottom: 8,
                    ),
                    if (_allRecommendations.isEmpty)
                      MyText(
                        text: 'No recommendations found. Create one below.',
                        size: 12,
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: kBorderColor2),
                          borderRadius: BorderRadius.circular(8),
                          color: kQuaternaryColor,
                        ),
                        child: DropdownButton<AdjustmentRecommendation>(
                          isExpanded: true,
                          underline: const SizedBox(),
                          value: _selectedRecommendation,
                          hint: const Text('Select recommendation...'),
                          items: _allRecommendations
                              .map(
                                (rec) => DropdownMenuItem(
                                  value: rec,
                                  child: Text(rec.title),
                                ),
                              )
                              .toList(),
                          onChanged: (rec) {
                            setState(() => _selectedRecommendation = rec);
                          },
                        ),
                      ),
                    const SizedBox(height: 16),

                    // B) Create new
                    MyText(
                      text: 'B) Create New',
                      size: 14,
                      weight: FontWeight.w600,
                      paddingBottom: 8,
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _showCreateRecForm = !_showCreateRecForm);
                      },
                      icon: Icon(_showCreateRecForm ? Icons.expand_less : Icons.add),
                      label: Text(
                        _showCreateRecForm ? 'Cancel' : 'Create New Recommendation',
                      ),
                    ),
                    if (_showCreateRecForm) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _recTitleController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Title',
                          labelStyle: const TextStyle(color: Colors.black54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _recDetailsController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Details',
                          labelStyle: const TextStyle(color: Colors.black54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: kBorderColor2),
                          borderRadius: BorderRadius.circular(8),
                          color: kQuaternaryColor,
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          underline: const SizedBox(),
                          value: _recCategory,
                          items: ['Understeer', 'Oversteer', 'Other']
                              .map(
                                (cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() => _recCategory = val ?? 'Other');
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _creatingRecommendation ? null : _createRecommendation,
                        child: _creatingRecommendation
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Create Recommendation'),
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),
                ],

                // ═══════════════════ SECTION 5: ATTACH RECOMMENDATION ═══════════════════
                if (_selectedSet != null) ...[
                  MyText(
                    text: 'Section 5: Attach to Set',
                    size: 16,
                    weight: FontWeight.bold,
                    paddingBottom: 12,
                  ),
                  if (_selectedRecommendation != null) ...[
                    MyText(
                      text: 'Selected: ${_selectedRecommendation!.title}',
                      size: 12,
                      paddingBottom: 8,
                    ),
                  ],
                  TextField(
                    controller: _priorityController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Priority Order',
                      labelStyle: const TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _attachingRecommendation ? null : _attachRecommendation,
                    child: _attachingRecommendation
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Attach to Set'),
                  ),
                  const SizedBox(height: 24),

                  // Attached recommendations list
                  if (_loadingAttached)
                    const Center(child: CircularProgressIndicator())
                  else if (_attachedRecommendations.isNotEmpty) ...[
                    MyText(
                      text: 'Attached Recommendations',
                      size: 14,
                      weight: FontWeight.w600,
                      paddingBottom: 12,
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _attachedRecommendations.length,
                      itemBuilder: (context, index) {
                        final item = _attachedRecommendations[index];
                        final rec = item['adjustment_recommendations'] as Map?;
                        final title = rec?['title'] ?? 'Unknown';
                        final priority = item['priority_order'] ?? 0;
                        final recId = rec?['id'] as String?;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: kBorderColor2),
                            borderRadius: BorderRadius.circular(8),
                            color: kQuaternaryColor,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    MyText(
                                      text: title,
                                      size: 13,
                                      weight: FontWeight.w600,
                                    ),
                                    MyText(
                                      text: 'Priority: $priority',
                                      size: 11,
                                      color: kSecondaryColor,
                                    ),
                                  ],
                                ),
                              ),
                              if (recId != null)
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  onPressed: () =>
                                      _detachRecommendation(recId),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                ],

                // ═══════════════════ SECTION 6: TRACK PRESETS ═══════════════════
                if (_selectedSet != null && _presets.isNotEmpty) ...[
                  MyText(
                    text: 'Section 6: Link Track Presets',
                    size: 16,
                    weight: FontWeight.bold,
                    paddingBottom: 12,
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presets
                        .map(
                          (preset) => FilterChip(
                            selected: _selectedPresetIds.contains(preset['id']),
                            label: Text(_presetLabel(preset)),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedPresetIds.add(preset['id'] as String);
                                } else {
                                  _selectedPresetIds.remove(preset['id']);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _savingPresets ? null : _savePresets,
                    child: _savingPresets
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Link Presets'),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
