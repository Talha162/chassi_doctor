import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/utils.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/view/screens/bottom_nav_bar/bottom_nav_bar.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';

class TrackConfiguration extends StatefulWidget {
  TrackConfiguration({super.key});

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
      {'title': 'Wet', 'image': Assets.imagesDry},
    ],
  };

  @override
  State<TrackConfiguration> createState() => _TrackConfigurationState();
}

class _TrackConfigurationState extends State<TrackConfiguration> {
  // Track selected index for each section
  final Map<String, int> selectedIndexes = {
    'Track Type': 0,
    'Surface Type': 0,
    'Weather Condition': 0,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: 'Track Configuration', haveLeading: false),
      body: ListView.builder(
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: BouncingScrollPhysics(),
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
                  ),
                ),
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
          child: MyButton(
            buttonText: 'Save Configuration',
            onTap: () {
              Get.offAll(() => BottomNavBar());
            },
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
    Key? key,
    required this.title,
    required this.imagePath,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        margin: EdgeInsets.symmetric(vertical: 4),
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
