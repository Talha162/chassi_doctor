import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_images.dart';

/// Full-bleed photo behind the top of the sign-in screens. It runs under the
/// status bar and the (transparent) top bar, and fades into the page colour
/// so the form sheet sits on it cleanly.
class AuthHero extends StatelessWidget {
  const AuthHero({super.key, this.heightFactor = 0.52});

  /// Share of the screen height the photo covers.
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    final bg = kPrimaryColor;
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.sizeOf(context).height * heightFactor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              Assets.imagesLoginHero,
              fit: BoxFit.cover,
              alignment: const Alignment(0, 0.25),
            ),
            // Darkens the top for the title, fades the bottom into the page.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    bg.withValues(alpha: 0.85),
                    bg.withValues(alpha: 0.0),
                    bg.withValues(alpha: 0.0),
                    bg,
                  ],
                  stops: const [0.0, 0.32, 0.62, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
