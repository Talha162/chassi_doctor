import 'package:flutter/material.dart';

/// A geometry calculator, run offline from the website's own build
/// (assets/geometry/<key>.html, made by scripts/standalone/build.mjs in the
/// website repo). The maths is the website's, unchanged.
class GeometryTool {
  const GeometryTool({
    required this.key,
    required this.title,
    required this.shortTitle,
    required this.summary,
    required this.stateKey,
    required this.icon,
  });

  /// Matches `saved_setups.tool` and the website's componentKey.
  final String key;
  final String title;
  final String shortTitle;
  final String summary;

  /// The website's localStorage key for this calculator's figures.
  final String stateKey;
  final IconData icon;

  String get asset => 'assets/geometry/$key.html';

  static const cornerWeight = GeometryTool(
    key: 'corner-weight',
    title: 'Corner Weight Analyser',
    shortTitle: 'Corner Weights',
    summary: 'Cross, left and rear %, wedge changes and ballast from your scale readings.',
    stateKey: 'chassis-doctor:corner-weight:v1',
    icon: Icons.scale_outlined,
  );

  static const motionRatio = GeometryTool(
    key: 'motion-ratio',
    title: 'Motion Ratio Calculator',
    shortTitle: 'Motion Ratio',
    summary: 'Motion ratio, wheel rate and ride frequency for outboard, pushrod or pullrod.',
    stateKey: 'chassis-doctor:motion-ratio:v1',
    icon: Icons.compress_rounded,
  );

  static const rollCentre = GeometryTool(
    key: 'ifs-roll-centre',
    title: 'IFS Roll Centre Calculator',
    shortTitle: 'Roll Centre',
    summary: 'Roll centre, camber gain, KPI and scrub through heave and roll, front view.',
    stateKey: 'chassis-doctor:roll-centre:v2',
    icon: Icons.architecture_rounded,
  );

  static const all = [rollCentre, cornerWeight, motionRatio];

  static GeometryTool? byKey(String key) {
    for (final t in all) {
      if (t.key == key) return t;
    }
    return null;
  }
}
