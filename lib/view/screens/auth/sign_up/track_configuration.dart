import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/config/routes/routes.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/services/profile_service.dart';
import 'package:motorsport/services/supabase/supabase_client_service.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrackConfiguration extends StatefulWidget {
  TrackConfiguration({
    super.key,
    this.initialTrackType,
    this.initialSurfaceType,
    this.initialWeatherCondition,
  });

  final String? initialTrackType;
  final String? initialSurfaceType;
  final String? initialWeatherCondition;

  final Map<String, List<Map<String, String>>> trackSections = {
    'Track Type': [
      {'title': 'Oval', 'image': Assets.imagesOval},
      {'title': 'Circuit/Road Course', 'image': Assets.imagesCircuit},
    ],
    'Surface Type': [
      {'title': 'Tarmac/Paved', 'image': Assets.imagesTarmac},
      {'title': 'Shale/Dirt/Grass', 'image': Assets.imagesShale},
    ],
    'Weather Condition': [
      {'title': 'Dry', 'image': Assets.imagesDry},
      {'title': 'Wet', 'image': Assets.imagesWeather},
    ],
    'Engine Position': [
      {'title': 'Front', 'image': Assets.imagesCar},
      {'title': 'Mid', 'image': Assets.imagesCar},
      {'title': 'Rear', 'image': Assets.imagesCar},
    ],
    'Aerofoils': [
      {'title': 'Yes', 'image': Assets.imagesAdvanced},
      {'title': 'No', 'image': Assets.imagesAdvanced},
    ],
  };

  @override
  State<TrackConfiguration> createState() => _TrackConfigurationState();
}

class _TrackConfigurationState extends State<TrackConfiguration> {
  final ProfileService _profileService = ProfileService();
  final SupabaseService _supabaseService = SupabaseService.instance;
  static const String _trackCircuitNameKey = 'track_circuit_name';
  static const String _enginePositionKey = 'engine_position';
  static const String _aerofoilsKey = 'aerofoils';

  bool _isLoading = false;
  final TextEditingController _trackCircuitNameController =
      TextEditingController();

  final Map<String, int> selectedIndexes = {
    'Track Type': 0,
    'Surface Type': 0,
    'Weather Condition': 0,
    'Engine Position': 0,
    'Aerofoils': 0,
  };

  Future<void> _saveConfiguration() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final trackType = widget
          .trackSections['Track Type']![selectedIndexes['Track Type']!]['title']!;
      final surfaceType = widget
          .trackSections['Surface Type']![selectedIndexes['Surface Type']!]['title']!;
      final weatherCondition = widget
          .trackSections['Weather Condition']![selectedIndexes['Weather Condition']!]['title']!;

      final enginePosition = widget
          .trackSections['Engine Position']![selectedIndexes['Engine Position']!]['title']!;
      final aerofoils = widget
          .trackSections['Aerofoils']![selectedIndexes['Aerofoils']!]['title']!;
      final nickname = _trackCircuitNameController.text.trim();

      await _profileService.saveTrackConfiguration(
        trackType: trackType,
        surfaceType: surfaceType,
        weatherCondition: weatherCondition,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _trackCircuitNameKey,
        nickname.isEmpty ? trackType : nickname,
      );
      await prefs.setString(_enginePositionKey, enginePosition);
      await prefs.setString(_aerofoilsKey, aerofoils);

      Get.offAllNamed(AppLinks.bottomNavBar);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save configuration. Check console for details. Error: ${e.toString()}',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
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
  void initState() {
    super.initState();
    _applyInitialSelections();
    _loadLatestConfigurationIfNeeded();
    _loadLocalConfiguration();
  }

  @override
  void dispose() {
    _trackCircuitNameController.dispose();
    super.dispose();
  }

  void _applyInitialSelections() {
    selectedIndexes['Track Type'] = _indexFor(
      'Track Type',
      widget.initialTrackType,
    );
    selectedIndexes['Surface Type'] = _indexFor(
      'Surface Type',
      widget.initialSurfaceType,
    );
    selectedIndexes['Weather Condition'] = _indexFor(
      'Weather Condition',
      widget.initialWeatherCondition,
    );
  }

  Future<void> _loadLocalConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final nickname = prefs.getString(_trackCircuitNameKey);
    final enginePosition = prefs.getString(_enginePositionKey);
    final aerofoils = prefs.getString(_aerofoilsKey);

