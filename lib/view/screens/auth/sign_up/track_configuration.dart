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
      {'title': 'Wet', 'image': Assets.imagesWeather}, // Corrected this line
    ],
  };

  @override
  State<TrackConfiguration> createState() => _TrackConfigurationState();
}

class _TrackConfigurationState extends State<TrackConfiguration> {
  final ProfileService _profileService = ProfileService();
  final SupabaseService _supabaseService = SupabaseService.instance;
  bool _isLoading = false;

  final Map<String, int> selectedIndexes = {
    'Track Type': 0,
    'Surface Type': 0,
    'Weather Condition': 0,
  };

  Future<void> _saveConfiguration() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final trackType =
          widget.trackSections['Track Type']![selectedIndexes['Track Type']!]['title']!;
      final surfaceType = widget
          .trackSections['Surface Type']![selectedIndexes['Surface Type']!]['title']!;
      final weatherCondition = widget.trackSections['Weather Condition']![
          selectedIndexes['Weather Condition']!]['title']!;

      await _profileService.saveTrackConfiguration(
        trackType: trackType,
        surfaceType: surfaceType,
        weatherCondition: weatherCondition,
      );

      Get.offAllNamed(AppLinks.bottomNavBar);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to save configuration. Check console for details. Error: ${e.toString()}"),
          backgroundColor: Colors.redAccent,
        ));
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
  }

  void _applyInitialSelections() {
    selectedIndexes['Track Type'] =
        _indexFor('Track Type', widget.initialTrackType);
    selectedIndexes['Surface Type'] =
        _indexFor('Surface Type', widget.initialSurfaceType);
    selectedIndexes['Weather Condition'] =
        _indexFor('Weather Condition', widget.initialWeatherCondition);
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
      final latest =
          await _supabaseService.getLatestTrackConfigurationForUser(userId);
      if (!mounted || latest == null) return;
      setState(() {
        selectedIndexes['Track Type'] =
            _indexFor('Track Type', latest.trackType);
        selectedIndexes['Surface Type'] =
            _indexFor('Surface Type', latest.surfaceType);
        selectedIndexes['Weather Condition'] =
            _indexFor('Weather Condition', latest.weatherCondition);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: 'Track Configuration', haveLeading: false),
      body: ListView.builder(
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.trackSections.length,
        itemBuilder: (context, sectionIndex) {
          final sectionKey = widget.trackSections.keys.elementAt(sectionIndex);
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
                    Image.asset(
                      [
                        Assets.imagesTrackType,
                        Assets.imagesSurfaceType,
                        Assets.imagesWeather,
                      ][sectionIndex],
                      height: 24,
                    ),
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
                  ),),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        color: kPrimaryColor,
        child: Padding(
          padding: AppSizes.DEFAULT,
          child: _isLoading
              ?  Center(child: CircularProgressIndicator(color: kSecondaryColor))
              : MyButton(
                  buttonText: 'Save Configuration',
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
          color: selected ? kTertiaryColor.withValues(alpha: .1) : Colors.transparent,
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
