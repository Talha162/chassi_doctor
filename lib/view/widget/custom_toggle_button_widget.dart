// import 'package:drink_with_me/constants/app_colors.dart';
// import 'package:drink_with_me/constants/app_images.dart';
// import 'package:drink_with_me/view/widget/my_text_widget.dart';
// import 'package:flutter/material.dart';

// class CustomToggleButton extends StatelessWidget {
//   final String icon;
//   final String title;
//   final bool isSelected;
//   final double? iconSize;
//   final VoidCallback onTap;

//   const CustomToggleButton({
//     super.key,
//     required this.icon,
//     required this.title,
//     this.iconSize,
//     required this.isSelected,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         height: 30,
//         padding: EdgeInsets.symmetric(horizontal: 6),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(50),
//           color: isSelected ? kPrimaryColor : kLightOrangeColor,
//         ),
//         child: Wrap(
//           spacing: 2,
//           runAlignment: WrapAlignment.center,
//           crossAxisAlignment: WrapCrossAlignment.center,
//           children: [
//             Image.asset(icon, height: iconSize ?? 18, color: kSecondaryColor),
//             MyText(
//               paddingLeft: 2,
//               paddingRight: 6,
//               color: kSecondaryColor,
//               size: 12,
//               textAlign: TextAlign.center,
//               text: title,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class CancelToggleButton extends StatelessWidget {
//   final String title;
//   final bool isSelected;
//   final VoidCallback onTap;

//   const CancelToggleButton({
//     super.key,
//     required this.title,
//     required this.isSelected,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         height: 30,
//         padding: EdgeInsets.symmetric(horizontal: 6),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(50),
//           color: isSelected ? kPrimaryColor : kLightOrangeColor,
//         ),
//         child: Wrap(
//           spacing: 2,
//           runAlignment: WrapAlignment.center,
//           crossAxisAlignment: WrapCrossAlignment.center,
//           children: [
//             MyText(
//               paddingRight: 2,
//               paddingLeft: 6,
//               color: kSecondaryColor,
//               size: 12,
//               textAlign: TextAlign.center,
//               text: title,
//             ),
//             Image.asset(Assets.imagesCloseIconRounded, height: 22,),
//           ],
//         ),
//       ),
//     );
//   }
// }
