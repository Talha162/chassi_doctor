import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_fonts.dart';

final ThemeData lightTheme = ThemeData(
  scaffoldBackgroundColor: kScaffoldBgColor,
  fontFamily: AppFonts.ROBOTO,
  appBarTheme: AppBarTheme(elevation: 0, backgroundColor: kWhiteColor),
  splashColor: kWhiteColor.withValues(alpha: 0.1),
  highlightColor: kWhiteColor.withValues(alpha: 0.1),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    secondary: kSecondaryColor.withValues(alpha: 0.1),
    primary: kSecondaryColor,
  ),
  useMaterial3: false,
  textSelectionTheme: TextSelectionThemeData(cursorColor: kWhiteColor),
);
