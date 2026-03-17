import 'package:flutter/material.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';

class CustomTile extends StatelessWidget {
  final String imagePath;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  const CustomTile({
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(imagePath, width: 28, height: 28),
            SizedBox(width: 16),
            Expanded(
              child: MyText(text: title, size: 16, weight: FontWeight.w600),
            ),
            trailing ??
                Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}
