import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/config/theme/theme_controller.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/models/chassis_symptom.dart';
import 'package:motorsport/services/supabase/supabase_client_service.dart';
import 'package:motorsport/view/screens/home/setup_recommendation.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
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
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: kQuaternaryColor,
              title: const Text('Report a New Symptom'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Symptom title',
                      ),
                      maxLength: 60,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          final description =
                              descriptionController.text.trim();
                          if (title.isEmpty || description.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill in all fields.'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          try {
                            final created =
                                await _supabaseService.createChassisSymptom(
                              title: title,
                              description: description,
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              _loadSymptoms();
                              Get.to(
                                () => SetupRecommendation(
                                  symptom: created,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to save symptom: ${e.toString()}',
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setDialogState(() => isSaving = false);
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
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
              physics: BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 200,
              ),
              itemCount: _symptoms.length,
              itemBuilder: (context, index) {
                final issue = _symptoms[index];
                final imagePath = _issueImageForTitle(issue.title);
                return GestureDetector(
                  onTap: () {
                    Get.to(
                      () => SetupRecommendation(
                        symptom: issue,
                      ),
                    );
                  },
                  child: Container(
                    width: Get.width,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: kBorderColor2, width: 1),
                      color: kQuaternaryColor,
                      image: DecorationImage(
                        image: AssetImage(
                          ThemeController.instance.isDarkMode
                              ? Assets.imagesCardBg2Dark
                              : Assets.imagesCardBg2,
                        ),
                        alignment: Alignment.bottomRight,
                        fit: BoxFit.cover,
                      ),
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
                              Image.asset(
                                imagePath,
                                height: 50,
                              ),
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
          SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              _showAddSymptomDialog();
            },
            child: Container(
              height: 200,
              width: Get.width,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: kBorderColor2, width: 1),
                color: kQuaternaryColor,
                image: DecorationImage(
                  image: AssetImage(
                    ThemeController.instance.isDarkMode
                        ? Assets.imagesCardBg2Dark
                        : Assets.imagesCardBg2,
                  ),
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
