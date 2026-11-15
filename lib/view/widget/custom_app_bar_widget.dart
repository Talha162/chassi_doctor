import 'package:flutter/material.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_images.dart';

AppBar simpleAppBar({
  bool haveLeading = true,
  bool centerTitle = true,
  String? title,
  Color? bgColor,
  double? leadingWidth,
  final Widget? leading,
  List<Widget>? actions,
  VoidCallback? onLeadingTap,
}) {
  return AppBar(
    elevation: 0,
    backgroundColor: bgColor ?? kPrimaryColor,
    automaticallyImplyLeading: false,
    centerTitle: centerTitle,
    leadingWidth: leadingWidth,
    leading: haveLeading
        ? leading ?? Center(child: AppBackButton(onTap: onLeadingTap))
        : null,
    title: MyText(
      text: title ?? '',
      size: 18,
      weight: FontWeight.w600,
      color: kTertiaryColor,
    ),
    actions: actions,
  );
}

/// The app's back arrow. Use this everywhere instead of a bare arrow image.
///
/// - The whole 48x48 box is tappable (the arrow image alone is only 14px,
///   which made back buttons very hard to hit).
/// - The default action uses Flutter's Navigator rather than `Get.back()`,
///   so it always leaves the page even if GetX thinks an overlay is open.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onTap});

  /// Optional custom action; defaults to popping the current page.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Image.asset(
              Assets.imagesArrowBack,
              height: 14,
              color: kTertiaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
