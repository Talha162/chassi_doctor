import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_images.dart';
import '../../constants/app_colors.dart';
import 'my_text_widget.dart';

class AuthHeading extends StatelessWidget {
  const AuthHeading({
    super.key,
    required this.title,
    required this.subTitle,
    this.marginTop,
  });
  final String? title;
  final String? subTitle;
  final double? marginTop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [Image.asset(Assets.imagesLogo, height: 65)]),
        MyText(
          paddingTop: marginTop ?? 16,
          text: title ?? '',
          size: 28,
          paddingBottom: subTitle!.isEmpty ? 24 : 6,
          weight: FontWeight.w500,
        ),
        if (subTitle!.isNotEmpty)
          MyText(
            text: subTitle ?? '',
            size: 14,
            lineHeight: 1.5,
            paddingBottom: 24,
            color: kGreyColor,
          ),
      ],
    );
  }
}
