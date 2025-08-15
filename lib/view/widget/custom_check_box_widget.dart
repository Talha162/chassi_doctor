import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';

// ignore: must_be_immutable
class CustomCheckBox extends StatelessWidget {
  CustomCheckBox({
    Key? key,
    required this.isActive,
    required this.onTap,
    this.unSelectedColor,
    this.isRadio = false,
  }) : super(key: key);

  final bool isActive;
  final bool? isRadio;
  final VoidCallback onTap;
  final Color? unSelectedColor;

  @override
  Widget build(BuildContext context) {
    if (isRadio!) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 230),
          curve: Curves.easeInOut,
          height: 20,
          width: 20,
          decoration: BoxDecoration(
            border: Border.all(
              width: 1.0,
              color:
                  isActive ? kSecondaryColor : unSelectedColor ?? kBorderColor,
            ),
            shape: BoxShape.circle,
          ),
          child:
              !isActive
                  ? SizedBox()
                  : Center(
                    child: AnimatedContainer(
                      margin: EdgeInsets.all(3),
                      duration: Duration(milliseconds: 230),
                      curve: Curves.easeInOut,
                      height: Get.height,
                      width: Get.width,
                      decoration: BoxDecoration(
                        color: kSecondaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 230),
          curve: Curves.easeInOut,
          height: 20,
          width: 20,
          decoration: BoxDecoration(
            border: Border.all(
              width: 1.0,
              color: isActive ? kSecondaryColor : kBorderColor,
            ),
            color: isActive ? kSecondaryColor : kPrimaryColor,
            borderRadius: BorderRadius.circular(3.3),
          ),
          child:
              !isActive
                  ? SizedBox()
                  : Icon(Icons.check, size: 16, color: kWhiteColor),
        ),
      );
    }
  }
}
