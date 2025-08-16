import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/main.dart';
import 'package:motorsport/view/screens/home/identify_issues.dart';
import 'package:motorsport/view/widget/common_image_view_widget.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> cardData = [
      {
        'subtitle': 'Contact us',
        'title': 'Chassis Doctor',
        'image': Assets.imagesChassisDoc,
      },
      {
        'subtitle': 'Contact us',
        'title': 'Learning Modules',
        'image': Assets.imagesLearningModules,
      },
      {
        'subtitle': 'Contact us',
        'title': 'Setup History',
        'image': Assets.imagesSetupHistory,
      },
      {
        'subtitle': 'Contact us',
        'title': 'Track map',
        'image': Assets.imagesTrackMap,
      },
    ];

    return Scaffold(
      appBar: simpleAppBar(
        title: '',
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Image.asset(Assets.imagesMenu, height: 24)],
        ),
        actions: [
          Center(
            child: CommonImageView(
              height: 32,
              width: 32,
              radius: 100,
              url: dummyImg,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 12),
          Center(child: Image.asset(Assets.imagesNotifications, height: 24)),
          SizedBox(width: 20),
        ],
      ),
      body: ListView(
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: BouncingScrollPhysics(),
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  Assets.imagesBanner,
                  height: 170,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                right: 20,
                top: 20,
                child: Image.asset(Assets.imagesBannerText, height: 84),
              ),
            ],
          ),
          SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            padding: AppSizes.ZERO,
            physics: BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 110,
            ),
            itemCount: cardData.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Get.to(() => IdentifyIssues());
                },
                child: Stack(
                  children: [
                    Container(
                      width: Get.width,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xff333030), width: 1),
                        color: kQuaternaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 8,
                      child: Image.asset(Assets.imagesCardBg, height: 70),
                    ),
                    Container(
                      width: Get.width,
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            cardData[index]['image'] ?? '',
                            height: 38,
                          ),
                          MyText(
                            paddingTop: 8,
                            text: cardData[index]['subtitle'] ?? '',
                            size: 12,
                            color: kSecondaryColor,
                            paddingBottom: 4,
                          ),
                          MyText(
                            text: cardData[index]['title'] ?? '',
                            size: 14,
                            weight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),

                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 90,
                          height: 4,
                          decoration: BoxDecoration(
                            color: kSecondaryColor,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 20),
          Container(
            width: Get.width,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xff634F91), width: 1),
              color: kQuaternaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: MyText(
                        text: 'Current Condition',
                        size: 14,
                        weight: FontWeight.w700,
                      ),
                    ),
                    MyText(text: 'Edit', size: 12),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Image.asset(Assets.imagesTt, height: 20),
                    Expanded(
                      child: MyText(
                        paddingLeft: 6,
                        text: 'Track Type:',
                        size: 14,
                        color: kSecondaryColor,
                      ),
                    ),
                    MyText(
                      text: 'Laguna seca circuit',
                      size: 14,
                      weight: FontWeight.w500,
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Image.asset(Assets.imagesSt, height: 20),
                    Expanded(
                      child: MyText(
                        paddingLeft: 6,
                        text: 'Surface Type:',
                        size: 14,
                        color: kSecondaryColor,
                      ),
                    ),
                    MyText(
                      text: 'Tarmac - Dry',
                      size: 14,
                      weight: FontWeight.w500,
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Image.asset(Assets.imagesW, height: 20),
                    Expanded(
                      child: MyText(
                        paddingLeft: 6,
                        text: 'Weather:',
                        size: 14,
                        color: kSecondaryColor,
                      ),
                    ),
                    MyText(
                      text: 'Sunny & Warm (28C)',
                      size: 14,
                      weight: FontWeight.w500,
                    ),
                  ],
                ),

                SizedBox(height: 12),
              ],
            ),
          ),
          SizedBox(height: 20),
          Container(
            width: Get.width,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xff634F91), width: 1),
              color: kQuaternaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MyText(
                  text: 'Recent Activity',
                  size: 14,
                  weight: FontWeight.w700,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Image.asset(Assets.imagesSelected, height: 20),
                    Expanded(
                      child: MyText(
                        paddingLeft: 8,
                        text:
                            'Chassis Doctor Diagnosis completed for poor traction',
                        size: 12,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                MyText(
                  paddingTop: 2,
                  textAlign: TextAlign.end,
                  text: '2 hours ago',
                  size: 10,
                  color: kTertiaryColor.withValues(alpha: 0.5),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Image.asset(Assets.imagesTc, height: 20),
                    Expanded(
                      child: MyText(
                        paddingLeft: 8,
                        text:
                            'Track configuration updated to "Nürburgring - Wet.',
                        size: 12,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                MyText(
                  paddingTop: 2,
                  textAlign: TextAlign.end,
                  text: '2 hours ago',
                  size: 10,
                  color: kTertiaryColor.withValues(alpha: 0.5),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Image.asset(Assets.imagesInfo, height: 20),
                    Expanded(
                      child: MyText(
                        paddingLeft: 8,
                        text: 'New learning module "Suspension Basics" added.',
                        size: 12,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                MyText(
                  paddingTop: 2,
                  textAlign: TextAlign.end,
                  text: '2 hours ago',
                  size: 10,
                  color: kTertiaryColor.withValues(alpha: 0.5),
                ),

                SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
