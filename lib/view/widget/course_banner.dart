import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_images.dart';

/// A course banner at 16:9 (the size to upload: 1600 x 900 px). The whole
/// image is always shown; a banner of another shape is centred on the card
/// colour instead of being cropped.
class CourseBanner extends StatelessWidget {
  const CourseBanner({super.key, this.url, this.width, this.radius = 8});

  final String? url;

  /// Fixed width (list rows); null fills the available width (cards).
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.trim().isNotEmpty;
    final image = hasUrl
        ? Image.network(
            url!,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _fallback(),
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : ColoredBox(color: kPrimaryColor.withValues(alpha: 0.5)),
          )
        : _fallback();
    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: ColoredBox(color: kPrimaryColor, child: image),
        ),
      ),
    );
  }

  Widget _fallback() => Image.asset(Assets.imagesAdvanced, fit: BoxFit.cover);
}
