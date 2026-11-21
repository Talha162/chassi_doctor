import 'package:flutter/services.dart';
import 'package:motorsport/utils/app_snackbar.dart';
import 'package:motorsport/view/widget/report_dialog.dart';
import 'package:motorsport/utils/motion.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/config/theme/theme_controller.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/models/chassis_symptom.dart';
import 'package:motorsport/services/supabase/supabase_client_service.dart';
import 'package:motorsport/view/screens/home/setup_recommendation.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';

class IdentifyIssues extends StatefulWidget {
  const IdentifyIssues({super.key});

  @override
  State<IdentifyIssues> createState() => _IdentifyIssuesState();
}

class _IdentifyIssuesState extends State<IdentifyIssues> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  bool _isLoading = true;
  List<ChassisSymptom> _symptoms = [];

  @override
  void initState() {
    super.initState();
    _loadSymptoms();
  }

  Future<void> _loadSymptoms() async {
    try {
      setState(() => _isLoading = true);
      final issues = await _supabaseService.getChassisSymptoms();
      if (!mounted) return;
      setState(() {
        _symptoms = issues;
      });
    } catch (e) {
      debugPrint('Failed to load chassis issues: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddSymptomDialog() async {
    final sent = await showReportDialog(
      context: context,
      heading: 'Report a New Symptom',
      titleLabel: 'Symptom',
      titleHint: 'e.g. Snap oversteer on bumps',
      descriptionHint: 'What does the car do, and when?',
      onSubmit: (title, description) => _supabaseService.createSymptomReport(
        title: title,
        description: description,
      ),
    );
    if (sent == true) {
      showSuccessSnackbar(
        "Thanks! We'll review your symptom and add it to the app.",
        title: 'Report sent',
      );
    }
  }

  String _issueImageForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'understeer':
        return Assets.imagesUndersteer;
      case 'oversteer':
        return Assets.imagesOverSteer;
      case 'poor traction':
        return Assets.imagesPoorTraction;
      case 'braking instability':
        return Assets.imagesBrakingInstability;
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
      default:
        return Assets.imagesSymptons;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kPrimaryColor,
        automaticallyImplyLeading: false,
        leading: const Center(child: AppBackButton()),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: kPrimaryColor,
              child: ClipOval(
                child: Image.asset(
                  Assets.mainlogo,
                  height: 68,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),
            MyText(
              text: 'Chassis Doctor',
              size: 18,
              weight: FontWeight.w600,
              color: kTertiaryColor,
            ),
          ],
        ),
      ),
      body: ListView(
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 12),
          MyText(
            text: 'What’s going on with the car?',
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
          if (_isLoading)
            Center(child: CircularProgressIndicator(color: kSecondaryColor))
          else if (_symptoms.isEmpty)
            MyText(
              text: 'No symptoms available yet. Add the first one below.',
              size: 12,
              color: kSecondaryColor,
              paddingBottom: 12,
            )
          else
            GridView.builder(
              shrinkWrap: true,
              padding: AppSizes.ZERO,
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 200,
              ),
              itemCount: _symptoms.length > 4
                  ? 4
                  : _symptoms
                        .length, // used to handle temporarily from frontend as no backend access
              itemBuilder: (context, index) => FadeInUp(
                delay: staggerDelay(index),
                child: Builder(
                  builder: (context) {
                    final issue = _symptoms[index];
                    final fallbackAsset = _issueImageForTitle(issue.title);

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Get.to(() => SetupRecommendation(symptom: issue));
                      },
                      child: Container(
                        width: Get.width,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: kBorderColor2, width: 1),
                          color: kQuaternaryColor,
                          gradient: ThemeController.instance.isDarkMode
                              ? null
                              : const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xff23356C),
                                    Color(0xff2B3F7B),
                                  ],
                                ),
                          image: ThemeController.instance.isDarkMode
                              ? const DecorationImage(
                                  image: AssetImage(Assets.imagesCardBg2Dark),
                                  alignment: Alignment.bottomRight,
                                  fit: BoxFit.cover,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 60,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (issue.imageUrl != null)
                                    Image.network(
                                      issue.imageUrl!,
                                      height: 50,
                                      errorBuilder: (_, __, ___) => Image.asset(
                                        fallbackAsset,
                                        height: 50,
                                      ),
                                      loadingBuilder:
                                          (context, child, progress) {
                                            if (progress == null) return child;
                                            return SizedBox(
                                              height: 50,
                                              width: 50,
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: kSecondaryColor,
                                                    ),
                                              ),
                                            );
                                          },
                                    )
                                  else
                                    Image.asset(fallbackAsset, height: 50),
                                ],
                              ),
                            ),
                            MyText(
                              paddingTop: 8,
                              text: issue.title,
                              size: 14,
                              weight: FontWeight.w600,
                              paddingBottom: 4,
                              maxLines: 1,
                              textOverflow: TextOverflow.ellipsis,
                            ),
                            MyText(
                              text: issue.description,
                              size: 10,
                              lineHeight: 1.5,
                              color: kSecondaryColor,
                              maxLines: 3,
                              textOverflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          SizedBox(height: 20),
          // Center(child: Image.asset(Assets.imagesChassisDoc, height: 36)),
          SizedBox(height: 18),
          GestureDetector(
            onTap: () {
              _showAddSymptomDialog();
            },
            child: Container(
              height: 200,
              width: Get.width,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: kBorderColor2, width: 1),
                color: kQuaternaryColor,
                gradient: ThemeController.instance.isDarkMode
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xff23356C), Color(0xff2B3F7B)],
                      ),
                image: ThemeController.instance.isDarkMode
                    ? const DecorationImage(
                        image: AssetImage(Assets.imagesCardBg2Dark),
                        alignment: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
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
                        "Don't see your symptom above? Tap to submit it for admin review.",
                    size: 10,
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
