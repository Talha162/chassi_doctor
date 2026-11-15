import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:motorsport/config/theme/theme_controller.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/models/geometry_tool.dart';
import 'package:motorsport/models/saved_setup.dart';
import 'package:motorsport/utils/app_error.dart';
import 'package:motorsport/utils/app_snackbar.dart';
import 'package:motorsport/utils/motion.dart';
import 'package:motorsport/view/screens/geometry/setup_sheets.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Runs one of the website's calculators offline (same maths, same screens) and
/// lets the member save or open setups shared with the website.
class GeometryCalculatorScreen extends StatefulWidget {
  const GeometryCalculatorScreen({
    super.key,
    required this.tool,
    this.initialSetup,
  });

  final GeometryTool tool;

  /// Opened straight from a saved setup (e.g. from the Geometry hub).
  final SavedSetup? initialSetup;

  @override
  State<GeometryCalculatorScreen> createState() =>
      _GeometryCalculatorScreenState();
}

class _GeometryCalculatorScreenState extends State<GeometryCalculatorScreen> {
  late final WebViewController _web;
  bool _ready = false;
  SavedSetup? _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialSetup;
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xffF2F5F9))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _onLoaded(),
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadFlutterAsset(widget.tool.asset);
  }

  Future<void> _onLoaded() async {
    // The page can report "finished" before React has drawn the calculator
    // (and the first WebView start-up on a device is slow), so keep the
    // loading cover until the calculator is actually on screen.
    for (var i = 0; i < 40; i++) {
      try {
        final drawn = await _web.runJavaScriptReturningResult(
          "document.getElementById('root') != null && "
          "document.getElementById('root').childElementCount > 0 && "
          "typeof window.chassisDoctorGetState === 'function'",
        );
        if (drawn == true || drawn.toString() == '1' || drawn.toString() == 'true') {
          break;
        }
      } catch (_) {
        // Not ready to evaluate yet.
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    final setup = widget.initialSetup;
    if (setup != null) {
      await _loadIntoCalculator(setup, announce: true);
    }
    // Two frames for the WebView to composite before fading it in.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (mounted) setState(() => _ready = true);
  }

  /// The calculator's current figures, exactly as the website stores them.
  Future<Map<String, dynamic>?> _readState() async {
    try {
      var raw = await _web.runJavaScriptReturningResult(
        'window.chassisDoctorGetState()',
      );
      // iOS returns the JSON string; Android returns it JSON-quoted.
      for (var i = 0; i < 2 && raw is String; i++) {
        final decoded = jsonDecode(raw);
        raw = decoded;
      }
      return raw is Map ? Map<String, dynamic>.from(raw) : null;
    } catch (e) {
      debugPrint('[GEOMETRY] read state failed: $e');
      return null;
    }
  }

  Future<void> _loadIntoCalculator(SavedSetup setup, {bool announce = true}) async {
    final payload = jsonEncode(jsonEncode(setup.data));
    await _web.runJavaScript('window.chassisDoctorLoad($payload)');
    if (!mounted) return;
    setState(() => _current = setup);
    if (announce) {
      showSuccessSnackbar(
        'The calculator now shows these figures.',
        title: 'Loaded “${setup.name}”',
      );
    }
  }

  Future<void> _save() async {
    final state = await _readState();
    if (!mounted) return;
    if (state == null) {
      showErrorSnackbar("Couldn't read the calculator's figures. Please try again.");
      return;
    }
    final saved = await showSaveSetupSheet(
      context,
      tool: widget.tool,
      data: state,
    );
    if (saved != null && mounted) {
      setState(() => _current = saved);
      showSuccessSnackbar(
        'It’s also in your account on the Chassis Doctor website.',
        title: 'Saved “${saved.name}”',
      );
    }
  }

  Future<void> _openSetups() async {
    final result = await showSetupListSheet(
      context,
      tool: widget.tool,
      readCurrentState: _readState,
    );
    if (result != null && mounted) {
      await _loadIntoCalculator(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    final gold = kSecondaryColor;
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: simpleAppBar(title: widget.tool.shortTitle),
      body: Column(
        children: [
          if (_current != null)
            FadeInUp(
              key: ValueKey(_current!.id),
              offset: 8,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                color: kPrimaryColor,
                child: Row(
                  children: [
                    Icon(Icons.bookmark_rounded, color: gold, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        [
                          _current!.name,
                          if ((_current!.trackName ?? '').isNotEmpty)
                            _current!.trackName!,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: kTertiaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                children: [
                  WebViewWidget(controller: _web),
                  IgnorePointer(
                    ignoring: _ready,
                    child: AnimatedOpacity(
                      opacity: _ready ? 0 : 1,
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOut,
                      child: Container(
                        color: const Color(0xffF2F5F9),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(widget.tool.icon,
                                size: 40, color: const Color(0xff00224B)),
                            const SizedBox(height: 14),
                            const SizedBox(
                              width: 140,
                              child: LinearProgressIndicator(
                                minHeight: 3,
                                color: Color(0xffD6A43A),
                                backgroundColor: Color(0x2200224B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: _PillButton(
                  label: 'My setups',
                  icon: Icons.bookmarks_outlined,
                  filled: false,
                  gold: gold,
                  onTap: _openSetups,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PillButton(
                  label: 'Save setup',
                  icon: Icons.save_alt_rounded,
                  filled: true,
                  gold: gold,
                  textColor: isDark ? Colors.black : kPrimaryColor,
                  onTap: _ready ? _save : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.gold,
    required this.onTap,
    this.textColor,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final Color gold;
  final Color? textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? (textColor ?? kPrimaryColor) : gold;
    return PressScale(
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: onTap == null ? 0.5 : 1,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: filled
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color.lerp(gold, Colors.white, 0.18)!, gold],
                    )
                  : null,
              borderRadius: BorderRadius.circular(25),
              border: filled ? null : Border.all(color: gold.withValues(alpha: 0.8)),
              boxShadow: filled
                  ? [
                      BoxShadow(
                        color: gold.withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Friendly message for setup errors (used by the sheets).
String setupErrorMessage(Object e) => friendlyError(
      e,
      fallback: "Couldn't reach your saved setups. Please try again.",
    );
