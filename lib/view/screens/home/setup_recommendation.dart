import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';

class SetupRecommendation extends StatelessWidget {
  const SetupRecommendation({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> cardData = [
      {'title': 'Understeer', 'image': Assets.imagesUndersteer},
      {'title': 'Oversteer', 'image': Assets.imagesOverSteer},
      {'title': 'Poor Braking', 'image': Assets.imagesPoorBraking},
      {'title': 'Instability', 'image': Assets.imagesInstability},
      {'title': 'Uneven Tire Wear', 'image': Assets.imagesUnevenTyre},
      {'title': 'Rough Ride', 'image': Assets.imagesRoughRide},
      {'title': 'Lack of Grip', 'image': Assets.imagesLack},
      {'title': 'Slow Turn-in', 'image': Assets.imagesSlowTurnIn},
    ];
    return Scaffold(
      appBar: simpleAppBar(title: 'Chassis Doctor'),
      body: ListView(
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: BouncingScrollPhysics(),
        children: [
          MyText(
            text: 'Identify the Issues',
            size: 18,
            paddingBottom: 8,
            weight: FontWeight.bold,
          ),
          MyText(
            text:
                "Select the symptom that best describes your vehicle's behavior.",
            size: 12,
            paddingBottom: 25,
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
            itemCount: cardData.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {},
                child: Container(
                  width: Get.width,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: kBorderColor2, width: 1),
                    color: kQuaternaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 60,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              cardData[index]['image'] ?? '',
                              height: 60,
                            ),
                          ],
                        ),
                      ),
                      MyText(
                        paddingTop: 10,
                        text: cardData[index]['title'] ?? '',
                        size: 14,
                        weight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 20),
          MyText(
            text: 'Recommended Adjustment',
            size: 18,
            paddingBottom: 8,
            weight: FontWeight.bold,
          ),
          ListView.builder(
            shrinkWrap: true,
            padding: AppSizes.ZERO,
            physics: BouncingScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              final tiles = [
                {
                  'title': 'Soften Front Shocks',
                  'duration':
                      'Chassis Doctor Diagnosis completed for poor traction',
                },
                {
                  'title': 'Reduce Rear Brake Bias',
                  'duration':
                      'Chassis Doctor Diagnosis completed for poor traction',
                },
                {
                  'title': 'Increase Rear Wing Angle',
                  'duration':
                      'Chassis Doctor Diagnosis completed for poor traction',
                },
              ];
              final tile = tiles[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < tiles.length - 1 ? 10 : 0,
                ),
                child: _AdjustmentTile(
                  title: tile['title'] as String,
                  subtitle: tile['duration'] as String,
                  trailing: index == 0
                      ? 'Cornering Balance'
                      : index == 1
                      ? 'Braking Stability'
                      : 'High Speed Grip',
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
  final String trailing;

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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Color(0xffE8618C).withAlpha(51),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: MyText(
                  text: trailing,
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
