import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'my_text_widget.dart';

class SocialLogin extends StatelessWidget {
  const SocialLogin({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final String icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          splashColor: kBorderColor,
          highlightColor: kBorderColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                icon,
                height: 20,
              ),
              MyText(
                paddingLeft: 8,
                paddingRight: 8,
                text: title,
                size: 14,
                weight: FontWeight.w500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
