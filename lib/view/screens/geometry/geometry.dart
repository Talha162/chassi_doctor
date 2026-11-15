import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/models/geometry_tool.dart';
import 'package:motorsport/models/saved_setup.dart';
import 'package:motorsport/services/supabase/supabase_client_service.dart';
import 'package:motorsport/utils/app_error.dart';
import 'package:motorsport/utils/motion.dart';
import 'package:motorsport/view/screens/geometry/geometry_calculator_screen.dart';
import 'package:motorsport/view/screens/geometry/setup_sheets.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';

/// Geometry tools: the website's calculators, offline in the app, with the
/// member's saved setups (shared with the website).
class Geometry extends StatefulWidget {
  const Geometry({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  State<Geometry> createState() => _GeometryState();
}

class _GeometryState extends State<Geometry> {
  List<SavedSetup>? _setups;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await SupabaseService.instance.getSavedSetups();
      if (mounted) setState(() {
        _setups = list;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = friendlyError(
              e,
              fallback: "Couldn't load your saved setups.",
            ));
      }
    }
  }

  Future<void> _open(GeometryTool tool, [SavedSetup? setup]) async {
    await Get.to(() => GeometryCalculatorScreen(tool: tool, initialSetup: setup));
    _load(); // pick up anything saved inside the calculator
  }

  int _countFor(GeometryTool t) =>
      _setups?.where((s) => s.tool == t.key).length ?? 0;

  @override
  Widget build(BuildContext context) {
    final setups = _setups;
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: simpleAppBar(
        title: 'Geometry Tools',
        haveLeading: widget.showBackButton,
      ),
      body: RefreshIndicator(
        color: kSecondaryColor,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
          children: [
            FadeInUp(
              child: Text(
                'Work out your car’s geometry, save it with the track and date, '
                'and look back before your next race. Your setups are also on '
                'the Chassis Doctor website.',
                style: TextStyle(
                  color: kTertiaryColor.withValues(alpha: 0.8),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 18),
            for (final (i, tool) in GeometryTool.all.indexed) ...[
              FadeInUp(
                delay: staggerDelay(i + 1, stepMs: 70),
                child: _ToolCard(
                  tool: tool,
                  savedCount: _countFor(tool),
                  onTap: () => _open(tool),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 260),
              child: Row(
                children: [
                  Text(
                    'Recent setups',
                    style: TextStyle(
                      color: kWhiteColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (setups != null && setups.isNotEmpty)
                    Text(
                      '${setups.length} saved',
                      style: TextStyle(
                        color: kTertiaryColor.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (_error != null)
              _InfoBox(icon: Icons.cloud_off_rounded, text: _error!)
            else if (setups == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (setups.isEmpty)
              const _InfoBox(
                icon: Icons.bookmark_add_outlined,
                text:
                    'No saved setups yet. Open a calculator, enter your car’s figures and tap “Save setup”.',
              )
            else
              for (final (i, s) in setups.take(20).indexed)
                FadeInUp(
                  delay: staggerDelay(i, stepMs: 45),
                  child: _RecentSetupTile(
                    setup: s,
                    onTap: () {
                      final tool = GeometryTool.byKey(s.tool);
                      if (tool != null) _open(tool, s);
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.tool,
    required this.savedCount,
    required this.onTap,
  });

  final GeometryTool tool;
  final int savedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gold = kSecondaryColor;
    return PressScale(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kQuaternaryColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kBorderColor2),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      gold.withValues(alpha: 0.28),
                      gold.withValues(alpha: 0.08),
                    ],
                  ),
                ),
                child: Icon(tool.icon, color: gold, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.title,
                      style: TextStyle(
                        color: kWhiteColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tool.summary,
                      style: TextStyle(
                        color: kTertiaryColor.withValues(alpha: 0.75),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                    if (savedCount > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        '$savedCount saved setup${savedCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: kTertiaryColor.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentSetupTile extends StatelessWidget {
  const _RecentSetupTile({required this.setup, required this.onTap});

  final SavedSetup setup;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tool = GeometryTool.byKey(setup.tool);
    final subtitle = [
      tool?.shortTitle ?? setup.tool,
      if (setupSubtitle(setup) != null) setupSubtitle(setup)!,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorderColor2.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Icon(tool?.icon ?? Icons.bookmark_rounded,
                    color: kSecondaryColor, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        setup.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: kWhiteColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: kTertiaryColor.withValues(alpha: 0.65),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  setup.source == 'app'
                      ? Icons.phone_iphone_rounded
                      : Icons.language_rounded,
                  size: 16,
                  color: kTertiaryColor.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kQuaternaryColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: kSecondaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: kTertiaryColor.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
