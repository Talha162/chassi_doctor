import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/config/theme/theme_controller.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/main.dart';
import 'package:motorsport/models/app_user.dart';
import 'package:motorsport/services/auth/auth_service.dart';
import 'package:motorsport/services/supabase/supabase_client_service.dart';
import 'package:motorsport/view/screens/auth/login.dart';
import 'package:motorsport/view/screens/settings/edit_profile.dart';
import 'package:motorsport/view/screens/settings/privacy_policy.dart';
import 'package:motorsport/view/screens/settings/saved_setup_history.dart';
import 'package:motorsport/view/widget/common_image_view_widget.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final AuthService _authService = AuthService();
  final SupabaseService _service = SupabaseService.instance;

  AppUser? _user;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      setState(() => _isLoadingUser = true);
      final current = await _service.getCurrentUserProfile();
      setState(() {
        _user = current;
      });
    } catch (e) {
      debugPrint('Error loading user profile in Settings: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      Get.offAll(() => const Login());
    } catch (e) {
      Get.snackbar(
        "Logout Error",
        "Failed to log out: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(
      () => Scaffold(
        appBar: simpleAppBar(title: 'Settings', haveLeading: false),
        body: ListView(
          shrinkWrap: true,
          padding: AppSizes.DEFAULT,
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 16),

            // ---------- HEADER (stable height, better UX) ----------
            _buildHeader(),

            // ---------- FIRST SETTINGS CARD ----------
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kQuaternaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SettingsTile(
                    imagePath: Assets.imagesProfile,
                    title: 'Profile information',
                    onTap: () async {
                      final updated = await Get.to(() => const EditProfile());
                      if (updated != null) {
                        _loadUser();
                      }
                    },
                  ),
                  const _Divider(),
                  _SettingsTile(
                    imagePath: Assets.imagesNotifications,
                    title: 'Push notification',
                    trailing: Transform.scale(
                      scale: 0.65,
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        height: 20 / 0.65,
                        width: 20 / 0.65,
                        child: CupertinoSwitch(
                          value: true,
                          thumbColor: kPrimaryColor,
                          activeTrackColor: kSecondaryColor,
                          onChanged: (bool value) {
                            // TODO: persist notification preferences if needed
                          },
                        ),
                      ),
                    ),
                    onTap: () {},
                  ),

                  const _Divider(),
                  _SettingsTile(
                    imagePath: Assets.imagesData,
                    title: 'Data and Privacy Setting',
                    onTap: () {
                      Get.to(() => const PrivacyPolicy());
                    },
                  ),
                  const _Divider(),
                  _SettingsTile(
                    imagePath: Assets.imagesTheme,
                    title: themeController.isDarkMode
                        ? 'Switch to Light Mode'
                        : 'Switch to Dark Mode',
                    onTap: () {},
                    trailing: Transform.scale(
                      scale: 0.65,
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        height: 20 / 0.65,
                        width: 20 / 0.65,
                        child: CupertinoSwitch(
                          value: themeController.isDarkMode,
                          thumbColor: kPrimaryColor,
                          activeTrackColor: kSecondaryColor,
                          onChanged: (bool value) {
                            themeController.toggleTheme();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ---------- SECOND SETTINGS CARD ----------
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kQuaternaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SettingsTile(
                    imagePath: Assets.imagesLogout,
                    title: 'Logout',
                    onTap: () {
                      showCupertinoModalPopup(
                        context: context,
                        builder: (context) => Theme(
                          data: Theme.of(context).copyWith(
                            cupertinoOverrideTheme: CupertinoThemeData(
                              scaffoldBackgroundColor: kPrimaryColor,
                            ),
                          ),
                          child: CupertinoAlertDialog(
                            title: Column(
                              children: [
                                Image.asset(
                                  Assets.imagesLogoutIcon,
                                  height: 38,
                                ),
                                const SizedBox(height: 8),
                                MyText(
                                  text: 'Logout',
                                  size: 16,
                                  color: Colors.black,
                                  weight: FontWeight.w700,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                MyText(
                                  text: 'Do you really want to logout?',
                                  size: 12,
                                  color: Colors.black,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            content: Container(),
                            actions: [
                              CupertinoDialogAction(
                                child: MyText(
                                  text: 'Cancel',
                                  size: 14,
                                  color: Colors.black,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              CupertinoDialogAction(
                                child: MyText(
                                  text: 'Logout',
                                  size: 14,
                                  color: CupertinoColors.destructiveRed,
                                ),
                                isDestructiveAction: true,
                                onPressed: () {
                                  _logout();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const _Divider(),
                  _SettingsTile(
                    imagePath: Assets.imagesDelete,
                    title: 'Delete Account',
                    onTap: () {
                      showCupertinoModalPopup(
                        context: context,
                        builder: (context) => Theme(
                          data: Theme.of(context).copyWith(
                            cupertinoOverrideTheme: CupertinoThemeData(
                              scaffoldBackgroundColor: kPrimaryColor,
                            ),
                          ),
                          child: CupertinoAlertDialog(
                            title: Column(
                              children: [
                                Image.asset(
                                  Assets.imagesDeleteProfile,
                                  height: 38,
                                ),
                                const SizedBox(height: 8),
                                MyText(
                                  text: 'Delete Account',
                                  size: 16,
                                  color: Colors.black,
                                  weight: FontWeight.w700,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                MyText(
                                  text:
                                      'Are you sure you want to delete your account? This will permanently erase your account.',
                                  size: 12,
                                  color: Colors.black,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            content: Container(),
                            actions: [
                              CupertinoDialogAction(
                                child: MyText(
                                  text: 'Cancel',
                                  size: 14,
                                  color: Colors.black,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              CupertinoDialogAction(
                                child: MyText(
                                  text: 'Delete',
                                  size: 14,
                                  color: CupertinoColors.destructiveRed,
                                ),
                                isDestructiveAction: true,
                                onPressed: () {
                                  // TODO: implement delete account logic
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header widget that keeps a fixed layout but shows a subtle loader overlay
  /// while user data is being fetched.
  Widget _buildHeader() {
    final isLoading = _isLoadingUser;
    final avatarUrl = _user?.avatarUrl ?? dummyImg;
    final name = _user?.fullName ?? (isLoading ? 'Loading...' : 'Your name');
    final email = _user?.email ?? (isLoading ? '' : '');

    return Column(
      children: [
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: kSecondaryColor,
                    width: 4,
                  ),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: SizedBox(
                    height: 120,
                    width: 120,
                    child: CommonImageView(
                      height: 120,
                      width: 120,
                      radius: 100,
                      url: avatarUrl,
                    ),
                  ),
                ),
              ),
              if (isLoading)
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        MyText(
          text: name,
          size: 18,
          weight: FontWeight.bold,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        if (email.isNotEmpty)
          MyText(
            text: email,
            size: 14,
            textAlign: TextAlign.center,
            color: kTertiaryColor.withValues(alpha: 0.8),
            paddingBottom: 30,
          )
        else
          const SizedBox(height: 30),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String imagePath;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    Key? key,
    required this.imagePath,
    required this.title,
    this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Image.asset(imagePath, height: 24, color: kTertiaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: MyText(
              text: title,
              size: 16,
              weight: FontWeight.w500,
            ),
          ),
          trailing ?? const SizedBox(),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: kBorderColor2,
      margin: const EdgeInsets.symmetric(vertical: 12),
    );
  }
}
