import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/view/screens/home/setup_recommendation.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';

class IdentifyIssues extends StatelessWidget {
  const IdentifyIssues({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> cardData = [
      {
        'subtitle':
            'The car turns less than desired when cornering, often leading to a wider path.',
        'title': 'Understeer',
        'image': Assets.imagesUndersteer,
      },
      {
        'subtitle':
            'The car turns more than desired, causing the rear end to slide out in a corner.',
        'title': 'Oversteer',
        'image': Assets.imagesOverSteer,
      },
      {
        'subtitle':
            'Lack of grip during acceleration, braking, or cornering, leading to wheel spin or slides.',
        'title': 'Poor Traction',
        'image': Assets.imagesPoorTraction,
      },
      {
        'subtitle':
            'Car pulls to one side or feels unstable during hard braking.',
        'title': 'Braking Instability',
        'image': Assets.imagesBrakingInstability,
      },
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
              mainAxisExtent: 200,
            ),
            itemCount: cardData.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Get.to(() => SetupRecommendation());
                },
                child: Container(
                  width: Get.width,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xff333030), width: 1),
                    color: kQuaternaryColor,
                    image: DecorationImage(
                      image: AssetImage(Assets.imagesCardBg2),
                      alignment: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 60,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              cardData[index]['image'] ?? '',
                              height: index == 1
                                  ? 60
                                  : index == 3
                                  ? 30
                                  : 50,
                            ),
                          ],
                        ),
                      ),
                      MyText(
                        paddingTop: 8,
                        text: cardData[index]['title'] ?? '',
                        size: 14,
                        weight: FontWeight.w600,
                        paddingBottom: 4,
                      ),
                      MyText(
                        text: cardData[index]['subtitle'] ?? '',
                        size: 12,
                        lineHeight: 1.5,
                        color: kSecondaryColor,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Get.to(() => SetupRecommendation());
            },
            child: Container(
              height: 200,
              width: Get.width,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xff333030), width: 1),
                color: kQuaternaryColor,
                image: DecorationImage(
                  image: AssetImage(Assets.imagesCardBg2),
                  alignment: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 60,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(Assets.imagesSymptons, height: 60),
                      ],
                    ),
                  ),
                  MyText(
                    paddingTop: 8,
                    text: 'Report a New Symptom',
                    size: 14,
                    weight: FontWeight.w600,
                    paddingBottom: 4,
                  ),
                  MyText(
                    text:
                        'Lack of grip during acceleration, braking, or cornering, leading to wheel spin or slides.',
                    size: 12,
                    lineHeight: 1.5,
                    color: kSecondaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
