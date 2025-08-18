import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class MyCourses extends StatelessWidget {
  const MyCourses({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      padding: AppSizes.DEFAULT,
      physics: BouncingScrollPhysics(),
      children: [
        MyText(
          text: 'My Courses',
          size: 18,
          paddingBottom: 12,
          weight: FontWeight.bold,
        ),
        ListView.builder(
          shrinkWrap: true,
          padding: AppSizes.ZERO,
          physics: BouncingScrollPhysics(),
          itemCount: 6,
          itemBuilder: (context, index) {
            final tiles = [
              {
                'title': 'Advanced Aerodynamics',
                'duration': '2hrs 30mins',
                'imagePath': Assets.imagesAdvanced,
                'percent': 0.75,
                'completedText': '75% completed',
              },
              {
                'title': 'Advanced Aerodynamics in Racing',
                'duration': '2hrs 30mins',
                'imagePath': Assets.imagesAdvanced1,
                'percent': 0.75,
                'completedText': '75% completed',
              },
              {
                'title': 'Tire Science & Grip Management',
                'duration': '2hrs 30mins',
                'imagePath': Assets.imagesScience,
                'percent': 0.75,
                'completedText': '75% completed',
              },
              {
                'title': 'Advanced Aerodynamics',
                'duration': '2hrs 30mins',
                'imagePath': Assets.imagesAdvanced,
                'percent': 0.75,
                'completedText': '75% completed',
              },
              {
                'title': 'Advanced Aerodynamics in Racing',
                'duration': '2hrs 30mins',
                'imagePath': Assets.imagesAdvanced1,
                'percent': 0.75,
                'completedText': '75% completed',
              },
              {
                'title': 'Tire Science & Grip Management',
                'duration': '2hrs 30mins',
                'imagePath': Assets.imagesScience,
                'percent': 0.75,
                'completedText': '75% completed',
              },
            ];
            final tile = tiles[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < tiles.length - 1 ? 12 : 0,
              ),
              child: _LearningHubTile(
                title: tile['title'] as String,
                duration: tile['duration'] as String,
                imagePath: tile['imagePath'] as String,
                percent: tile['percent'] as double,
                completedText: tile['completedText'] as String,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LearningHubTile extends StatelessWidget {
  final String title;
  final String duration;
  final String imagePath;
  final double percent;
  final String completedText;

  const _LearningHubTile({
    Key? key,
    required this.title,
    required this.duration,
    required this.imagePath,
    required this.percent,
    required this.completedText,
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              imagePath,
              height: 70,
              width: 70,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MyText(
                  text: title,
                  size: 14,
                  paddingBottom: 4,
                  weight: FontWeight.bold,
                ),
                MyText(text: duration, size: 12, paddingBottom: 6),
                LinearPercentIndicator(
                  lineHeight: 6,
                  percent: percent,
                  padding: EdgeInsets.zero,
                  backgroundColor: kTertiaryColor,
                  progressColor: kGreenColor,
                  barRadius: Radius.circular(4),
                ),
                MyText(
                  paddingTop: 6,
                  textAlign: TextAlign.end,
                  text: completedText,
                  size: 12,
                  color: kTertiaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