    if (!mounted) return;

    setState(() {
      if (nickname != null) {
        _trackCircuitNameController.text = nickname;
      }
      if (enginePosition != null) {
        selectedIndexes['Engine Position'] = _indexFor(
          'Engine Position',
          enginePosition,
        );
      }
      if (aerofoils != null) {
        selectedIndexes['Aerofoils'] = _indexFor('Aerofoils', aerofoils);
      }
    });
  }

  Future<void> _loadLatestConfigurationIfNeeded() async {
    if (widget.initialTrackType != null ||
        widget.initialSurfaceType != null ||
        widget.initialWeatherCondition != null) {
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final latest = await _supabaseService.getLatestTrackConfigurationForUser(
        userId,
      );
      if (!mounted || latest == null) return;
      setState(() {
        selectedIndexes['Track Type'] = _indexFor(
          'Track Type',
          latest.trackType,
        );
        selectedIndexes['Surface Type'] = _indexFor(
          'Surface Type',
          latest.surfaceType,
        );
        selectedIndexes['Weather Condition'] = _indexFor(
          'Weather Condition',
          latest.weatherCondition,
        );
      });
    } catch (e) {
      debugPrint('Failed to load latest track configuration: $e');
    }
  }

  int _indexFor(String section, String? value) {
    if (value == null) return selectedIndexes[section] ?? 0;
    final items = widget.trackSections[section];
    if (items == null) return selectedIndexes[section] ?? 0;
    final index = items.indexWhere((item) => item['title'] == value);
    if (index == -1) return selectedIndexes[section] ?? 0;
    return index;
  }

  String _sectionIcon(String sectionKey) {
    switch (sectionKey) {
      case 'Track Type':
        return Assets.imagesTrackType;
      case 'Surface Type':
        return Assets.imagesSurfaceType;
      case 'Weather Condition':
        return Assets.imagesWeather;
      case 'Engine Position':
        return Assets.imagesCar;
      case 'Aerofoils':
        return Assets.imagesAdvanced;
      default:
        return Assets.imagesInfo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(
        title: 'Track / Car Configuration',
        haveLeading: false,
      ),
      body: ListView(
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: const BouncingScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kQuaternaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(Assets.imagesCircuit, height: 24),
                    Expanded(
                      child: MyText(
                        text: 'Track/Circuit Nickname',
                        size: 16,
                        weight: FontWeight.w500,
                        color: kSecondaryColor,
                        paddingLeft: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _trackCircuitNameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Mendips Raceway / Silverstone',
                    filled: true,
                    fillColor: kPrimaryColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: kBorderColor2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: kBorderColor2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...widget.trackSections.keys.map((sectionKey) {
            final items = widget.trackSections[sectionKey]!;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kQuaternaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(_sectionIcon(sectionKey), height: 24),
                      Expanded(
                        child: MyText(
                          text: sectionKey,
                          size: 16,
                          weight: FontWeight.w500,
                          color: kSecondaryColor,
                          paddingLeft: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(
                    items.length,
                    (index) => _CustomRadioTile(
                      title: items[index]['title']!,
                      imagePath: items[index]['image']!,
                      selected: selectedIndexes[sectionKey] == index,
                      onTap: () {
                        setState(() {
                          selectedIndexes[sectionKey] = index;
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Center(child: Image.asset(Assets.imagesChassisDoc, height: 36)),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        color: kPrimaryColor,
        child: Padding(
          padding: AppSizes.DEFAULT,
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: kSecondaryColor))
              : MyButton(
                  buttonText: 'Save Track & Car Setup',
                  onTap: _saveConfiguration,
                ),
        ),
      ),
    );
  }
}

class _CustomRadioTile extends StatelessWidget {
  final String title;
  final String imagePath;
  final bool selected;
  final VoidCallback onTap;

  const _CustomRadioTile({
    required this.title,
    required this.imagePath,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected
              ? kTertiaryColor.withValues(alpha: .1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Image.asset(imagePath, height: 24),
            Expanded(
              child: MyText(
                text: title,
                size: 16,
                weight: FontWeight.w500,
                paddingLeft: 12,
              ),
            ),
            if (selected)
              Image.asset(Assets.imagesSelected, height: 24)
            else
              Image.asset(Assets.imagesUnSelected, height: 24),
          ],
        ),
      ),
    );
  }
}
