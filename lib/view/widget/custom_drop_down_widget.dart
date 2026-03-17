import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_images.dart';

import '../../constants/app_colors.dart';
import 'my_text_widget.dart';

// ignore: must_be_immutable
class CustomDropDown extends StatelessWidget {
  CustomDropDown({
    required this.hint,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.bgColor,
    this.marginBottom,
    this.width,
    this.labelText,
    this.isMandatory = false,
    this.prefix,
  });

  final List<dynamic>? items;
  String selectedValue;
  final ValueChanged<dynamic>? onChanged;
  String hint;
  String? labelText;
  Color? bgColor;
  double? marginBottom, width;
  final bool isMandatory;
  final Widget? prefix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: marginBottom ?? 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (labelText != null)
            Row(
              children: [
                MyText(
                  text: labelText ?? '',
                  paddingBottom: 6,
                  size: 12,
                  color: kQuaternaryColor,
                  weight: FontWeight.w600,
                ),
                if (isMandatory)
                  MyText(
                    paddingLeft: 2,
                    paddingBottom: 6,
                    text: '*',
                    size: 12,
                    color: Color(0xffFF3B30),
                    weight: FontWeight.bold,
                  ),
              ],
            ),
          DropdownButtonHideUnderline(
            child: DropdownButton2(
              items:
                  items!
                      .map(
                        (item) => DropdownMenuItem<dynamic>(
                          value: item,
                          child: MyText(
                            text: item,
                            size: 14,
                            weight: FontWeight.w500,
                            color: kQuaternaryColor,
                          ),
                        ),
                      )
                      .toList(),
              value: selectedValue,
              onChanged: onChanged,
              iconStyleData: IconStyleData(icon: SizedBox()),
              isDense: true,
              isExpanded: false,
              customButton: Container(
                height: 48,
                padding: EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  border: Border.all(width: 1.0, color: kBorderColor),
                  color: Color(0xffFCFCFC),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (prefix != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: prefix!,
                      ),
                    ],
                    Expanded(
                      child: MyText(
                        paddingRight: 12,
                        text: selectedValue == hint ? hint : selectedValue,
                        size: 14,
                        maxLines: 1,
                        textOverflow: TextOverflow.ellipsis,
                        color:
                            selectedValue == hint
                                ? kQuaternaryColor.withValues(alpha: 0.6)
                                : kTertiaryColor,
                      ),
                    ),
                    Image.asset(Assets.imagesDropdown, height: 20),
                  ],
                ),
              ),
              menuItemStyleData: MenuItemStyleData(height: 35),
              dropdownStyleData: DropdownStyleData(
                elevation: 6,
                maxHeight: 300,
                offset: Offset(0, -5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: kWhiteColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// class MultiDropDown extends StatefulWidget {
//   const MultiDropDown({
//     required this.hint,
//     this.labelText,
//     this.isMandatory = false,
//     this.prefix,
//     required this.items,
//     required this.selectedValues,
//     required this.onTap,
//     this.marginBottom,
//   });
//   final String hint;
//   final String? labelText;
//   final bool isMandatory;
//   final Widget? prefix;
//   final List<String> items;
//   final List<String> selectedValues;
//   final double? marginBottom;
//   final void Function(String value) onTap;

//   @override
//   State<MultiDropDown> createState() => _MultiDropDownState();
// }

// class _MultiDropDownState extends State<MultiDropDown> {
//   late ExpandableController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = ExpandableController(initialExpanded: false);
//     _controller.addListener(() {
//       setState(() {});
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         if (widget.labelText != null)
//           Row(
//             children: [
//               MyText(
//                 text: widget.labelText ?? '',
//                 paddingBottom: 6,
//                 size: 12,
//                 color: kQuaternaryColor,
//                 weight: FontWeight.w600,
//               ),
//               if (widget.isMandatory)
//                 MyText(
//                   paddingLeft: 2,
//                   paddingBottom: 6,
//                   text: '*',
//                   size: 12,
//                   color: Color(0xffFF3B30),
//                   weight: FontWeight.bold,
//                 ),
//             ],
//           ),
//         ExpandableNotifier(
//           controller: _controller,
//           child: ScrollOnExpand(
//             child: ExpandablePanel(
//               controller: _controller,
//               theme: ExpandableThemeData(
//                 tapHeaderToExpand: true,
//                 hasIcon: false,
//               ),
//               header: Container(
//                 height: 48,
//                 padding: EdgeInsets.symmetric(horizontal: 15),
//                 decoration: BoxDecoration(
//                   border: Border.all(width: 1.0, color: kBorderColor),
//                   color: Color(0xffFCFCFC),
//                   borderRadius: BorderRadius.circular(50),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     if (widget.prefix != null)
//                       Padding(
//                         padding: const EdgeInsets.only(right: 8.0),
//                         child: widget.prefix!,
//                       ),
//                     Expanded(
//                       child: MyText(
//                         paddingRight: 12,
//                         text:
//                             widget.selectedValues.isEmpty
//                                 ? widget.hint
//                                 : widget.selectedValues.join(', '),
//                         size: 14,
//                         maxLines: 1,
//                         textOverflow: TextOverflow.ellipsis,
//                         color:
//                             widget.selectedValues.isEmpty
//                                 ? kQuaternaryColor.withAlpha(153)
//                                 : kTertiaryColor,
//                       ),
//                     ),
//                     Image.asset(Assets.imagesDropdown, height: 20),
//                   ],
//                 ),
//               ),
//               collapsed: SizedBox(),
//               expanded: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   SizedBox(height: 12),
//                   Container(
//                     padding: EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       border: Border.all(width: 1.0, color: kBorderColor),
//                       color: Color(0xffFCFCFC),
//                       boxShadow: [
//                         BoxShadow(
//                           color: kTertiaryColor.withValues(alpha: 0.1),
//                           blurRadius: 8,
//                           offset: Offset(0, 2),
//                         ),
//                       ],
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Wrap(
//                       spacing: 8,
//                       runSpacing: 8,
//                       children:
//                           widget.items
//                               .where((value) => value != widget.hint)
//                               .map(
//                                 (value) => GestureDetector(
//                                   onTap: () => widget.onTap(value),
//                                   child: Container(
//                                     padding: EdgeInsets.symmetric(
//                                       horizontal: 12,
//                                       vertical: 8,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color:
//                                           widget.selectedValues.contains(value)
//                                               ? kSecondaryColor
//                                               : kPrimaryColor,
//                                       borderRadius: BorderRadius.circular(50),
//                                       border: Border.all(
//                                         color: kSecondaryColor,
//                                       ),
//                                     ),
//                                     child: Row(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         Image.asset(
//                                           widget.selectedValues.contains(value)
//                                               ? Assets.imagesCloseIcon
//                                               : Assets.imagesPlus,
//                                           height: 8,
//                                           color:
//                                               widget.selectedValues.contains(
//                                                     value,
//                                                   )
//                                                   ? kPrimaryColor
//                                                   : kSecondaryColor,
//                                         ),
//                                         MyText(
//                                           paddingLeft: 6,
//                                           paddingRight: 6,
//                                           text: value,
//                                           size: 12,
//                                           color:
//                                               widget.selectedValues.contains(
//                                                     value,
//                                                   )
//                                                   ? kPrimaryColor
//                                                   : kSecondaryColor,
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               )
//                               .toList(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         if (widget.selectedValues.isNotEmpty)
//           Padding(
//             padding: const EdgeInsets.only(top: 8.0),
//             child: Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               children:
//                   widget.selectedValues
//                       .map(
//                         (value) => GestureDetector(
//                           onTap: () => widget.onTap(value),
//                           child: Container(
//                             padding: EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 8,
//                             ),
//                             decoration: BoxDecoration(
//                               color: kSecondaryColor,
//                               borderRadius: BorderRadius.circular(50),
//                               border: Border.all(color: kSecondaryColor),
//                             ),
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Image.asset(
//                                   Assets.imagesCloseIcon,
//                                   height: 8,
//                                   color: kPrimaryColor,
//                                 ),
//                                 MyText(
//                                   paddingLeft: 6,
//                                   paddingRight: 6,
//                                   text: value,
//                                   size: 12,
//                                   color: kPrimaryColor,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       )
//                       .toList(),
//             ),
//           ),
//         SizedBox(height: widget.marginBottom ?? 16),
//       ],
//     );
//   }
// }
