import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/main.dart';
import 'package:motorsport/models/app_user.dart';
import 'package:motorsport/models/track_configuration.dart' as track_models;
import 'package:motorsport/services/supabase/supabase_client_service.dart';
import 'package:motorsport/view/screens/auth/sign_up/track_configuration.dart'
    as track_ui;
import 'package:motorsport/view/screens/home/identify_issues.dart';
import 'package:motorsport/view/screens/notifications/notifications_screen.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../learning_hub/learning_hub.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final SupabaseService _service = SupabaseService.instance;
  static const String _trackCircuitNameKey = 'track_circuit_name';
  static const String _enginePositionKey = 'engine_position';
  static const String _aerofoilsKey = 'aerofoils';

  AppUser? _user;
  bool _isLoadingUser = true;
  track_models.TrackConfiguration? _latestConfig;
  bool _isLoadingConfig = true;
  String _trackCircuitName = '';
  String _carType = 'Not set';
  String _note = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadLatestConfig();
    _loadLocalSetupDetails();
  }

  Future<void> _loadUser() async {
    try {
      setState(() => _isLoadingUser = true);
      final current = await _service.getCurrentUserProfile();
      setState(() {
        _user = current;
      });
    } catch (e) {
      debugPrint('Error loading user profile in Home: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  Future<void> _loadLatestConfig() async {
    try {
      setState(() => _isLoadingConfig = true);
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _latestConfig = null;
          _isLoadingConfig = false;
        });
        return;
      }
      final latest = await _service.getLatestTrackConfigurationForUser(userId);
      if (!mounted) return;
      setState(() => _latestConfig = latest);
      if (latest != null) {
        final historyNote = await _service.getHistoryNote(
          userId: userId,
          sourceType: 'track',
          sourceId: 'track-${latest.id}',
        );
        if (!mounted) return;
        setState(() => _note = historyNote?.note ?? '');
      }
    } catch (e) {
      debugPrint('Error loading latest track configuration in Home: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingConfig = false);
      }
    }
  }

  Future<void> _editTrackConfiguration() async {
    await Get.to(
      () => track_ui.TrackConfiguration(
        initialTrackType: _latestConfig?.trackType,
        initialSurfaceType: _latestConfig?.surfaceType,
        initialWeatherCondition: _latestConfig?.weatherCondition,
      ),
    );
    _loadLatestConfig();
    _loadLocalSetupDetails();
  }

  Future<void> _loadLocalSetupDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final trackCircuitName =
        prefs.getString(_trackCircuitNameKey)?.trim() ?? '';
    final enginePosition = prefs.getString(_enginePositionKey)?.trim() ?? '';
    final aerofoils = prefs.getString(_aerofoilsKey)?.trim() ?? '';

    var carType = 'Not set';
    if (enginePosition.isNotEmpty && aerofoils.isNotEmpty) {
      carType = '$enginePosition-engine / Aerofoils: $aerofoils';
    }

    if (!mounted) return;
    setState(() {
      _trackCircuitName = trackCircuitName;
      _carType = carType;
    });
  }

  String get _greetingName {
    if (_isLoadingUser) return 'Driver';
    final full = _user?.fullName;
    if (full == null || full.trim().isEmpty) return 'Driver';
    return full.trim().split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> cardData = [
      {'subtitle': '', 'title': 'Chassis Doctor', 'image': Assets.mainlogo},
      {'subtitle': '', 'title': 'Learning Modules', 'image': Assets.imagesLogo},
      // {
      //   'subtitle': 'Contact us',
      //   'title': 'Setup History',
      //   'image': Assets.imagesSetupHistory,
      // },
      // {
      //   'subtitle': 'Contact us',
      //   'title': 'Track map',
      //   'image': Assets.imagesTrackMap,
      // },
    ];

    final avatarUrl = _user?.avatarUrl ?? dummyImg;
    final trackTypeText = _isLoadingConfig
        ? 'Loading...'
        : (_latestConfig?.trackType ?? 'Not set');
    final trackCircuitText = _trackCircuitName.isNotEmpty
        ? _trackCircuitName
        : trackTypeText;
    final surfaceTypeText = _isLoadingConfig
        ? 'Loading...'
        : (_latestConfig?.surfaceType ?? 'Not set');
    final weatherText = _isLoadingConfig
        ? 'Loading...'
        : (_latestConfig?.weatherCondition ?? 'Not set');

    return Scaffold(
      appBar: simpleAppBar(
        title: 'Chassis Doctor',
        centerTitle: false,
        // Profile avatar on the LEFT
        leading: GestureDetector(
          // onTap: () async {
          //   final _ = await Get.to(() => const Settings(showBackButton: true));
          //   _loadUser(); // refresh after returning
          // },
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Container(
                //   decoration: BoxDecoration(
                //     shape: BoxShape.circle,
                //     border: Border.all(color: kSecondaryColor, width: 2),
                //   ),
                //   child: ClipOval(
                //     child: SizedBox(
                //       height: 32,
                //       width: 32,
                //       child: CommonImageView(
                //         height: 32,
                //         width: 32,
                //         radius: 100,
                //         url: avatarUrl, // 👈 dynamic user avatar or default
                //         fit: BoxFit.cover,
                //       ),
                //     ),
                //   ),
                // ),
                // Small loading overlay if user is loading
                // if (_isLoadingUser)
                //   Container(
                //     height: 32,
                //     width: 32,
                //     decoration: BoxDecoration(
                //       color: Colors.black.withOpacity(0.25),
                //       shape: BoxShape.circle,
                //     ),
                //     child: const SizedBox(
                //       height: 14,
                //       width: 14,
                //       child: CircularProgressIndicator(strokeWidth: 2),
                //     ),
                //   ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: kBorderColor2,
                  child: ClipOval(
                    child: Image.asset(Assets.mainlogo, fit: BoxFit.contain),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Notification icon on RIGHT side
        actions: [
          GestureDetector(
            onTap: () => Get.to(() => const NotificationsScreen()),
            child: Center(
              child: Image.asset(Assets.imagesNotifications, height: 24),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),

      body: ListView(
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: const BouncingScrollPhysics(),
        children: [
          Text(
            "Hey $_greetingName!",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),

          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(Assets.racetracklogo, fit: BoxFit.cover),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0x40303887), Color(0xA0151B4F)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 18,
                    right: 16,
                    left: 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x9A5B3A92),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Chassis Setup Made Simple.',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              shadows: [
                                Shadow(
                                  color: Color(0xCC000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Live Race Car Setup Feedback\nin your hands 24/7.',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Color(0xFFE6E8FF),
                            fontSize: 12,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Color(0xB3000000),
                                blurRadius: 6,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          GridView.builder(
            shrinkWrap: true,
            padding: AppSizes.ZERO,
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 110,
            ),
            itemCount: cardData.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  final title = cardData[index]['title'];
                  if (title == 'Chassis Doctor') {
                    Get.to(() => const IdentifyIssues());
                  } else if (title == 'Learning Modules') {
                    Get.to(() => LearningHub());
                  }
                },
                child: Stack(
                  children: [
                    Container(
                      width: Get.width,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: kBorderColor2, width: 1),
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
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: kPrimaryColor,
                            child: ClipOval(
                              child: Image.asset(
                                cardData[index]['image'] ?? '',
                                fit: BoxFit.contain,
                              ),
                            ),
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
                            borderRadius: const BorderRadius.only(
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

          const SizedBox(height: 20),

          Container(
            width: Get.width,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: kBorderColor2, width: 1),
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
                        text: 'Current Track/Circuit',
                        size: 14,
                        weight: FontWeight.w700,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _editTrackConfiguration,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: kSecondaryColor),
                        minimumSize: const Size(72, 32),
                      ),
                      child: const Text('Edit'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Image.asset(Assets.imagesTt, height: 20),
                    Expanded(
                      child: MyText(
                        paddingLeft: 6,
                        text: 'Current Track/Circuit:',
                        size: 14,
                        color: kSecondaryColor,
                      ),
                    ),
                    MyText(
                      text: trackCircuitText,
                      size: 14,
                      weight: FontWeight.w500,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Image.asset(Assets.imagesCar, height: 20),
                    Expanded(
                      child: MyText(
                        paddingLeft: 6,
                        text: 'Car Type:',
                        size: 14,
                        color: kSecondaryColor,
                      ),
                    ),
                    MyText(text: _carType, size: 14, weight: FontWeight.w500),
                  ],
                ),
                const SizedBox(height: 12),
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
                      text: surfaceTypeText,
                      size: 14,
                      weight: FontWeight.w500,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                      text: weatherText,
                      size: 14,
                      weight: FontWeight.w500,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_note.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.sticky_note_2_outlined,
                        color: kSecondaryColor,
                        size: 20,
                      ),
                      Expanded(
                        child: MyText(
                          paddingLeft: 6,
                          text: 'Notes: ',
                          size: 14,
                          color: kSecondaryColor,
                          maxLines: 3,
                          textOverflow: TextOverflow.ellipsis,
                        ),
                      ),
                      MyText(text: _note, size: 14, weight: FontWeight.w500),
                    ],
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Center(child: Image.asset(Assets.imagesChassisDoc, height: 36)),
          const SizedBox(height: 20),

          // // Recent Activity card (unchanged)
          // Container(
          //   width: Get.width,
          //   padding: const EdgeInsets.all(10),
          //   decoration: BoxDecoration(
          //     border: Border.all(color: kBorderColor2, width: 1),
          //     color: kQuaternaryColor,
          //     borderRadius: BorderRadius.circular(12),
          //   ),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.stretch,
          //     children: [
          //        MyText(
          //         text: 'Recent Activity',
          //         size: 14,
          //         weight: FontWeight.w700,
          //       ),
          //       const SizedBox(height: 12),
          //       Row(
          //         children: [
          //           Image.asset(Assets.imagesSelected, height: 20),
          //            Expanded(
          //             child: MyText(
          //               paddingLeft: 8,
          //               text:
          //               'Chassis Doctor Diagnosis completed for poor traction',
          //               size: 12,
          //               weight: FontWeight.w500,
          //             ),
          //           ),
          //         ],
          //       ),
          //       MyText(
          //         paddingTop: 2,
          //         textAlign: TextAlign.end,
          //         text: '2 hours ago',
          //         size: 10,
          //         color: kTertiaryColor.withValues(alpha: 0.5),
          //       ),
          //       const SizedBox(height: 12),
          //       Row(
          //         children: [
          //           Image.asset(Assets.imagesTc, height: 20),
          //            Expanded(
          //             child: MyText(
          //               paddingLeft: 8,
          //               text:
          //               'Track configuration updated to "Nürburgring - Wet.',
          //               size: 12,
          //               weight: FontWeight.w500,
          //             ),
          //           ),
          //         ],
          //       ),
          //       MyText(
          //         paddingTop: 2,
          //         textAlign: TextAlign.end,
          //         text: '2 hours ago',
          //         size: 10,
          //         color: kTertiaryColor.withValues(alpha: 0.5),
          //       ),
          //       const SizedBox(height: 12),
          //       Row(
          //         children: [
          //           Image.asset(Assets.imagesInfo, height: 20),
          //            Expanded(
          //             child: MyText(
          //               paddingLeft: 8,
          //               text:
          //               'New learning module "Suspension Basics" added.',
          //               size: 12,
          //               weight: FontWeight.w500,
          //             ),
          //           ),
          //         ],
          //       ),
          //       MyText(
          //         paddingTop: 2,
          //         textAlign: TextAlign.end,
          //         text: '2 hours ago',
          //         size: 10,
          //         color: kTertiaryColor.withValues(alpha: 0.5),
          //       ),
          //       const SizedBox(height: 12),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}
