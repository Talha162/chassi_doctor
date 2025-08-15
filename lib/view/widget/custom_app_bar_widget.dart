import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_images.dart';

AppBar simpleAppBar({
  bool haveLeading = true,
  bool centerTitle = true,
  String? title,
  Color? bgColor,
  final Widget? leading,
  List<Widget>? actions,
  VoidCallback? onLeadingTap,
}) {
  return AppBar(
    elevation: 0,
    backgroundColor: bgColor ?? kPrimaryColor,
    automaticallyImplyLeading: false,
    centerTitle: centerTitle,
    leading: haveLeading
        ? leading ??
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: GestureDetector(
                      onTap: onLeadingTap ?? () => Get.back(),
                      child: Image.asset(
                        Assets.imagesArrowBack,
                        height: 16,
                        color: kTertiaryColor,
                      ),
                    ),
                  ),
                ],
              )
        : null,
    title: MyText(
      text: title ?? '',
      size: 22,
      weight: FontWeight.w600,
      color: kTertiaryColor,
    ),
    actions: actions,
  );
}
