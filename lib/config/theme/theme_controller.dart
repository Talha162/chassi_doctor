import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static ThemeController get instance => Get.find<ThemeController>();
  static const String _prefKey = 'theme_mode';
  Rx<ThemeMode> themeMode = ThemeMode.light.obs;

  final Rx<Color> currentPrimaryColor = Color(0xff231543).obs;
  final Rx<Color> currentSecondaryColor = Color(0xffE8C670).obs;
  final Rx<Color> currentTertiaryColor = Color(0xffDFDEDE).obs;
  final Rx<Color> currentWhiteColor = Color(0xffFFFFFF).obs;
  final Rx<Color> currentBorderColor = Color(0xffDEDEDE).obs;
  final Rx<Color> currentBorderColor2 = Color(0xff634F91).obs;
  final Rx<Color> currentFillColor = Color(0xffFCFCFC).obs;
  final Rx<Color> currentHintColor = Color(0xff767676).obs;
  final Rx<Color> currentGreyColor = Color(0xff767676).obs;
  final Rx<Color> currentGreyColor2 = Color(0xffCFCFCF).obs;
  final Rx<Color> currentDarkGreyColor = Color(0xff98A2B3).obs;
  final Rx<Color> currentLightGreyColor = Color(0xff9A9A9A).obs;
  final Rx<Color> currentRedColor = Color(0xffFF0000).obs;
  final Rx<Color> currentGreenColor = Color(0xff0E9B09).obs;
  final Rx<Color> currentQuaternaryColor = Color(0xff392A5E).obs;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_prefKey);
    if (isDark == null) return;
    setTheme(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> _persistTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, mode == ThemeMode.dark);
  }

  void _applyThemeColors(ThemeMode mode) {
    if (mode == ThemeMode.dark) {
      currentPrimaryColor.value = Color(0xff000000);
      currentSecondaryColor.value = Color(0xffFFD700);
      currentTertiaryColor.value = Color(0xffDFDEDE);
      currentWhiteColor.value = Color(0xffEDEDED);
      currentBorderColor.value = Color(0xff444444);
      currentBorderColor2.value = Color(0xff333030);
      currentFillColor.value = Color(0xff111013);
      currentHintColor.value = Color(0xffA0A0A0);
      currentGreyColor.value = Color(0xffA0A0A0);
      currentGreyColor2.value = Color(0xff444444);
      currentDarkGreyColor.value = Color(0xff6C6C6C);
      currentLightGreyColor.value = Color(0xffB0B0B0);
      currentRedColor.value = Color(0xffFF4C4C);
      currentGreenColor.value = Color(0xff1DB954);
      currentQuaternaryColor.value = Color(0xff111013);
    } else {
      currentPrimaryColor.value = Color(0xff231543);
      currentSecondaryColor.value = Color(0xffE8C670);
      currentTertiaryColor.value = Color(0xffDFDEDE);
      currentWhiteColor.value = Color(0xffFFFFFF);
      currentBorderColor.value = Color(0xffDEDEDE);
      currentBorderColor2.value = Color(0xff634F91);
      currentFillColor.value = Color(0xffFCFCFC);
      currentHintColor.value = Color(0xff767676);
      currentGreyColor.value = Color(0xff767676);
      currentGreyColor2.value = Color(0xffCFCFCF);
      currentDarkGreyColor.value = Color(0xff98A2B3);
      currentLightGreyColor.value = Color(0xff9A9A9A);
      currentRedColor.value = Color(0xffFF0000);
      currentGreenColor.value = Color(0xff0E9B09);
      currentQuaternaryColor.value = Color(0xff392A5E);
    }
  }

  Future<void> toggleTheme() async {
    final nextMode =
        themeMode.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    setTheme(nextMode);
    await _persistTheme(nextMode);
  }

  void setTheme(ThemeMode mode) {
    themeMode.value = mode;
    _applyThemeColors(mode);
    Get.changeThemeMode(mode);
  }

  bool get isDarkMode => themeMode.value == ThemeMode.dark;
}
