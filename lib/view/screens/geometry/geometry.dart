import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';

class Geometry extends StatelessWidget {
  const Geometry({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: 'Geometry', haveLeading: false),
      body: ListView(
        padding: AppSizes.DEFAULT,
        shrinkWrap: true,
        physics: BouncingScrollPhysics(),
        children: [
          MyText(
            text: 'Fundamentals of Chassis Setup',
            size: 20,
            weight: FontWeight.bold,
            paddingBottom: 12,
          ),
          MyText(
            text:
                'Understanding suspension geometry is crucial for optimizing vehicle handling and performance. It involves studying the movement and interaction of suspension components during driving, impacting grip, stability, and responsiveness. Mastering these principles allows for precise adjustments that can significantly reduce lap times and improve driver confidence.',
            size: 12,
            lineHeight: 1.5,
            paddingBottom: 14,
          ),
          ...[
            'Chassis setup directly influences tire contact patch',
            'Correct geometry maximizes mechanical grip',
            'Dynamic changes affect vehicle balance under load',
            'Predictable handling is a result of fine-tuned geometry',
          ].map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kSecondaryColor,
                    ),
                  ),
                  Expanded(child: MyText(text: text, size: 12)),
                ],
              ),
            ),
          ),
          MyText(
            paddingTop: 19,
            text: 'Double Wishbone System',
            size: 20,
            weight: FontWeight.bold,
            paddingBottom: 12,
          ),
          MyText(
            text:
                'A highly tunable and effective suspension type, offering precise control over camber and toe throughout its travel.',
            size: 12,
            lineHeight: 1.5,
            paddingBottom: 40,
          ),
          Image.asset(Assets.imagesDoubleWishbone, height: 126),
          MyText(
            paddingTop: 40,
            text: 'Camber & Toe Dynamics',
            size: 20,
            weight: FontWeight.bold,
            paddingBottom: 12,
          ),
          MyText(
            text:
                'Camber refers to the vertical angle of the wheel relative to the road, and toe is the horizontal angle. Both are critical for tire wear and cornering grip.',
            size: 12,
            lineHeight: 1.5,
            paddingBottom: 40,
          ),
          Image.asset(Assets.imagesChamber, height: 160),
          SizedBox(height: 40),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Color(0xFF9A5DBE), Color(0xFFA14E96)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MyText(
                  text: 'Anti-Dive Effect on Braking',
                  size: 20,
                  weight: FontWeight.bold,
                  paddingBottom: 12,
                ),
                MyText(
                  text:
                      "Anti-dive geometry reduces the tendency for the front of the car to 'dive' under heavy braking, maintaining a more stable platform for cornering.",
                  size: 12,
                  lineHeight: 1.5,
                  paddingBottom: 14,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: 12,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          Assets.imagesPlaceHolder,
                          height: 86,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          Assets.imagesPlaceHolder,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          MyText(
            paddingTop: 40,
            text: 'Roll Center Explained',
            size: 20,
            weight: FontWeight.bold,
            paddingBottom: 12,
          ),
          MyText(
            text:
                'The roll center is an imaginary point around which the vehicle body rolls. Its position significantly influences lateral load transfer and body roll characteristics.',
            size: 12,
            lineHeight: 1.5,
            paddingBottom: 40,
          ),
          Image.asset(Assets.imagesDoubleWishbone, height: 126),
        ],
      ),
    );
  }
}
